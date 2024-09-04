local DramaHandleBase = require("DramaHandleBase")
---@class FarmDramaHandle:DramaHandleBase
---@field new fun():FarmDramaHandle
local FarmDramaHandle = class("FarmDramaHandle", DramaHandleBase)
local StateMachine = require("StateMachine")
local FarmDramaStateRoute = require("FarmDramaStateRoute")
local FarmDramaStateWorking = require("FarmDramaStateWorking")
local FarmDramaStateMoving = require("FarmDramaStateMoving")
local FarmDramaStateStorage = require("FarmDramaStateStorage")
local FarmDramaStateAssetUnload = require("FarmDramaStateAssetUnload")
local Utils = require("Utils")
local DramaStateDefine = require("DramaStateDefine")

---@param petUnit CityUnitPet
function FarmDramaHandle:ctor(petUnit)
    ---@type CityFurnitureCropStatus
    self.farmCropComp = nil
    local furnitureId = petUnit.petData.furnitureId
    if furnitureId == 0 then
        g_Logger.ErrorChannel("LumbermillDramaHandle", "宠物数据异常")
        return
    end
    DramaHandleBase.ctor(self, petUnit, furnitureId)
    
    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState(DramaStateDefine.State.route, FarmDramaStateRoute.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.work, FarmDramaStateWorking.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.storage, FarmDramaStateStorage.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.move, FarmDramaStateMoving.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.assetunload, FarmDramaStateAssetUnload.new(self))

    self:Initialize()
end

function FarmDramaHandle:Start()
    DramaHandleBase.Start(self)

    if Utils.IsNotNull(self.go) then
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

function FarmDramaHandle:Tick(dt)
    self.stateMachine:Tick(dt)
end

function FarmDramaHandle:End()
    if self.farmCropComp then
        self.farmCropComp:ClearAllCrop()
    end
    self.petUnit:ReleaseAllAttachedModel()
    DramaHandleBase.End(self)
end

function FarmDramaHandle:OnAssetLoaded(go)
    self:PrepareAsset(go)
    if Utils.IsNotNull(self.go) then
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

function FarmDramaHandle:OnAssetUnload()
    self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
    self.go = nil
    self.holder = nil
    self.targetActPos = nil
    self.targetActRot = nil
    self.targetIndex = nil
    self.farmCropComp = nil
    self.targetCropValue = nil
    self.oneActionValue = nil
end

---@param go CS.UnityEngine.GameObject
function FarmDramaHandle:PrepareAsset(go)
    local holder = go:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNull(holder) then
        g_Logger.ErrorChannel("FarmDramaHandle", "家具表演所需的挂点脚本不存在")
        return
    end
    self.farmCropComp = nil
    local be = go:GetLuaBehaviourInChildren("CityFurnitureCropStatus")
    if Utils.IsNotNull(be) then
        self.farmCropComp = be.Instance
    end

    ---@type CS.FXAttachPointHolder
    self.holder = go:GetComponent(typeof(CS.FXAttachPointHolder))
    local target1 = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target1_act)
    local target2 = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target2_act)
    local target3 = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target3_act)
    local target4 = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target4_act)

    local storage = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.storage_act)

    ---@type CS.UnityEngine.Transform[]
    local targetPoints = {}
    self:CheckAndAddPoint(targetPoints, target1, target2, target3, target4, storage)

    if #targetPoints < 2 or Utils.IsNull(storage) then
        g_Logger.ErrorChannel("FarmDramaHandle", "家具表演所需的挂点未匹配")
        return
    end
    if self.farmCropComp then
        self.farmCropComp:ClearAllCrop()
    end
    local supportStatusCount = self.farmCropComp and self.farmCropComp:GetStatusCount() or 0
    self.targetActPos = {}
    self.targetActRot = {}
    for _, value in ipairs(targetPoints) do
        table.insert(self.targetActPos, value.position)
        table.insert(self.targetActRot, value.rotation)
    end
    self.targetIndex = math.random(1, #targetPoints - 1)
    self.counter = 0
    self.maxCount = 3
    self.targetCropValue = {}
    self.oneActionValue = supportStatusCount > 0 and (1.0 / supportStatusCount) or 1
    for i = 1, #targetPoints - 1 do
        self.targetCropValue[i] = math.random(0, supportStatusCount) * self.oneActionValue
    end
    self.storageIndex = #self.targetActPos
    self.go = go
    if self.farmCropComp then
        for index, value in ipairs(self.targetCropValue) do
            self.farmCropComp:SetupGrowNormalized(index, value)
        end
    end
end

function FarmDramaHandle:GetIndex()
    if self:IsCountFull() then
        return self.storageIndex
    else
        return self.targetIndex
    end
end

function FarmDramaHandle:IsCurrentFieldFull()
    local index = self:GetIndex()
    return self.targetCropValue[index] >= 1
end

function FarmDramaHandle:DoWater()
    local index = self:GetIndex()
    self.targetCropValue[index] = self.targetCropValue[index] + self.oneActionValue
    if self.farmCropComp then
        self.farmCropComp:SetupGrowNormalized(index, self.targetCropValue[index])
    end
end

function FarmDramaHandle:CountPlus()
    self.counter = self.counter + 1
    local index = self:GetIndex()
    if self.farmCropComp then
        self.targetCropValue[index] = 0
        self.farmCropComp:SetupGrowNormalized(index, 0)
    end
    local res,scale = self:GetResModleAttachUnit()
    if string.IsNullOrEmpty(res) then return end
    self.petUnit:AttachModelTo(res, scale, self.counter)
end

function FarmDramaHandle:CountClear()
    self.counter = 0
    self.petUnit:ReleaseAllAttachedModel()
end

function FarmDramaHandle:IsCountFull()
    return self.counter >= self.maxCount
end

function FarmDramaHandle:GetTargetPosition()
    local index = self:GetIndex()
    return self.targetActPos[index], self.targetActRot[index]
end

function FarmDramaHandle:MoveToNextActPoint()
    if not self:IsCountFull() then
        self.targetIndex = self.targetIndex + 1
        if self.targetIndex >= self.storageIndex then
            self.targetIndex = 1
        end
    end
    self.stateMachine:ChangeState(DramaStateDefine.State.route)
end

function FarmDramaHandle:IsResReady()
    return Utils.IsNotNull(self.go)
end

return FarmDramaHandle