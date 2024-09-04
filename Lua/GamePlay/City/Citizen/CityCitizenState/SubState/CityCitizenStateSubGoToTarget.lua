local Delegate = require("Delegate")
local CityCitizenDefine = require("CityCitizenDefine")
local CityWorkType = require("CityWorkType")

local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateSubGoToTarget:CityCitizenState
---@field new fun(cityUnitCitizen:CityUnitCitizen):CityCitizenStateSubGoToTarget
---@field super CityCitizenState
local CityCitizenStateSubGoToTarget = class('CityCitizenStateSubGoToTarget', CityCitizenState)

function CityCitizenStateSubGoToTarget:Enter()
    local forceRun = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetNeedForceRun)
    self._enterWithWork = self:HasWorkTask()
    self._targetInfo = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo)
    local targetPosKey = CityCitizenDefine.StateMachineKey.TargetPos
    local targetPos = self.stateMachine:ReadBlackboard(targetPosKey)
    if not targetPos then
        if self._enterWithWork then
            self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo, self._targetInfo)
            self.stateMachine:ChangeState("CityCitizenStateSubInteractTarget")
        else
            self.stateMachine:ChangeState("CityCitizenStateSubRandomWait")
        end
        return
    end
    local useRun = forceRun or self:HasWorkTask()
    self._citizen:SetIsRunning(useRun)
    self._citizen:MoveToTargetPos(targetPos, useRun, Delegate.GetOrCreate(self, self.OnPathReady))
    self._hasGoToTip = false
    if self:HasWorkTask() then
        self._citizen:RequestGoToBubbleTip()
        self._hasGoToTip = true
    end
end

function CityCitizenStateSubGoToTarget:Tick(dt)
    if not self._citizen._hasTargetPos then
        if self:HasWorkTask() then
            self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo, self._targetInfo)
            self.stateMachine:ChangeState("CityCitizenStateSubInteractTarget")
        else
            if self._enterWithWork then
                self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork)
                self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork, true)
            end
            self.stateMachine:ChangeState("CityCitizenStateSubRandomWait")
        end
    end
end

---@param gridRange CityPathFindingGridRange
function CityCitizenStateSubGoToTarget:OnWalkableChangedCheck(gridRange)
    if not self:HasWorkTask() then
        if gridRange.buildingId and self._citizen:CheckSelfPathInRange(gridRange.oldRange) then
            self._citizen:OffsetMoveAndWayPoints(self._citizen._moveAgent._currentPosition +  gridRange.offset)
            return
        end
        if self._citizen:CheckSelfPathInRange(gridRange) then
            self.stateMachine:ChangeState("CityCitizenStateSubRandomTarget")
        end
    end
end

---@param path CS.UnityEngine.Vector3[]
---@param agent UnitMoveAgent
function CityCitizenStateSubGoToTarget:OnPathReady(path, agent)
    self._path = {}
    for i, v in ipairs(path) do
        self._path[i] = v
    end
end

function CityCitizenStateSubGoToTarget:Exit()
    if self._hasGoToTip then
        self._hasGoToTip = false
        self._citizen:ReleaseBubbleTip()
    end
    self._path = nil
    self._citizen:RemovePathLine()
end

function CityCitizenStateSubGoToTarget:OnWorkTargetChanged(targetId, targetType)
    if self._targetInfo and self._targetInfo.id == targetId and self._targetInfo.type == targetType then
        local targetPos = self._citizen._data:GetPositionById(targetId, targetType)
        self._citizen:MoveToTargetPos(targetPos, self:HasWorkTask(), Delegate.GetOrCreate(self, self.OnPathReady))
    end
end

function CityCitizenStateSubGoToTarget:OnDrawGizmos()
    if not self._path or #self._path < 2 then
        return
    end
    ---@type CS.UnityEngine.Gizmos
    local Gizmos = CS.UnityEngine.Gizmos
    Gizmos.color = CS.UnityEngine.Color.white
    local last = self._path[1]
    for i = 2, #self._path do
        local p = self._path[i]
        Gizmos.DrawLine(last, p)
        last = p
    end
end

return CityCitizenStateSubGoToTarget