---@class CityPetBuildMasterInfo
---@field new fun():CityPetBuildMasterInfo
local CityPetBuildMasterInfo = class("CityPetBuildMasterInfo")
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local CityInteractionPointType = require("CityInteractionPointType")
local CityWorkTargetType = require("CityWorkTargetType")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@param manager CityPetManager
function CityPetBuildMasterInfo:ctor(manager, furnitureId)
    self.manager = manager
    self.city = manager.city
    self.furnitureId = furnitureId
    self.targetId = nil
    self.targetPosition = CS.UnityEngine.Vector3.zero
    self.targetRotation = CS.UnityEngine.Quaternion.identity
    ---@type table<CityUnitPet, boolean>
    self.petUnits = {}
    self.started = false
end

function CityPetBuildMasterInfo:GetTargetPosition()
    return self.targetPosition, self.targetRotation
end

---@return CS.UnityEngine.Vector3 @返回要前往进行建造的地方
function CityPetBuildMasterInfo:GetTargetPositionImp()
    if self.targetId == nil then
        return CS.UnityEngine.Vector3.zero, CS.UnityEngine.Quaternion.identity
    else
        local needOwnerInfo = {}
        needOwnerInfo.id = self.targetId
        needOwnerInfo.type = CityWorkTargetType.Furniture
        local furniture = self.city.furnitureManager:GetFurnitureById(self.targetId)
        local targetPos = furniture:UpdatePos()
        local targetDir = furniture:UpdateForward().normalized
        local targetRot = CS.UnityEngine.Quaternion.Euler(targetDir.x, targetDir.y, targetDir.z)
        local handle = self.city.cityInteractPointManager:AcquireInteractPoint(CityInteractionPointType.Upgrade, ~(0), needOwnerInfo)
        if handle ~= nil then
            targetPos = handle:GetWorldPos()
            targetRot = CS.UnityEngine.Quaternion.LookRotation(handle.worldRotation)
            self.city.cityInteractPointManager:DismissInteractPoint(handle)
        end
        return targetPos, targetRot
    end
end

---@private
---@param petUnit CityUnitPet
function CityPetBuildMasterInfo:RegisterPetPerformanceReady(petUnit)
    if not petUnit:IsModelReady() then return end

    self.petUnits[petUnit] = true
    self:UpdateOrderedLiftModels()
end

function CityPetBuildMasterInfo:NeedMove(petUnit)
    return not petUnit:IsCloseTo(self:GetTargetPosition())
end

function CityPetBuildMasterInfo:TryRegisterBuildMasterReady(petUnit)
    if not self:NeedMove(petUnit) then
        self:RegisterPetPerformanceReady(petUnit)
    end
end

function CityPetBuildMasterInfo:UnregisterBuildMaster(petUnit)
    self.petUnits[petUnit] = nil
    self:UpdateOrderedLiftModels()
end

function CityPetBuildMasterInfo:UpdateOrderedLiftModels()
    ---@type CityUnitPet[]
    local orderList = {}
    for petUnit, _ in pairs(self.petUnits) do
        if petUnit:IsModelReady() then
            table.insert(orderList, petUnit)
        end
    end

    ---@param a CityUnitPet
    ---@param b CityUnitPet
    table.sort(orderList, function(a, b)
        return a:GetSize() > b:GetSize()
    end)

    if #orderList == 1 then
        orderList[1]:StopMove()
        orderList[1]:SyncAnimatorSpeed()
        orderList[1]:PlayLoopState(CityPetAnimStateDefine.Construct)
        return
    end

    for i, petUnit in ipairs(orderList) do
        petUnit:StopMove()
        petUnit:DetachFromPrevPetAnchor()
        petUnit:SyncAnimatorSpeed()

        if i > 1 then
            petUnit:AttachToPrevPetAnchor(orderList[i - 1])
        end

        if i < #orderList then
            petUnit:PlayLoopState(CityPetAnimStateDefine.Lift)
        else
            petUnit:PlayLoopState(CityPetAnimStateDefine.Construct)
        end
    end
end

function CityPetBuildMasterInfo:UpdateTargetInfo()
    local map = self.city:GetCastle().GlobalData.BuildingMasterStatues2Target
    local targetId = map[self.furnitureId]
    
    if self.targetId ~= targetId then
        if self.started then
            self:StopBuildMaster()
        end
        self.started = targetId ~= nil
        self.targetId = targetId
        if self.started then
            self:StartBuildMaster()
        else
            self:StopBuildMaster()
        end
    end
end

---@private
function CityPetBuildMasterInfo:StartBuildMaster()
    local petIdsMap = self.manager:GetPetIdByWorkFurnitureId(self.furnitureId)
    self.targetPosition, self.targetRotation = self:GetTargetPositionImp()
    
    if petIdsMap == nil then return end
    for id, _ in pairs(petIdsMap) do
        local petUnit = self.manager.unitMap[id]
        if petUnit then
            self:TryRegisterBuildMasterReady(petUnit)
        end
    end

    g_Game.EventManager:AddListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMove))
end

function CityPetBuildMasterInfo:StopBuildMaster()
    g_Game.EventManager:RemoveListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMove))
    self.petUnits = {}
    self.targetPosition = CS.UnityEngine.Vector3.zero
    self.targetRotation = CS.UnityEngine.Quaternion.identity
end

function CityPetBuildMasterInfo:OnFurnitureMove(city, oldx, oldy, newx, newy)
    if self.city ~= city then return end

    local furniture = self.city.furnitureManager:GetPlaced(newx, newy)
    if furniture and furniture.singleId == self.targetId then
        ---@type CityUnitPet[]
        local units = {}
        for petUnit, _ in pairs(self.petUnits) do
            table.insert(units, petUnit)
        end
        self:StopBuildMaster()
        self:StartBuildMaster()
        for _, petUnit in ipairs(units) do
            petUnit:SyncFromServer()
        end
    end
end

return CityPetBuildMasterInfo