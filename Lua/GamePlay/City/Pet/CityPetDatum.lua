---@class CityPetDatum
---@field new fun():CityPetDatum
local CityPetDatum = class("CityPetDatum")
local ConfigRefer = require("ConfigRefer")
local UnitActorConfigWrapper = require("UnitActorConfigWrapper")
local ArtResourceUtils = require("ArtResourceUtils")
local I18N = require("I18N")
local CityWorkType = require("CityWorkType")
local ModuleRefer = require("ModuleRefer")
local CityInteractionPointType = require("CityInteractionPointType")
local CityWorkTargetType = require("CityWorkTargetType")
local Vector3 = CS.UnityEngine.Vector3

---@param manager CityPetManager
---@param id number
function CityPetDatum:ctor(manager, id)
    self.manager = manager
    self.id = id
    ---@type string
    self.customName = nil
end

---@param castlePet wds.CastlePet
function CityPetDatum:Initialize(castlePet)
    self.wds = castlePet
    
    if self.wds.PetCompId ~= self.id then
        g_Logger.ErrorChannel("CityPetDatum", "PetCompId not match")
    end

    self.petCfg = ConfigRefer.Pet:Find(self.wds.PetConfigId)
    if not self.petCfg then
        g_Logger.ErrorChannel("CityPetDatum", "PetConfigId not valid")
    end
    ---@type table<number, PetWorkConfigCell>
    self.workAbility = {}
    for i = 1, self.petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(self.petCfg:PetWorks(i))
        self.workAbility[petWorkCfg:Type()] = petWorkCfg
    end

    local changed = false
    changed = changed or self.furnitureId ~= self.wds.FurnitureId
    self.furnitureId = self.wds.FurnitureId
    self.speed = math.max(1, self.wds.Speed)
    self.actorConfigWrapper = UnitActorConfigWrapper.new(self.speed, self.speed * 2)
    changed = changed or self.status ~= self.wds.Status
    self.status = self.wds.Status
    self.eatingFoodItemId = self.wds.EatingFoodItemId
    if self.hp ~= nil and self.wds.Hp > self.hp and self.eatingFoodItemId > 0 then
        self.eatFoodMark = true
    end
    changed = changed or self.eatFoodMark
    self.hp = self.wds.Hp
    self.serverPos = self.wds.Pos
    self.actionStartTime = self.wds.RealActionStartTime.ServerSecond
    self.nextFreeTime = self.wds.NextFreeTime.ServerSecond
    self.lastDecreaseHpTime = self.wds.LastDecreaseHpTime.ServerSecond
    changed = changed or self.workId ~= self.wds.CurWorkId
    self.workId = self.wds.CurWorkId
    self.carryInfo = {
        startPos = self.wds.CarryInfo.TargetPos,
        endPos = self.wds.CarryInfo.FinalPos,
        carryType = self.wds.CarryInfo.PetCarryType,
        furnitureId = self.wds.CarryInfo.ProcessFurnitureId,
        elementResCfgId = self.wds.CarryInfo.ResourceCfgId,
    }
    return changed
end

---@param castlePet wds.CastlePet
function CityPetDatum:SyncDataFromWds(castlePet, change)
    local changed = self:Initialize(castlePet)
    if changed then
        return true
    end

    if self:IsStrictMoving() and change.Pos then
        return true
    end

    return false
end

function CityPetDatum:GetPredictedHp()
    return self.hp + self:GetHpRecoverPerSecond() * math.floor(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() - self.lastDecreaseHpTime)
end

function CityPetDatum:GetHpRecoverPerSecond()
    return 1
end

function CityPetDatum:UnitActorConfigWrapper()
    return self.actorConfigWrapper
end

---@return string
function CityPetDatum:GetAssetPath()
    if self.petCfg then
        return ArtResourceUtils.GetItem(self.petCfg:CityModel())
    end
    return string.Empty
end

---@return number @default:1
function CityPetDatum:GetModelScale()
    if self.petCfg then
        local scale = ArtResourceUtils.GetScale(self.petCfg:CityModel())
        if scale ~= 0 then
            return scale
        end
    end
    return 1
end

function CityPetDatum:GetStatus()
    if self.eatFoodMark then
        self.eatFoodMark = nil
        return wds.CastlePetStatus.CastlePetStatusEating
    end
    return self.status
