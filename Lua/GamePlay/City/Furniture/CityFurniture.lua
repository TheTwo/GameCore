local ConfigRefer = require("ConfigRefer")
local CityCitizenDefine = require("CityCitizenDefine")
local I18N = require("I18N")
local FurnitureCategory = require("FurnitureCategory")
local CityAttrType = require("CityAttrType")
local CityProcessUtils = require("CityProcessUtils")
local UIMediatorNames = require("UIMediatorNames")
local CityUtils = require("CityUtils")

---@class CityFurniture:CityCellBase
---@field new fun(manager, configId, singleId, direction):CityFurniture
---@field singleId number
---@field furnitureCell CityFurnitureLevelConfigCell
---@field isNew boolean 是否是刚放下
---@field navMeshes {x:number, y:number, sizeX:number, sizeY:number}
---@field lastNavmeshes {x:number, y:number, sizeX:number, sizeY:number}
local CityFurniture = class("CityFurniture")
local EventConst = require("EventConst")
local CityWorkType = require("CityWorkType")
local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
local ModuleRefer = require("ModuleRefer")
local NpcServiceObjectType = require("NpcServiceObjectType")

---@param manager CityFurnitureManager
function CityFurniture:ctor(manager, configId, singleId, direction)
    self.manager = manager
    self.singleId = singleId
    self.direction = direction or 0
    self.battleState = false
    self.functions = {}
    ---@type number[]
    self.interactPoints = {}
    self:UpdateConfigId(configId)
    self:UpdateSize()
    self:UpdateObjectAxis()
end

function CityFurniture:UpdateConfigId(configId)
    self.configId = configId
    self.furnitureCell = ConfigRefer.CityFurnitureLevel:Find(configId)
    self.level = self.furnitureCell:Level()
    self.furType = self.furnitureCell:Type()
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.furType)
    self.name = I18N.Get(typCfg:Name())
    self.image = typCfg:Image()
    self.displaySort = typCfg:DisplaySort()

    self:ResetFunctions()

    for i = 1, self.furnitureCell:WorkListLength() do
        local workCfgId = self.furnitureCell:WorkList(i)
        local workCfg = ConfigRefer.CityWork:Find(workCfgId)
        if workCfg ~= nil then
            local workType = workCfg:Type()
            if self.functions[workType] == 0 then
                self.functions[workType] = workCfg:Id()
            else
                g_Logger.Error("重复类型WorkCfgId")
            end
        else
            g_Logger.ErrorChannel("CityFurniture", "找不到WorkCfgId:[%d]对应的配置", workCfgId)
        end
    end
end

function CityFurniture:ResetFunctions()
    for _, idx in pairs(CityWorkType) do
        self.functions[idx] = 0
    end
end

function CityFurniture:GetCastleFurniture()
    return self.manager:GetCastleFurniture(self.singleId)
end

function CityFurniture:IsOutside()
    local castleFurniture = self:GetCastleFurniture()
    if not castleFurniture then
        return false
    end
    return castleFurniture.BuildingId == 0 or self.manager.city.legoManager:DontHasRoof(castleFurniture.BuildingId)
end

function CityFurniture:IsLocked()
    local castleFurniture = self:GetCastleFurniture()
    if not castleFurniture then
        return false
    end
    return castleFurniture.Locked
end

function CityFurniture:IsPolluted()
    if self:GetCastleFurniture() ~= nil then
        return self:GetCastleFurniture().Polluted
    end
    return false
end

function CityFurniture:MarkIsNew()
    self.isNew = true
end

function CityFurniture:IsNew()
    return self.isNew
end

function CityFurniture:ClearNewMark()
    self.isNew = false
end

function CityFurniture:SetDirection(direction)
    self.direction = direction
    self:UpdateSize()
    return self
end

function CityFurniture:IsInBuilding()
    return self.manager.city.gridLayer:IsInnerBuildingMask(self.x, self.y)
end

function CityFurniture:UpdateSize()
    self.sizeX = self:IsXYExChange() and (self.furnitureCell:SizeY() or 1) or (self.furnitureCell:SizeX() or 1)
    self.sizeY = self:IsXYExChange() and (self.furnitureCell:SizeX() or 1) or (self.furnitureCell:SizeY() or 1)
