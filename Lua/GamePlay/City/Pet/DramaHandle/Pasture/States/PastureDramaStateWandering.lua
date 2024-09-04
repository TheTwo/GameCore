local CityPetAnimStateDefine = require("CityPetAnimStateDefine")

local PastureDramaStateBase = require("PastureDramaStateBase")

---@class PastureDramaStateWandering:PastureDramaStateBase
---@field new fun(handle:PastureDramaHandle):PastureDramaStateWandering
---@field super PastureDramaStateBase
local PastureDramaStateWandering = class("PastureDramaStateWandering", PastureDramaStateBase)

function PastureDramaStateWandering:Enter()
    self._idleLeftTime = nil
    self._inMove = math.random() > 0.5
    self.handle.petUnit:StopMove()
    self.handle.petUnit:SyncAnimatorSpeed()
    self.handle.petUnit:SetFindPathMask(-1)
    self.handle:SetIgnoreStrictMovingSpeedUp(true)
    if self._inMove then
        self.handle.petUnit:PlayMove()
    else
        self._idleLeftTime = math.random() * 0.5
    end
end

function PastureDramaStateWandering:Exit()
    self.handle:SetIgnoreStrictMovingSpeedUp(false)
    self.handle.petUnit:StopMove()
    self.handle.petUnit:SetFindPathMask()
    self.handle.petUnit:SyncAnimatorSpeed()
end

function PastureDramaStateWandering:TickMove(dt)
    if self.handle.petUnit._moveAgent._isMoving or self.handle.petUnit:IsFindingPath() then
        return
    end
    self._inMove = false
    self.handle.petUnit:StopMove()
    self.handle.petUnit:SyncAnimatorSpeed()
    self.handle.petUnit:PlayLoopState(CityPetAnimStateDefine.Idle)
    self._idleLeftTime = math.random() * 0.5
end

function PastureDramaStateWandering:TickIdle(dt)
    if not self._idleLeftTime then
        self.handle.petUnit:PlayMove()
        self._inMove = true
        return
    end
    self._idleLeftTime = self._idleLeftTime - dt
    if self._idleLeftTime <= 0 then
        self._idleLeftTime = nil
    end
end

function PastureDramaStateWandering:Tick(dt)
    if self._inMove then
        self:TickMove(dt)
    else
        self:TickIdle(dt)
    end
end

return PastureDramaStateWandering