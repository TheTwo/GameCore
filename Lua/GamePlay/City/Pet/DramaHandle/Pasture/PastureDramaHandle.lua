local StateMachine = require("StateMachine")
local Utils = require("Utils")
local DramaStateDefine = require("DramaStateDefine")

local PastureDramaStateRoute = require("PastureDramaStateRoute")
local PastureDramaStateWandering = require("PastureDramaStateWandering")
local PastureDramaStateAssetUnload = require("PastureDramaStateAssetUnload")

local DramaHandleBase = require("DramaHandleBase")

---@class PastureDramaHandle:DramaHandleBase
---@field new fun(petUnit:CityUnitPet):PastureDramaHandle
---@field super DramaHandleBase
local PastureDramaHandle = class("PastureDramaHandle", DramaHandleBase)

---@param petUnit CityUnitPet
function PastureDramaHandle:ctor(petUnit)
    local furnitureId = petUnit.petData.furnitureId
    if furnitureId == 0 then
        g_Logger.ErrorChannel("LumbermillDramaHandle", "宠物数据异常")
        return
    end
    PastureDramaHandle.super.ctor(self, petUnit, furnitureId)

    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState(DramaStateDefine.State.route, PastureDramaStateRoute.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.wandering, PastureDramaStateWandering.new(self))
    self.stateMachine:AddState(DramaStateDefine.State.assetunload, PastureDramaStateAssetUnload.new(self))

    self:Initialize()
end

function PastureDramaHandle:Start()
    PastureDramaHandle.super.Start(self)

    if self:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

function PastureDramaHandle:Tick(dt)
    self.stateMachine:Tick(dt)
end

function PastureDramaHandle:End()
    self.petUnit:ReleaseAllAttachedModel()
    PastureDramaHandle.super.End(self)
end

function PastureDramaHandle:OnAssetLoaded(go)
    self:PrepareAsset(go)
    if self:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

function PastureDramaHandle:OnAssetUnload()
    self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
    self.go = nil
end

function PastureDramaHandle:IsResReady()
    return Utils.IsNotNull(self.go)
end

---@param go CS.UnityEngine.GameObject
function PastureDramaHandle:PrepareAsset(go)
    self.go = go
end

---@return CS.UnityEngine.Vector3|nil
function PastureDramaHandle:GetTargetPosition()
    local petData = self.petUnit.petData
    local city = petData.manager.city
    local funritureMgr = city.furnitureManager
    local f = funritureMgr:GetFurnitureById(self.furnitureId)
    local p = city.cityPathFinding
    return p:RandomPositionInRange(f.x, f.y, f.sizeX, f.sizeY, -1), nil
end

function PastureDramaHandle:HasSuggestMoveRemainTime(runTime, walkTime, targetPos, runSpeed, walkSpeed)
    if not self.ignoreStrictMovingSpeedUp then return false, runTime end
    return true, walkTime * 4.0
end

return PastureDramaHandle