end

function CityFurniture:UpdateObjectAxis()
    if self.direction == 0 then
        self.axisX = {x = 1, y = 0}
        self.axisY = {x = 0, y = 1}
    elseif self.direction == 90 then
        self.axisX = {x = 0, y = -1}
        self.axisY = {x = 1, y = 0}
    elseif self.direction == 180 then
        self.axisX = {x = -1, y = 0}
        self.axisY = {x = 0, y = -1}
    elseif self.direction == 270 then
        self.axisX = {x = 0, y = 1}
        self.axisY = {x = -1, y = 0}
    end
end

function CityFurniture:GetObjectAxisPosBase()
    if self.direction == 0 then
        return self.x, self.y
    elseif self.direction == 90 then
        return self.x, self.y + self.sizeY - 1
    elseif self.direction == 180 then
        return self.x + self.sizeX - 1, self.y + self.sizeY - 1
    elseif self.direction == 270 then
        return self.x + self.sizeX - 1, self.y
    end
end

function CityFurniture:UpdateNavmeshData()
    self.lastNavmeshes = self.navMeshes
    self.navMeshes = {}
    self.baseX, self.baseY = self:GetObjectAxisPosBase()
    local navHalfBaseX,navHalfBaseY = self.baseX * 2, self.baseY * 2
    local validCfgCount = 0
    for i = 1, self.furnitureCell:InnerBlockSpaceLength() do
        local rect = self.furnitureCell:InnerBlockSpace(i)
        local width, height = rect:Width(), rect:Height()
        if width > 0 and height > 0 then
            validCfgCount = validCfgCount + 1
            local ox, oy = rect:MinX(), rect:MinY()
            local startX = navHalfBaseX + ox * self.axisX.x + oy * self.axisY.x
            local startY = navHalfBaseY + ox * self.axisX.y + oy * self.axisY.y
            local endX = startX + width * self.axisX.x + height * self.axisY.x
            local endY = startY + width * self.axisX.y + height * self.axisY.y

            local minX, maxX = math.min(startX, endX), math.max(startX, endX)
            local minY, maxY = math.min(startY, endY), math.max(startY, endY)
            table.insert(self.navMeshes, {x = minX, y = minY, sizeX = maxX - minX, sizeY = maxY - minY})
        end
    end

    --- 当未配置家具内部阻挡时，默认此家具完全不可走
    if validCfgCount == 0 then
        table.insert(self.navMeshes, {x = self.x * 2, y = self.y * 2, sizeX = self.sizeX * 2, sizeY = self.sizeY * 2})
    end
end

function CityFurniture:IsXYExChange()
    return self.direction == 90 or self.direction == 270
end

function CityFurniture:SetPos(x, y)
    self.x, self.y = x, y
    return self
end

function CityFurniture:Besides(x, y)
    return x >= self.x and x < self.x + self.sizeX and y >= self.y and y < self.y + self.sizeY
end

function CityFurniture:UniqueId()
    return self.singleId
end

function CityFurniture:ConfigId()
    return self.configId
end

function CityFurniture:IsFurniture()
    return true
end

---@param reason CityCitizenDefine.WorkTargetReason
---@return number, number
function CityFurniture:GetCollectPos(reason)
    local offsetX,offsetY = self:GetLocalCollectOffset(reason)
    return self.x + offsetX, self.y + offsetY
end

function CityFurniture:IsCreepFurniture()
    return self.furType == ConfigRefer.CityConfig:CreepClearFurniture()
end

function CityFurniture:GetFurnitureType()
    return self.furType
end

