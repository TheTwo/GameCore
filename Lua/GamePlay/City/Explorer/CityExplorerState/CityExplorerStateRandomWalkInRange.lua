local CityExplorerStateDefine = require("CityExplorerStateDefine")
local CityExplorerState = require("CityExplorerState")

---@class CityExplorerStateRandomWalkInRange:CityExplorerState
---@field new fun(explorer:CityUnitExplorer):CityExplorerStateRandomWalkInRange
---@field super CityExplorerState
local CityExplorerStateRandomWalkInRange = class('CityExplorerStateRandomWalkInRange', CityExplorerState)

function CityExplorerStateRandomWalkInRange:Enter()
    CityExplorerState.Enter(self)
    self._mask = self._explorer._pathFinder.AreaMask.CityGround
    self._range = self.stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetIdleWalkRange)
    self._randomWaitTime = nil
    self:CheckAndInitUnitPos()
    self._explorer:SetIsRunning(false)
    --self._explorer:SetSelectedShow(false)
    self:NextAction(true)
end

function CityExplorerStateRandomWalkInRange:Tick(dt)
    if self._randomWaitTime then
        self._randomWaitTime = self._randomWaitTime - dt
        if self._randomWaitTime < 0 then
            self._randomWaitTime = nil
        end
        return
    end
    if not self._explorer._hasTargetPos then
        self:NextAction(false)
    end
end

function CityExplorerStateRandomWalkInRange:NextAction(noWait)
    if (not noWait) and (math.random() > 0.5) then
        self._explorer._moveAgent:StopMove(self._explorer._moveAgent._currentPosition)
        self._randomWaitTime = math.random(1, 3)
        self._explorer:ChangeAnimatorState(CityExplorerStateDefine.AnimatorState.idle)
    else
        if self._range then
            local targetPos = self._explorer._pathFinder:RandomPositionInRange(self._range.x, self._range.y, self._range.sx, self._range.sy, self._mask)
            self._explorer:MoveToTargetPos(targetPos, false, false)
        else
            local targetPos = self._explorer._pathFinder:RandomPositionInExploredZoneWithInSafeArea(self._mask)
            self._explorer:MoveToTargetPos(targetPos, false, false)
        end
    end
end

function CityExplorerStateRandomWalkInRange:CheckAndInitUnitPos()
    if not self._explorer._moveAgent._currentPosition then
        local targetPos
        if self._range then
            targetPos = self._explorer._pathFinder:RandomPositionInRange(self._range.x, self._range.y, self._range.sx, self._range.sy, self._mask)
        else
            targetPos = self._explorer._pathFinder:RandomPositionInExploredZoneWithInSafeArea(self._mask)
        end
        self._explorer:WarpPos(targetPos, self._explorer.DefaultInitDir)
    end
end

return CityExplorerStateRandomWalkInRange

