
local StateMachine = require("StateMachine")
local DramaStateDefine = require("DramaStateDefine")
local Utils = require("Utils")

local DramaHandleBase = require("DramaHandleBase")

local CookDramaStateRoute = require("CookDramaStateRoute")
local CookDramaStateWorking = require("CookDramaStateWorking")
local CookDramaStateMoving = require("CookDramaStateMoving")
local CookDramaStateAssetUnload = require("CookDramaStateAssetUnload")

---@class CookDramaHandle:DramaHandleBase
---@field new fun(petUnit:CityUnitPet):CookDramaHandle
---@field super DramaHandleBase
local CookDramaHandle = class("CookDramaHandle", DramaHandleBase)

---@param petUnit CityUnitPet
function CookDramaHandle:ctor(petUnit)
    local furnitureId = petUnit.petData.furnitureId
    if furnitureId == 0 then
        g_Logger.ErrorChannel("CookDramaHandle", "宠物数据异常")
        return
    end
    DramaHandleBase.ctor(self, petUnit, furnitureId)

    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState(DramaStateDefine.State.route, CookDramaStateRoute.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.work, CookDramaStateWorking.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.move, CookDramaStateMoving.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.assetunload, CookDramaStateAssetUnload.new(self))

    self:Initialize()
end

function CookDramaHandle:Start()
    CookDramaHandle.super.Start(self)

    if self:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

function CookDramaHandle:End()
    self.petUnit:ReleaseAllAttachedModel()
    CookDramaHandle.super.End(self)
end

function CookDramaHandle:Tick(dt)
    self.stateMachine:Tick(dt)
end

function CookDramaHandle:OnAssetLoaded(go)
    if Utils.IsNull(go) then return end

    self:PrepareAsset(go)
    self.stateMachine:ChangeState(DramaStateDefine.State.route)
end

function CookDramaHandle:OnAssetUnload()
    self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
    self.go = nil
    self.holder = nil
    self.targetActPos = nil
    self.targetActRot = nil
    self.targetIndex = nil
end

---@param go CS.UnityEngine.GameObject
function CookDramaHandle:PrepareAsset(go)
    local holder = go:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNull(holder) then
        g_Logger.ErrorChannel("CookDramaHandle", "家具表演所需的挂点脚本不存在")
        return
    end

    ---@type CS.FXAttachPointHolder
    self.holder = holder

    local target1_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target1_act)

    if Utils.IsNull(target1_act) then
        g_Logger.ErrorChannel("CookDramaHandle", "家具表演所需的挂点未匹配")
        return
    end

    self.targetActPos = {
        target1_act.position,
    }
    self.targetActRot = {
        target1_act.rotation,
    }

    self.targetIndex = 1
    self.go = go
end

function CookDramaHandle:GetIndex()
    return self.targetIndex
end

function CookDramaHandle:GetTargetPosition()
    local index = self:GetIndex()
    return self.targetActPos[index], self.targetActRot[index]
end

function CookDramaHandle:IsResReady()
    return Utils.IsNotNull(self.go)
end

return CookDramaHandle