---@param reason CityCitizenDefine.WorkTargetReason
function CityFurniture:GetCollectPosDirPos(reason)
    local offsetX,offsetY = self:GetLocalCollectOffset(reason)
    local dir = 0
    if self.furnitureCell:CollectPosLength() > 2 then
        dir = self.furnitureCell:CollectPos(3)
    end
    if self.direction == 90 then
        if dir == 1 then
            dir = 4
        elseif dir == 2 then
            dir = 3
        elseif dir == 3 then
            dir = 1
        elseif dir == 4 then
            dir = 2
        end
    elseif self.direction == 180 then
        if dir == 1 then
            dir = 2
        elseif dir == 2 then
            dir = 1
        elseif dir == 3 then
            dir = 4
        elseif dir == 4 then
            dir = 3
        end
    elseif self.direction == 270 then
        if dir == 1 then
            dir = 3
        elseif dir == 2 then
            dir = 4
        elseif dir == 3 then
            dir = 2
        elseif dir == 4 then
            dir = 1
        end
    end
    if dir == 1 then
        return offsetX, offsetY + 1
    elseif dir == 2 then
        return offsetX, offsetY - 1
    elseif dir == 3 then
        return offsetX - 1, offsetY
    elseif dir == 4 then
        return offsetX + 1, offsetY
    end
    return 0.5 * self.sizeX,0.5 * self.sizeY
end

---@param reason CityCitizenDefine.WorkTargetReason
function CityFurniture:GetLocalCollectOffset(reason)
    local x = 0
    local y = 0
    if reason then
        local config = ConfigRefer.CityFurnitureInteractPos:Find(self.furnitureCell:InteractPos())
        if config then
            if reason == CityCitizenDefine.WorkTargetReason.Base then
                local p = config:BasePos()
                x = p:X()
                y = p:Y()
            elseif reason == CityCitizenDefine.WorkTargetReason.Operate then
                local p = config:OperatePos()
                x = p:X()
                y = p:Y()
            else
                goto GetLocalCollectOffset_NO_REASON
            end
            if self.direction == 90 then
                return y, self.sizeX - x
            elseif self.direction == 180 then
                return self.sizeX - x, self.sizeY - y
            elseif self.direction == 270 then
                return self.sizeY - y, x
            end
            return x,y
        end
    end
    ::GetLocalCollectOffset_NO_REASON::
    if self.furnitureCell:CollectPosLength() > 0 then
        x = self.furnitureCell:CollectPos(1)
        y = self.furnitureCell:CollectPos(2)
        if self.direction == 90 then
            return y, self.sizeX - x
        elseif self.direction == 180 then
            return self.sizeX - x, self.sizeY - y
        elseif self.direction == 270 then
            return self.sizeY - y, x
        end
        return x,y
    else
        if self.direction == 90 then
            return 0, 0.5 * self.sizeY
        elseif self.direction == 180 then
            return 0.5 * self.sizeX,self.sizeY
        elseif self.direction == 270 then
            return self.sizeX, 0.5 * self.sizeY
        end
    end
    return 0.5 * self.sizeX,0
end

function CityFurniture:CenterPos()
    if self.x and self.y then
        return self.manager.city:GetCenterWorldPositionFromCoord(self.x, self.y, self.sizeX, self.sizeY)
    end
    return CS.UnityEngine.Vector3.zero
end

function CityFurniture:CenterGrid()
    return self.x + 0.5 * self.sizeX, self.y + 0.5 * self.sizeY
end

function CityFurniture:UpdatePos()
    if self.x and self.y then
        return self.manager.city:GetWorldPositionFromCoord(self.x + self.sizeX, self.y)
    end
    return CS.UnityEngine.Vector3.zero
end

function CityFurniture:UpdateForward()
    return CS.UnityEngine.Vector3(-self.sizeX, 0, self.sizeY)
end

function CityFurniture:SetBattleState(inBattle)
    self.battleState = inBattle
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_ASSET_UPDATE, wds.CityBattleObjType.CityBattleObjTypeFurniture, self.singleId)
end

function CityFurniture:UpdateHP(hp,maxhp)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_HP_UPDATE, wds.CityBattleObjType.CityBattleObjTypeFurniture, self.singleId)
end

function CityFurniture:SetAttackingState(inAttacking, targetTrans)
    if inAttacking and not self.battleState then
        self:SetBattleState(true)
    end
    local name = targetTrans == nil and "empty" or targetTrans.gameObject.name
    self.inAttacking = inAttacking
    self.targetTrans = targetTrans
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_ASSET_ATTACK_TARGET, wds.CityBattleObjType.CityBattleObjTypeFurniture, self.singleId)
end

