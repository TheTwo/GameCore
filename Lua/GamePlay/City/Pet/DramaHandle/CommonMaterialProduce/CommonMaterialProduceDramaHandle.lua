local StateMachine = require("StateMachine")
local DramaStateDefine = require("DramaStateDefine")
local Utils = require("Utils")

local DramaHandleBase = require("DramaHandleBase")

local CommonMaterialProduceState = require("CommonMaterialProduceState")
local CommonMaterialProduceStateRoute = require("CommonMaterialProduceStateRoute")
local CommonMaterialProduceStateWorking = require("CommonMaterialProduceStateWorking")
local CommonMaterialProduceStateMoving = require("CommonMaterialProduceStateMoving")
local CommonMaterialProduceStateAssetUnload = require("CommonMaterialProduceStateAssetUnload")

---@class CommonMaterialProduceDramaHandle:DramaHandleBase
---@field new fun(petUnit:CityUnitPet):CommonMaterialProduceDramaHandle
---@field super DramaHandleBase
local CommonMaterialProduceDramaHandle = class("CommonMaterialProduceDramaHandle", DramaHandleBase)

---@param petUnit CityUnitPet
function CommonMaterialProduceDramaHandle:ctor(petUnit)
    local furnitureId = petUnit.petData.furnitureId
    if furnitureId == 0 then
        g_Logger.ErrorChannel("CommonMaterialProduceDramaHandle", "宠物数据异常")
        return
    end
    DramaHandleBase.ctor(self, petUnit, furnitureId)

    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState(DramaStateDefine.State.route, CommonMaterialProduceStateRoute.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.work, CommonMaterialProduceStateWorking.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.move, CommonMaterialProduceStateMoving.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.assetunload, CommonMaterialProduceStateAssetUnload.new(self))

    self:Initialize()
end

function CommonMaterialProduceDramaHandle:Start()
    CommonMaterialProduceDramaHandle.super.Start(self)

    if self:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

function CommonMaterialProduceDramaHandle:End()
    self.petUnit:ReleaseAllAttachedModel()
    CommonMaterialProduceDramaHandle.super.End(self)
end

function CommonMaterialProduceDramaHandle:Tick(dt)
    self.stateMachine:Tick(dt)
end

function CommonMaterialProduceDramaHandle:OnAssetLoaded(go)
    if Utils.IsNull(go) then return end

    self:PrepareAsset(go)
    self.stateMachine:ChangeState(DramaStateDefine.State.route)
end

function CommonMaterialProduceDramaHandle:OnAssetUnload()
    self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
    self.go = nil
    self.holder = nil
    self.targetActPos = nil
    self.targetActRot = nil
    self.targetIndex = nil
end

---@param go CS.UnityEngine.GameObject
function CommonMaterialProduceDramaHandle:PrepareAsset(go)
    local holder = go:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNull(holder) then
        g_Logger.ErrorChannel("CommonMaterialProduceDramaHandle", "家具表演所需的挂点脚本不存在")
        return
    end

    ---@type CS.FXAttachPointHolder
    self.holder = holder

    local target1_act = self.holder:GetAttachPoint(DramaStateDefine.TargetKey.target1_act)

    if Utils.IsNull(target1_act) then
        g_Logger.ErrorChannel("CommonMaterialProduceDramaHandle", "家具表演所需的挂点未匹配")
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

function CommonMaterialProduceDramaHandle:GetIndex()
    return self.targetIndex
end

function CommonMaterialProduceDramaHandle:GetTargetPosition()
    local index = self:GetIndex()
    return self.targetActPos[index], self.targetActRot[index]
end

function CommonMaterialProduceDramaHandle:IsResReady()
    return Utils.IsNotNull(self.go)
end

return CommonMaterialProduceDramaHandle