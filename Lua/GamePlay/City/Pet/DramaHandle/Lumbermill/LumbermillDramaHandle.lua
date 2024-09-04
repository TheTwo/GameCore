local DramaHandleBase = require("DramaHandleBase")
---@class LumbermillDramaHandle:DramaHandleBase
---@field new fun():LumbermillDramaHandle
local LumbermillDramaHandle = class("LumbermillDramaHandle", DramaHandleBase)
local StateMachine = require("StateMachine")
local LumbermillDramaStateRoute = require("LumbermillDramaStateRoute")
local LumbermillDramaStateWorking = require("LumbermillDramaStateWorking")
local LumbermillDramaStateMoving = require("LumbermillDramaStateMoving")
local LumbermillDramaStateStorage = require("LumbermillDramaStateStorage")
local LumbermillDramaStateAssetUnload = require("LumbermillDramaStateAssetUnload")
local Utils = require("Utils")
local DramaStateDefine = require("DramaStateDefine")
local HitAnimNameHash = CS.UnityEngine.Animator.StringToHash("hit")

---@param petUnit CityUnitPet
function LumbermillDramaHandle:ctor(petUnit)
    local furnitureId = petUnit.petData.furnitureId
    if furnitureId == 0 then
        g_Logger.ErrorChannel("LumbermillDramaHandle", "宠物数据异常")
        return
    end
    DramaHandleBase.ctor(self, petUnit, furnitureId)
    
    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState(DramaStateDefine.State.route, LumbermillDramaStateRoute.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.work, LumbermillDramaStateWorking.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.move, LumbermillDramaStateMoving.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.storage, LumbermillDramaStateStorage.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.assetunload, LumbermillDramaStateAssetUnload.new(self))
    
    self:Initialize()
end

function LumbermillDramaHandle:Start()
    DramaHandleBase.Start(self)

    if self:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

function LumbermillDramaHandle:End()
    if self.targets then
        for _, value in pairs(self.targets) do
            if Utils.IsNotNull(value) then
                value:SetVisible(true)
            end
        end
    end
    self.petUnit:ReleaseAllAttachedModel()
    DramaHandleBase.End(self)
end

function LumbermillDramaHandle:Tick(dt)
    self.stateMachine:Tick(dt)
    if self.revive == nil then return end
    if self.targets == nil then return end

    for i, v in ipairs(self.revive) do
        if v > 0 then
            v = v - dt
            if v <= 0 then
                if Utils.IsNotNull(self.targets[i]) then
                    self.targets[i]:SetVisible(true)
                end
                self.revive[i] = -1
            else
                self.revive[i] = v
            end
        end
    end
end

function LumbermillDramaHandle:OnAssetLoaded(go)
    if Utils.IsNull(go) then return end

    self:PrepareAsset(go)
    self.stateMachine:ChangeState(DramaStateDefine.State.route)
end

function LumbermillDramaHandle:OnAssetUnload()
    self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
    self.go = nil
    self.holder = nil
    self.targets = nil
    self.revive = nil
    self.targetActPos = nil
    self.targetActRot = nil
    self.targetIndex = nil
    self.storageIndex = nil
    self.counter = nil
    self.maxCount = nil
end

---@param go CS.UnityEngine.GameObject
function LumbermillDramaHandle:PrepareAsset(go)
    local holder = go:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNull(holder) then
        g_Logger.ErrorChannel("LumbermillDramaHandle", "家具表演所需的挂点脚本不存在")
        return
    end

    ---@type CS.FXAttachPointHolder
    self.holder = holder
    local target1 = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target1)
    local target2 = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target2)
    local target3 = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target3)
    local target4 = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target4)
    local storage = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.storage_act)

    local target1_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target1_act)
    local target2_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target2_act)
    local target3_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target3_act)
    local target4_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target4_act)

    ---@type CS.UnityEngine.Transform[]
    local targetPoints = {}
    self:CheckAndAddPoint(targetPoints, target1, target2, target3, target4)
    ---@type CS.UnityEngine.Transform[]
    local targetActPoints = {}
    self:CheckAndAddPoint(targetActPoints, target1_act, target2_act, target3_act, target4_act, storage)

    if #targetPoints < 1 or Utils.IsNull(storage) or #targetActPoints < 2 then
        g_Logger.ErrorChannel("LumbermillDramaHandle", "家具表演所需的挂点未匹配")
        return
    end

    ---@type CS.UnityEngine.Transform[]
    self.targets = {}
    self.revive = {}
    for i = 1, #targetPoints do
        local target = targetPoints[i]
        target:SetVisible(true)
        self.targets[i] = target
        self.revive[i] = -1
    end

    self.targetActPos = {}
    self.targetActRot = {}
    for i = 1, #targetActPoints do
        local targetAct = targetActPoints[i]
        self.targetActPos[i] = targetAct.position
        self.targetActRot[i] = targetAct.rotation
    end
    self.targetIndex = 1
    self.storageIndex = #targetActPoints
    self.counter = 0
    self.maxCount = 5
    self.go = go
end

function LumbermillDramaHandle:GetIndex()
    if self:IsCountFull() then
        return self.storageIndex
    else
        return self.targetIndex
    end
end

function LumbermillDramaHandle:CountPlus()
    self.counter = self.counter + 1

    if self:IsCountFull() then
        self.targets[self.targetIndex]:SetVisible(false)
        self.revive[self.targetIndex] = 5
        self.targetIndex = self.targetIndex + 1
        if self.targetIndex > #self.targets then
            self.targetIndex = 1
        end
    end
    local res,scale = self:GetResModleAttachUnit()
    if string.IsNullOrEmpty(res) then return end
    self.petUnit:AttachModelTo(res, scale, self.counter - 1)
end

function LumbermillDramaHandle:CountClear()
    self.counter = 0
    self.petUnit:ReleaseAllAttachedModel()
end

function LumbermillDramaHandle:IsCountFull()
    return self.counter >= self.maxCount
end

function LumbermillDramaHandle:GetTargetPosition()
    local index = self:GetIndex()
    return self.targetActPos[index], self.targetActRot[index]
end

function LumbermillDramaHandle:IsResReady()
    return Utils.IsNotNull(self.go)
end

function LumbermillDramaHandle:PlayTargetWoodHit()
    if not self.targets then return end
    if not self.targets[self.targetIndex] then return end
    if Utils.IsNull(self.targets[self.targetIndex]) then return end

    ---@type CS.UnityEngine.Animator
    local animator = self.targets[self.targetIndex]:GetComponent(typeof(CS.UnityEngine.Animator))
    if Utils.IsNull(animator) then return end
    animator:Play(HitAnimNameHash)
end

return LumbermillDramaHandle