local StateMachine = require("StateMachine")
local Utils = require("Utils")
local DramaStateDefine = require("DramaStateDefine")
local ManualResourceConst = require("ManualResourceConst")

local DramaHandleBase = require("DramaHandleBase")

local MineDramaStateRoute = require("MineDramaStateRoute")
local MineDramaStateWorking = require("MineDramaStateWorking")
local MineDramaStateMoving = require("MineDramaStateMoving")
local MineDramaStateStorage = require("MineDramaStateStorage")
local MineDramaStateAssetUnload = require("MineDramaStateAssetUnload")

---@class MineDramaHandle:DramaHandleBase
---@field new fun(petUnit:CityUnitPet):MineDramaHandle
---@field super DramaHandleBase
local MineDramaHandle = class("MineDramaHandle", DramaHandleBase)

---@param petUnit CityUnitPet
function MineDramaHandle:ctor(petUnit)
    local furnitureId = petUnit.petData.furnitureId
    if furnitureId == 0 then
        g_Logger.ErrorChannel("MineDramaHandle", "宠物数据异常")
        return
    end
    MineDramaHandle.super.ctor(self, petUnit, furnitureId)

    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState(DramaStateDefine.State.route, MineDramaStateRoute.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.work, MineDramaStateWorking.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.move, MineDramaStateMoving.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.storage, MineDramaStateStorage.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.assetunload, MineDramaStateAssetUnload.new(self))

    self:Initialize()
end

function MineDramaHandle:Start()
    MineDramaHandle.super.Start(self)

    if self:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

function MineDramaHandle:End()
    self.petUnit:ReleaseAllAttachedModel()
    MineDramaHandle.super.End(self)
end

function MineDramaHandle:Tick(dt)
    self.stateMachine:Tick(dt)
end

function MineDramaHandle:OnAssetLoaded(go)
    if Utils.IsNull(go) then return end

    self:PrepareAsset(go)
    self.stateMachine:ChangeState(DramaStateDefine.State.route)
end

function MineDramaHandle:OnAssetUnload()
    self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
    self.go = nil
    self.holder = nil
    self.targetActPos = nil
    self.targetActRot = nil
    self.targetIndex = nil
    self.storageIndex = nil
    self.counter = nil
    self.maxCount = nil
end

---@param go CS.UnityEngine.GameObject
function MineDramaHandle:PrepareAsset(go)
    local holder = go:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNull(holder) then
        g_Logger.ErrorChannel("MineDramaHandle", "家具表演所需的挂点脚本不存在")
        return
    end

    ---@type CS.FXAttachPointHolder
    self.holder = holder
    local storage = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.storage_act)

    local target1_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target1_act)
    local target2_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target2_act)
    local target3_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target3_act)
    local target4_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target4_act)

    ---@type CS.UnityEngine.Transform[]
    local targetActPoints = {}
    self:CheckAndAddPoint(targetActPoints, target1_act, target2_act, target3_act, target4_act, storage)

    if #targetActPoints < 2 or Utils.IsNull(storage) then
        g_Logger.ErrorChannel("MineDramaHandle", "家具表演所需的挂点未匹配")
        return
    end

    self.targetActPos = {}
    self.targetActRot = {}

    for i = 1, #targetActPoints do
        local targetActPoint = targetActPoints[i]
        self.targetActPos[i] = targetActPoint.position
        self.targetActRot[i] = targetActPoint.rotation
    end

    self.targetIndex = 1
    self.storageIndex = #targetActPoints
    self.counter = 0
    self.maxCount = 5
    self.go = go
end

function MineDramaHandle:GetIndex()
    if self:IsCountFull() then
        return self.storageIndex
    else
        return self.targetIndex
    end
end

function MineDramaHandle:CountPlus()
    self.counter = self.counter + 1

    if self:IsCountFull() then
        self.targetIndex = self.targetIndex + 1
        if self.targetIndex >= self.storageIndex then
            self.targetIndex = 1
        end
    end
    local res,scale = self:GetResModleAttachUnit()
    if string.IsNullOrEmpty(res) then return end
    self.petUnit:AttachModelTo(res, scale, self.counter - 1)
end

function MineDramaHandle:CountClear()
    self.counter = 0
    self.petUnit:ReleaseAllAttachedModel()
end

function MineDramaHandle:IsCountFull()
    return self.counter >= self.maxCount
end

function MineDramaHandle:GetTargetPosition()
    local index = self:GetIndex()
    return self.targetActPos[index], self.targetActRot[index]
end

function MineDramaHandle:IsResReady()
    return Utils.IsNotNull(self.go)
end

return MineDramaHandle