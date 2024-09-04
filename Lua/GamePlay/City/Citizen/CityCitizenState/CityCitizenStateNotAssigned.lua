local CityCitizenDefine = require("CityCitizenDefine")
local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateNotAssigned:CityCitizenState
---@field new fun():CityCitizenStateNotAssigned
---@field super CityCitizenState
local CityCitizenStateNotAssigned = class('CityCitizenStateNotAssigned', CityCitizenState)

function CityCitizenStateNotAssigned:Enter()
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = self
    end
    self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork)
    self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse)
    if self:HasWorkTask() then
        if self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetRecovered) then
            self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetRecovered, true)
        end
        if self:IsCurrentWorkValid() then
            local targetInfo = self:GetTargetInfo()
            self._subStateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo, true)
            self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo, targetInfo)
        end
        self._subStateMachine:ChangeState("CityCitizenStateSubWorkingLoop")
    else
        self._subStateMachine:ChangeState("CityCitizenStateSubNotWorking")
    end
    self:SyncInfectionVfx()
end

function CityCitizenStateNotAssigned:Tick(dt)
    if self:IsAssigned() then
        self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse, true)
        self.stateMachine:ChangeState("CityCitizenStateAssigned")
        return
    end
    self._subStateMachine:Tick(dt)
end

function CityCitizenStateNotAssigned:Exit()
    self._subStateMachine:ChangeState("")
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = nil
    end
end

function CityCitizenStateNotAssigned:OnUnitAssetLoaded()
    local subState = self._subStateMachine:GetCurrentState()
    if subState and subState.OnUnitAssetLoaded then
        subState:OnUnitAssetLoaded()
    end
end

return CityCitizenStateNotAssigned

