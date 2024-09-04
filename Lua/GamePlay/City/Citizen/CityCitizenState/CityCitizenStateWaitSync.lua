local CityCitizenState = require("CityCitizenState")
local CityCitizenDefine = require("CityCitizenDefine")

---@class CityCitizenStateWaitSync:CityCitizenState
---@field new fun():CityCitizenStateWaitSync
---@field super CityCitizenState
local CityCitizenStateWaitSync = class('CityCitizenStateWaitSync', CityCitizenState)

function CityCitizenStateWaitSync:Enter()
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = self
    end
    self._citizen:StopMove()
    self._citizen:ChangeAnimatorState(CityCitizenDefine.AniClip.Idle)
    self._delayCheck = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.WaitSyncDelayTime, nil)
end

function CityCitizenStateWaitSync:Tick(dt)
    if self._delayCheck and self._delayCheck > 0 then
        self._delayCheck = self._delayCheck - dt
        if self._delayCheck <= 0 then
            self._delayCheck = nil
            if self:IsFainting() then
                self.stateMachine:ChangeState("CityCitizenStateFainting")
            elseif not self:HasWorkTask() then
                if self:IsAssigned() then
                    self.stateMachine:ChangeState("CityCitizenStateNotAssigned")
                else
                    self.stateMachine:ChangeState("CityCitizenStateAssigned")
                end
            else
                self.stateMachine:ChangeState("CityCitizenStateSyncFromServerData")
            end
        end
    end
end

function CityCitizenStateWaitSync:Exit()
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = nil
    end
end

return CityCitizenStateWaitSync