---@param targetPos CS.UnityEngine.Vector3
---@param animName string
---@param animDuration number
function CityFurniture:PlaySkill(targetPos, animName, animDuration)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_PLAY_SKILL, wds.CityBattleObjType.CityBattleObjTypeFurniture, self.singleId, targetPos, animName, animDuration)
end

---@see CityTileAssetSLGUnitLifeBarTempBase
function CityFurniture:IsInBattleState()
    return self.battleState
end

function CityFurniture:Clone()
    return CityFurniture.new(self.manager, self.configId, self.singleId, self.direction):SetPos(self.x, self.y)
end

function CityFurniture:GetUnitArea()
    local isXLine = self.sizeX > self.sizeY
    if isXLine then
        return self.x - 0.5, self.y - 3, self.sizeX + 1, self.sizeY + 6
    else
        return self.x - 3, self.y - 0.5, self.sizeX + 6, self.sizeY + 1
    end
end

---@see CityTileAssetSLGUnitLifeBarTempBase
function CityFurniture:ForceShowLifeBar()
    local state = self.manager.city.stateMachine:GetCurrentState()
    if state and state:GetName() == "CityStateFurnitureSelect" then
        local cellTile = state.cellTile
        if cellTile and cellTile:GetCell() == self then
            return true
        end
    end
    return false
end

function CityFurniture:CanDoCityWork(workType)
    if workType == nil then return false end
    if self.functions == nil then return false end
    return self.functions[workType] ~= 0
end

function CityFurniture:GetWorkCfgId(workType)
    if workType == nil then return 0 end
    if self.functions == nil then return 0 end
    return self.functions[workType] or 0
end

function CityFurniture:IsMakingFurnitureProcess()
    local workCfgId = self:GetWorkCfgId(CityWorkType.Process)
    if workCfgId == 0 then return false end

    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    if workCfg == nil then return false end

    for i = 1, workCfg:ProcessListLength() do
        local recipe = ConfigRefer.CityProcess:Find(workCfg:ProcessList(i))
        if recipe then
            local output = ConfigRefer.ItemGroup:Find(recipe:Output())
            if output ~= nil and output:ItemGroupInfoListLength() > 0 then
                local firstItemInfo = output:ItemGroupInfoList(1)
                local itemId = firstItemInfo:Items()
                if itemId > 0 and ModuleRefer.CityConstructionModule:IsFurnitureRelativeItem(itemId) then
                    return true
                end
            end
        end
    end
    return false
end

function CityFurniture:ToString()
    return string.format("CityFurniture: %d", self.singleId)
end

---@return number|nil
function CityFurniture:GetUpgradingWorkId()
    local castleFurniture = self:GetCastleFurniture()
    if not castleFurniture.LevelUpInfo.Working or castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress then
        return nil
    end
    return castleFurniture.WorkType2Id[CityWorkType.FurnitureLevelUp]
end

function CityFurniture:IsUpgrading()
    local castleFurniture = self:GetCastleFurniture()
    return castleFurniture.LevelUpInfo.Working and castleFurniture.LevelUpInfo.CurProgress < castleFurniture.LevelUpInfo.TargetProgress
end

function CityFurniture:IsUpgradingPaused()
    local castleFurniture = self:GetCastleFurniture()
    return castleFurniture.LevelUpInfo.Working and self:IsWorkPausedOrStopped(CityWorkType.FurnitureLevelUp)
end

function CityFurniture:IsShowUpgradingBar()
    if not self:IsUpgrading() then return false end
    local workId = self:GetUpgradingWorkId()
    if workId == nil then return false end

    local workData = self.manager.city.cityWorkManager:GetWorkData(workId)
    if workData == nil then return false end

    return g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() > workData.realStartTime + 1.2
end

function CityFurniture:IsProducing()
    local castleFurniture = self:GetCastleFurniture()
    return castleFurniture.ResourceGenerateInfo and castleFurniture.ResourceGenerateInfo.GeneratePlan:Count() > 0
