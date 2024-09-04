local DramaStateDefine = require("DramaStateDefine")

local MineDramaState = require("MineDramaState")

---@class MineDramaStateWorking:MineDramaState
---@field super MineDramaState
local MineDramaStateWorking = class("MineDramaStateWorking", MineDramaState)

function MineDramaStateWorking:Enter()
    self.handle.petUnit:PlayLoopState(self.handle:GetWorkCfgAnimName())
    self.handle.petUnit:SyncAnimatorSpeed()
    self.fakeEvtDelay = 2.5
end

function MineDramaStateWorking:Tick(dt)
    if self.fakeEvtDelay and self.fakeEvtDelay > 0 then
        self.fakeEvtDelay = self.fakeEvtDelay - dt
        if self.fakeEvtDelay <= 0 then
            if self.handle.petUnit:IsModelReady() then
                self:OnCounterEvent(self.handle.petUnit._animator:GetInstanceID())
            end
            self.fakeEvtDelay = 2.5
        end
    end
end

function MineDramaStateWorking:OnCounterEvent(animatorId)
    if self.handle.petUnit:IsModelReady() and animatorId == self.handle.petUnit._animator:GetInstanceID() then
        self.handle:CountPlus()
    end

    if self.handle:IsCountFull() then
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

return MineDramaStateWorking