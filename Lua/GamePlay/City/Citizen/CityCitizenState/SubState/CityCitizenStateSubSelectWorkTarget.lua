local CityCitizenDefine = require("CityCitizenDefine")
local CityCitizenStateHelper = require("CityCitizenStateHelper")

local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateSubSelectWorkTarget:CityCitizenState
---@field new fun(cityUnitCitizen:CityUnitCitizen):CityCitizenStateSubSelectWorkTarget
---@field super CityCitizenState
local CityCitizenStateSubSelectWorkTarget = class('CityCitizenStateSubSelectWorkTarget', CityCitizenState)

function CityCitizenStateSubSelectWorkTarget:Enter()
    self:SyncInfectionVfx()
    ---@type CityCitizenStateSubWorkingLoop|nil
    local cityCitizenStateSubWorkingLoopParent
    if self._parent and self._parent.SubSelectWorkTargetRegisterRedirectTarget then
        cityCitizenStateSubWorkingLoopParent = self._parent
        cityCitizenStateSubWorkingLoopParent:SubSelectWorkTargetRegisterRedirectTarget(nil)
    end
    if CityCitizenStateHelper.IsCurrentWorkValid(self._citizen._data) then
        local targetInfo = self:GetTargetInfo()
        local targetPos,redirectTarget
        targetPos,targetInfo,redirectTarget = CityCitizenStateHelper.GetWorkTargetPosByTargetInfo(targetInfo, self._citizen._data)
        if redirectTarget and cityCitizenStateSubWorkingLoopParent then
            cityCitizenStateSubWorkingLoopParent:SubSelectWorkTargetRegisterRedirectTarget(redirectTarget)
        end
        self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo, targetInfo)
        self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetPos, targetPos)
        self.stateMachine:ChangeState("CityCitizenStateSubGoToTarget")
    elseif self._parent and self._parent._parent and self._parent._parent.stateMachine then
        self._parent._parent.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.WaitSyncDelayTime, 5)
        self._parent._parent.stateMachine:ChangeState("CityCitizenStateWaitSync")
    end
end

return CityCitizenStateSubSelectWorkTarget