end

function CityPetDatum:IsCurrentActionValid()
    return self.nextFreeTime > 0 and self.nextFreeTime > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
end

function CityPetDatum:GetCurrentActionMovingTime()
    if self:IsCarrying() then
        if self:IsMovingToStartPoint() then
            return math.max(0, self.actionStartTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
        else
            return math.max(0, self.nextFreeTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
        end
    end
    return math.max(0, self.actionStartTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
end

---@return boolean 是否是一个严格的服务器移动行为（非闲逛寻路）
function CityPetDatum:IsStrictMoving()
    return self.status ~= wds.CastlePetStatus.CastlePetStatusWalking and self.status ~= wds.CastlePetStatus.CastlePetStatusBuilding
end

function CityPetDatum:IsWorking()
    return self.status == wds.CastlePetStatus.CastlePetStatusWorking
end

function CityPetDatum:GetWorkTargetPos()
    local workData = self.manager.city.cityWorkManager:GetWorkData(self.workId)
    if workData ~= nil then
        local workTarget = workData.targetId
        if workTarget > 0 then
            local element = self.manager.city.elementManager:GetElementById(workTarget)
            if element then
                local interactPos = self.manager.city.cityInteractPointManager:AcquireInteractPoint(CityInteractionPointType.Collect, (~0), {id = workTarget, type = CityWorkTargetType.Resource})
                if interactPos ~= nil then
                    local pos = interactPos:GetWorldPos()
                    local rotation = CS.UnityEngine.Quaternion.LookRotation(interactPos.worldRotation)
                    self.manager.city.cityInteractPointManager:DismissInteractPoint(interactPos)
                    return pos, rotation
                end
                return element:GetWorldPosition(), CS.UnityEngine.Quaternion.LookRotation(CS.UnityEngine.Vector3(1, 0, 1))
            end
            local furniture = self.manager.city.furnitureManager:GetFurnitureById(workTarget)
            if furniture then
                local interactPos = self.manager.city.cityInteractPointManager:AcquireInteractPoint(CityInteractionPointType.Operate, (~0), {id = workTarget, type = CityWorkTargetType.Furniture})
                if interactPos ~= nil then
                    local pos = interactPos:GetWorldPos()
                    local rotation = CS.UnityEngine.Quaternion.LookRotation(interactPos.worldRotation)
                    self.manager.city.cityInteractPointManager:DismissInteractPoint(interactPos)
                    return pos, rotation
                end
                local worldPosition = self.manager.city:GetWorldPositionFromCoord(furniture.x, furniture.y)
                return worldPosition, CS.UnityEngine.Quaternion.LookRotation(CS.UnityEngine.Vector3(1, 0, 1))
            end
        end
    end
    return self:GetFixedServerPos()
end

---@return string @根据工作家具和工作类型播放特定的动画状态机
function CityPetDatum:GetWorkAnimName()
    if self.workId > 0 then
        local workData = self.manager.city.cityWorkManager:GetWorkData(self.workId)
        if workData then
            return self.manager:GetWorkAnimNameByWorkCfg(workData.workCfg)
        end
    end
    if self.furnitureId > 0 then
        local furniture = self.manager.city.furnitureManager:GetFurnitureById(self.furnitureId)
        if furniture then
            for i = 1, furniture.furnitureCell:WorkListLength() do
                local workCfg = ConfigRefer.CityWork:Find(furniture.furnitureCell:WorkList(i))
                if workCfg and workCfg:Type() ~= CityWorkType.FurnitureLevelUp then
                    return self.manager:GetWorkAnimNameByWorkCfg(workCfg)
                end
            end
            return self.manager:GetWorkAnimNameByFurnitureType(furniture.furnitureCell:Type())
        end
    end
    return nil
end

---@return CS.UnityEngine.Vector3
function CityPetDatum:GetFixedServerPos()
    if self:IsCarrying() then
        if self:IsMovingToStartPoint() then
            return self.manager.city:GetWorldPositionFromCoord(self.carryInfo.startPos.X, self.carryInfo.startPos.Y)
        elseif self:IsCurrentActionValid() then
            return self.manager.city:GetWorldPositionFromCoord(self.carryInfo.endPos.X, self.carryInfo.endPos.Y)
        end
    end
    return self.manager.city:GetWorldPositionFromCoord(self.serverPos.X, self.serverPos.Y)
end

function CityPetDatum:GetDisplayName()
    if string.IsNullOrEmpty(self.customName) then
        return I18N.Get(self.petCfg:Name())
    end
    return self.customName
end

---@param workCfgId number @PetWorkCfg-Id
function CityPetDatum:CanDoWork(workCfgId)
    local workCfg = ConfigRefer.PetWork:Find(workCfgId)
    return self.workAbility[workCfg:Type()] ~= nil
end

---@param petWorkType number @PetWorkType
function CityPetDatum:CanDoWorkType(petWorkType)
    return self.workAbility[petWorkType] ~= nil
end

---@return number
function CityPetDatum:GetWorkLevel(petWorkType)
    local petWorkCfg = self.workAbility[petWorkType]
    if petWorkCfg then
        return petWorkCfg:Level()
    end
    return 0
end

function CityPetDatum:IsExhausted()
    return self.hp <= 1 and self.furnitureId ~= 0
end

function CityPetDatum:IsHungry()    
    local pet = ModuleRefer.PetModule:GetPetByID(self.id)
    if not pet then return false end

    local maxHp = pet.Props[ConfigRefer.PetConsts:PetAttrHp()] or 1
    return (self.hp / maxHp) < (ConfigRefer.CityConfig:PetHungryHp() / 100)
end

function CityPetDatum:GetHpPercent()
    local maxHp = self:GetMaxHp()
    if maxHp == 0 then return 0 end
    
    return math.clamp01(self.hp / maxHp)
end

function CityPetDatum:GetMaxHp()
    local pet = ModuleRefer.PetModule:GetPetByID(self.id)
    if not pet then return 0 end

    local maxHp = pet.Props[ConfigRefer.PetConsts:PetAttrHp()]
    return maxHp
end

function CityPetDatum:IsBuildMaster()
    return self.status == wds.CastlePetStatus.CastlePetStatusBuilding
end

function CityPetDatum:IsCarrying()
    return self.status == wds.CastlePetStatus.CastlePetStatusCarrying
end

function CityPetDatum:IsSleeping()
    return self.status == wds.CastlePetStatus.CastlePetStatusSleeping
end

function CityPetDatum:IsMovingToStartPoint()
    return self:IsCarrying() and g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() < self.actionStartTime
end

function CityPetDatum:GetCarryInfoPrefabNames()
    if not self:IsCarrying() then return nil end

    if self.carryInfo.carryType == wds.PetCarryType.PetCarryTypeResource then
        local resCfg = ConfigRefer.CityElementResource:Find(self.carryInfo.elementResCfgId)
        if resCfg then
            local ret = {}
            for i = 1, resCfg:LeftModelsLength() do
                local path = ArtResourceUtils.GetItem(resCfg:LeftModels(i))
                if not string.IsNullOrEmpty(path) then
                    table.insert(ret, path)
                end
            end
            return ret
        end
    elseif self.carryInfo.carryType == wds.PetCarryType.PetCarryTypeProcess then
        local furniture = self.manager.city.furnitureManager:GetFurnitureById(self.carryInfo.furnitureId)
        if furniture then
            local castleFurniture = furniture:GetCastleFurniture()
            if castleFurniture then
                local processCfg = ConfigRefer.CityWorkProcess:Find(castleFurniture.ProcessInfo.ConfigId)
                if processCfg then
                    local ret = {}
                    for i = 1, processCfg:LiftModelsLength() do
                        local path = ArtResourceUtils.GetItem(processCfg:LiftModels(i))
                        if not string.IsNullOrEmpty(path) then
                            table.insert(ret, path)
                        end
                    end
                    return ret
                end
            end
        end
    end

    return nil
end

function CityPetDatum:HasWorkType(petWorkType)
    return self.workAbility[petWorkType] ~= nil
end

function CityPetDatum:GetQuality()
    return self.petCfg:Quality()
end

---@return boolean @是否可以被抢占
function CityPetDatum:Preemptible()
    return self.workId == 0 or self.wds.PreemptibleWork
end

function CityPetDatum:CanBeClicked()
    if self.furnitureId == 0 then return true end

    local furniture = self.manager.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if not furniture then return true end

    if furniture:IsBuildMaster() then return true end
    if furniture:IsHotSpring() then return true end

    return false
end

return CityPetDatum