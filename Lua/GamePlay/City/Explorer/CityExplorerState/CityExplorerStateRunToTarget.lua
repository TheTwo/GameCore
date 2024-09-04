local CityExplorerState = require("CityExplorerState")
local CityExplorerStateDefine = require("CityExplorerStateDefine")

---@class CityExplorerStateRunToTarget:CityExplorerState
---@field new fun(actor:CityUnitExplorer):CityExplorerStateRunToTarget
---@field super CityExplorerState
local CityExplorerStateRunToTarget = class('CityExplorerStateRunToTarget', CityExplorerState)

function CityExplorerStateRunToTarget:Enter()
    self._explorer:SetIsRunning(true)
    --self._explorer:SetSelectedShow(true)
    local targetRadius = self.stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetRadius, true)
    self._targetRadiusSqr = targetRadius * targetRadius
    self._targetWayPoints = self.stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetWayPoints, true)
    self._targetIsGround = self.stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetIsGround, true)
    self._targetPos = self._targetWayPoints[#self._targetWayPoints]
    self._explorer:MoveUseWaypoints(self._targetWayPoints, true, self._explorer._isLeader)
    self._targetArrived = false
end

function CityExplorerStateRunToTarget:Tick(dt)
    CityExplorerState.Tick(self, dt)
    if self._targetArrived then
        return
    end
    if self._targetIsGround then
        if not self._explorer._moveAgent._isMoving and not self._explorer._moveAgent._isNotMovingYet then
            self._targetArrived = true
            self._explorer._moveAgent:StopMoveTurnToPos(self._targetPos)
        end
    else
        local distance = (self._explorer._moveAgent._currentPosition - self._targetPos).sqrMagnitude
        if distance < self._targetRadiusSqr then
            self._targetArrived = true
            self._explorer._moveAgent:StopMoveTurnToPos(self._targetPos)
        end
    end
end

function CityExplorerStateRunToTarget:Exit()
    self._explorer:ChangeAnimatorState(CityExplorerStateDefine.AnimatorState.idle)
    self._explorer:SetIsRunning(false)
    self._explorer:RemovePathLine()
end

return CityExplorerStateRunToTarget