end

function CityFurniture:GetPausedLevelUpProgress()
    local castleFurniture = self:GetCastleFurniture()
    return math.clamp01(castleFurniture.LevelUpInfo.CurProgress / castleFurniture.LevelUpInfo.TargetProgress)
end

function CityFurniture:GetPausedLevelUpRemainTime()
    local castleFurniture = self:GetCastleFurniture()
    return math.max(0, castleFurniture.LevelUpInfo.TargetProgress - castleFurniture.LevelUpInfo.CurProgress)
end

function CityFurniture:GetNormalLevelUpProgress()
    local castleFurniture = self:GetCastleFurniture()
    local cur = castleFurniture.LevelUpInfo.CurProgress
    local target = castleFurniture.LevelUpInfo.TargetProgress
    local workId = castleFurniture.WorkType2Id[CityWorkType.FurnitureLevelUp]
    if workId ~= nil then
        cur = cur + self.manager.city:GetWorkTimeSyncGap()
    end
    
    return math.clamp01(cur / target)
end

function CityFurniture:GetNormalLevelUpProgressRemainTime()
    local castleFurniture = self:GetCastleFurniture()
    local cur = castleFurniture.LevelUpInfo.CurProgress
    local target = castleFurniture.LevelUpInfo.TargetProgress
    local workId = castleFurniture.WorkType2Id[CityWorkType.FurnitureLevelUp]
    if workId ~= nil then
        cur = cur + self.manager.city:GetWorkTimeSyncGap()
    end
    
    return math.max(0, target - cur)
end

function CityFurniture:IsProcessPaused()
    local castleFurniture = self:GetCastleFurniture()
    if castleFurniture.ProcessInfo:Count() == 0 then return false end

    for i, v in ipairs(castleFurniture.ProcessInfo) do
        if (v.LeftNum > 0 or v.Auto) and self:IsWorkPausedOrStopped(CityWorkType.Process) then
            return true
        end
    end
    return false
end

function CityFurniture:IsWorkPausedOrStopped(workType)
    local castleFurniture = self:GetCastleFurniture()
    if castleFurniture.WorkType2Id[workType] == nil then
        return true
    end
    local workId = castleFurniture.WorkType2Id[workType]
    local workData = self.manager.city.cityWorkManager:GetWorkData(workId)
    if not workData then
        return true
    end
    return workData.Suspending
end

function CityFurniture:IsMainBase()
    return self.furType == CityFurnitureTypeNames["1000101"]
end

function CityFurniture:IsPetFur()
    return self.furType == CityFurnitureTypeNames.pet_system
end

function CityFurniture:RegisterInteractPoints()
    local config = self.furnitureCell
    if not config then
        return
    end
    local rotation = self.direction
    ---@type CityLegoBuilding
    local ownerBuilding
    local rangeMinX,rangeMinY,rangeMaxX,rangeMaxY
    if self:IsInBuilding() then
        ---@type CityLegoBuilding
        ownerBuilding = self.manager.city.legoManager:GetLegoBuilding(self:GetCastleFurniture().BuildingId)
        rangeMinX = ownerBuilding.x
        rangeMinY = ownerBuilding.z
        rangeMaxX = rangeMinX + ownerBuilding.sizeX
        rangeMaxY = rangeMinY + ownerBuilding.sizeZ
    end
    local sx = self.sizeX
    local sy = self.sizeY
    for i = 1, config:RefInteractPosLength() do
        local refPointId = config:RefInteractPos(i)
        local refPointConfig = ConfigRefer.CityInteractionPoint:Find(refPointId)
        self.manager:OnFurnitureRegisterInteractPoint(self, refPointConfig, rotation, ownerBuilding, rangeMinX,rangeMinY,rangeMaxX,rangeMaxY, sx, sy)
    end
end

function CityFurniture:UnRegisterInteractPoints()
    self.manager:OnFurnitureUnRegisterInteractPoint(self)
    table.clear(self.interactPoints)
end

