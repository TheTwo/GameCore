local CityCitizenDefine = require("CityCitizenDefine")
local CityCitizenState = require("CityCitizenState")


---@class CityCitizenStateSubRandomWait:CityCitizenState
---@field new fun(cityUnitCitizen:CityUnitCitizen):CityCitizenStateSubRandomWait
---@field super CityCitizenState
local CityCitizenStateSubRandomWait = class('CityCitizenStateSubRandomWait', CityCitizenState)

function CityCitizenStateSubRandomWait:Enter()
    local exitFromWork = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork)
    local assignHouse = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse)
    local _ = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetNeedForceRun)
    if exitFromWork or assignHouse then
        self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetNeedForceRun, false)
        self.stateMachine:ChangeState("CityCitizenStateSubRandomTarget")
        return
    end
    local wait = math.random() > 0.5
    if not wait then
        self.stateMachine:ChangeState("CityCitizenStateSubRandomTarget")
        return
    end
    self._citizen:StopMove()
    self._citizen:ChangeAnimatorState(CityCitizenDefine.AniClip.Idle)
    self._waitTime = 1 + math.random() * 2.5
end

function CityCitizenStateSubRandomWait:Tick(dt)
    if (not self._waitTime) or self._waitTime <= 0 then
        self.stateMachine:ChangeState("CityCitizenStateSubRandomTarget")
        return
    end
    self._waitTime = self._waitTime - dt
end

function CityCitizenStateSubRandomWait:Exit()
    self._waitTime = nil
end

---@param gridRange CityPathFindingGridRange
function CityCitizenStateSubRandomWait:OnWalkableChangedCheck(gridRange)
    if gridRange.buildingId and self._citizen._data._houseId == gridRange.buildingId then
        if self._citizen:CheckSelfPosition(gridRange.oldRange) then
            self._citizen:OffsetMoveAndWayPoints(self._citizen._moveAgent._currentPosition + gridRange.offset)
        end
    end
    if self._citizen:CheckSelfPosition(gridRange) then
        self._waitTime = nil
    end
end

return CityCitizenStateSubRandomWait

