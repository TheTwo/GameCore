local CityCitizenDefine = require("CityCitizenDefine")

local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateAssigned:CityCitizenState
---@field new fun():CityCitizenStateAssigned
---@field super CityCitizenState
local CityCitizenStateAssigned = class('CityCitizenStateAssigned', CityCitizenState)

function CityCitizenStateAssigned:Enter()
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = self
    end
    local v = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork)
    local runToHouse = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse)
    if self:HasWorkTask() then
        if self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetRecovered) then
            self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetRecovered, true)
            if self:IsCurrentWorkValid() then
                local targetInfo = self:GetTargetInfo()
                self._subStateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo, true)
                self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo, targetInfo)
            end
        end
        self._subStateMachine:ChangeState("CityCitizenStateSubWorkingLoop")
    else
        if v then
            self._subStateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork)
            self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork, true)
        end
        if runToHouse then
            self._subStateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse)
            self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse, true)
        end
        self._subStateMachine:ChangeState("CityCitizenStateSubNotWorking")
    end
    self:SyncInfectionVfx()
end

function CityCitizenStateAssigned:Tick(dt)
    if not self:IsAssigned() then
        self.stateMachine:ChangeState("CityCitizenStateNotAssigned")
        return
    end
    self._subStateMachine:Tick(dt)
end

function CityCitizenStateAssigned:Exit()
    self._subStateMachine:ChangeState("")
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = nil
    end
end

function CityCitizenStateAssigned:OnUnitAssetLoaded()
    local subState = self._subStateMachine:GetCurrentState()
    if subState and subState.OnUnitAssetLoaded then
        subState:OnUnitAssetLoaded()
    end
end

return CityCitizenStateAssigned