function CityFurniture:RequestToRepair(skipUICheck)
    if not self:GetCastleFurniture().Locked then return false end
    if self:GetCastleFurniture().Polluted then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("repair_furniture_tips"))
        return false
    end

    ModuleRefer.PlayerServiceModule:InteractWithTarget(NpcServiceObjectType.Furniture, self.singleId, skipUICheck)
    return true
end

function CityFurniture:IsMainFurniture()
    return self.furType == ConfigRefer.CityConfig:MainFurnitureType()
end

function CityFurniture:CanUpgrade(ignoreResourceCheck)
    local workCfgId = self:GetWorkCfgId(CityWorkType.FurnitureLevelUp)
    if workCfgId == 0 then
        return false
    end

    local castleFurniture = self:GetCastleFurniture()
    if castleFurniture.Polluted then
        return false
    end

    local workType = CityWorkType.FurnitureLevelUp
    local workId = castleFurniture.WorkType2Id[workType] or 0
    local workData = self.manager.city.cityWorkManager:GetWorkData(workId)

    if workId > 0 and workData and workData.ConfigId ~= workCfgId then
        return false
    end

    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    local CityWorkFormula = require("CityWorkFormula")

    local upgradingCount = self.manager.city.cityWorkManager:GetWorkingCountByType(workCfg:Type())
    local maxCount = self.manager:GetUpgradeQueueMaxCount()
    if upgradingCount >= maxCount then
        return false
    end

    if not self:IsUpgradeConditionMeet() then
        return false
    end

    local nextLvCell = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(self.furType, self.level + 1)
    if nextLvCell == nil then
        return false
    end

    if not ignoreResourceCheck then
        local itemGroup = ConfigRefer.ItemGroup:Find(nextLvCell:LevelUpCost())
        local cost = CityWorkFormula.CalculateInput(workCfg, itemGroup, nil, self.singleId)
        for i, v in ipairs(cost) do
            if ModuleRefer.InventoryModule:GetAmountByConfigId(v.id) < v.count then
                return false
            end
        end
    end

    return true
end

function CityFurniture:IsUpgradeConditionMeet()
    for i = 1, self.furnitureCell:LevelUpConditionLength() do
        local taskId = self.furnitureCell:LevelUpCondition(i)
        local taskCfg = ConfigRefer.Task:Find(taskId)
        if taskCfg ~= nil then
            local status = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskCfg:Id())
            local finished = status == wds.TaskState.TaskStateFinished or status == wds.TaskState.TaskStateCanFinish
            if not finished then
                return false
            end
        end
    end

    return true
end

function CityFurniture:GetName()
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.furType)
    return I18N.Get(typCfg:Name())
end

function CityFurniture:IsConfigMovable()
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.furType)
    return typCfg:Movable()
end

function CityFurniture:IsConfigUnclickable()
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.furType)
    return typCfg.Unclickable ~= nil and typCfg:Unclickable()
end

function CityFurniture:Movable()
    return self:IsConfigMovable() and not self:IsPolluted() and not self:IsLocked()
end

function CityFurniture:GetNotMovableReason()
    if not self:IsConfigMovable() then
        return I18N.GetWithParams("toast_cantmove_fur_config", self:GetName())
    elseif self:IsPolluted() then
        return I18N.GetWithParams("tips_polluted_cant_move", self:GetName())
    elseif self:IsLocked() then
        return I18N.GetWithParams("toast_cantmove_needrepair", self:GetName())
    -- elseif self:IsProducing() then
    --     return I18N.Get(CityStateI18N.Toast_CantMovingProducingFurniture)
    end
    return string.Empty
end

function CityFurniture:IsFogMask()
    if not self.x or not self.y or not self.sizeX or not self.sizeY then
        return false
    end

    return self.manager.city:IsFogMaskRect(self.x, self.y, self.sizeX, self.sizeY)
end

function CityFurniture:IsZoneRecovered()
    if not self.x or not self.y or not self.sizeX or not self.sizeY then
        return false
    end
    return self.manager.city.zoneManager:IsZoneRecovered(self.x, self.y)
end

function CityFurniture:NotFullLevel()
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.furType)
    return self.level < typCfg:MaxLevel()
end

function CityFurniture:IsDecoration()
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.furType)
    return typCfg:Category() == FurnitureCategory.Decoration
end

function CityFurniture:GetPetWorkSlotCount()
    local castle = self.manager.city:GetCastle()
    local castleAttr = castle.CastleAttribute
    local furAttr = castleAttr.FurnitureAttr[self.singleId]
    if furAttr then
        return ModuleRefer.CastleAttrModule:GetValueWithFurniture(CityAttrType.WorkSlotNum, self.singleId, true)
    end
    return 0
end

function CityFurniture:CanHatchEggCount()
    if not self:CanDoCityWork(CityWorkType.Incubate) then return 0 end

    local workCfgId = self:GetWorkCfgId(CityWorkType.Incubate)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    if not workCfg then return 0 end

    local ownCount = 0
    ---@type CityWorkProcessConfigCell[]
    local unlockedRecipes = {}
    for i = 1, workCfg:ProcessCfgLength() do
        local processCfg = ConfigRefer.CityWorkProcess:Find(workCfg:ProcessCfg(i))
        if CityProcessUtils.IsRecipeVisible(processCfg) then
            if CityProcessUtils.IsRecipeUnlocked(processCfg) then
                table.insert(unlockedRecipes, processCfg)
            end
        end
    end
    for i, v in ipairs(unlockedRecipes) do
        ownCount = ownCount + CityProcessUtils.GetCostEnoughTimes(v)
    end
    return ownCount
end

---@return fun():numberm,number,number,number @x,y,sizeX,sizeY
function CityFurniture:PreNavDataPairs()
    local key, value = nil, nil
    return function()
        if self.lastNavmeshes == nil then return end
        key, value = next(self.lastNavmeshes, key)
        if key ~= nil then
            return value.x, value.y, value.sizeX, value.sizeY
        end
    end
end

---@return fun():numberm,number,number,number @x,y,sizeX,sizeY
function CityFurniture:NavDataPairs()
    local key, value = nil, nil
    return function()
        if self.navMeshes == nil then return end
        key, value = next(self.navMeshes, key)
        if key ~= nil then
            return value.x, value.y, value.sizeX, value.sizeY
        end
    end
end

function CityFurniture:IsBuildMaster()
    return CityUtils.IsBuildMaster(self.furType)
end

function CityFurniture:IsHotSpring()
    return self.furType == ConfigRefer.CityConfig:HotSpringFurniture()
end

function CityFurniture:IsTemperatureBooster()
    return self.furType == ConfigRefer.CityConfig:TemperatureBooster()
end

function CityFurniture:TryOpenLvUpUI()
    local workCfg = ConfigRefer.CityWork:Find(self:GetWorkCfgId(CityWorkType.FurnitureLevelUp))
    if workCfg == nil then return false end

    if not self.x or not self.y then return false end
    local tile = self.manager.city.gridView:GetFurnitureTile(self.x, self.y)

    if tile == nil then return false end

    local CityWorkFurnitureUpgradeUIParameter = require("CityWorkFurnitureUpgradeUIParameter")
    local param = CityWorkFurnitureUpgradeUIParameter.new(workCfg, tile)
    g_Game.UIManager:Open(UIMediatorNames.CityWorkFurnitureUpgradeUIMediator, param)
    return true
end

function CityFurniture:TryOpenHatchEggUI()
    local workCfg = ConfigRefer.CityWork:Find(self:GetWorkCfgId(CityWorkType.Incubate))
    if workCfg == nil then return false end

    if not self.x or not self.y then return false end
    local tile = self.manager.city.gridView:GetFurnitureTile(self.x, self.y)

    if tile == nil then return false end

    local CityHatchEggUIParameter = require("CityHatchEggUIParameter")
    local param = CityHatchEggUIParameter.new(tile)
    g_Game.UIManager:Open(UIMediatorNames.CityHatchEggUIMediator, param)
    return true
end

function CityFurniture:GetUpgradeCostTime()
    local nextLvCfg = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(self.furType, self.level + 1)
    if nextLvCfg == nil then return 0 end

    return self.manager:GetFurnitureUpgradeCostTime(nextLvCfg)
end

return CityFurniture
