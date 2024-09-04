local CityExplorerTeamDefine = require("CityExplorerTeamDefine")
local CityExplorerStateDefine = require("CityExplorerStateDefine")
---@type CS.UnityEngine.Quaternion
local Quaternion = CS.UnityEngine.Quaternion

local CityExplorerState = require("CityExplorerState")

---@class CityExplorerStateFollowLeaderPos:CityExplorerState
---@field new fun(explorer:CityUnitExplorer):CityExplorerStateFollowLeaderPos
---@field super CityExplorerState
local CityExplorerStateFollowLeaderPos = class('CityExplorerStateFollowLeaderPos', CityExplorerState)

function CityExplorerStateFollowLeaderPos:Enter()
    self._leader = self._explorer._leaderUnit
    self._index = self._explorer._teamIndex
    self._posOffSetLimit = 0.1
    self._runSpeed = self._explorer._config:RunSpeed()
    self._SpecialRunLimit = 5 * self._runSpeed
    self._explorer:ChangeAnimatorState(CityExplorerStateDefine.AnimatorState.run)
    self._explorer._moveAgent:StopMoveTurnToPos(nil)
end

function CityExplorerStateFollowLeaderPos:Tick(dt)
    local leaderAgent = self._leader._moveAgent
    local selfAgent = self._explorer._moveAgent
    local pos = selfAgent._currentPosition
    local leaderPos = leaderAgent._currentPosition
    local leaderDir = leaderAgent._currentDirection
    local targetPos = CityExplorerTeamDefine.CalculateTeamUnitPosition(leaderPos, leaderDir, self._index)
    local offset = targetPos - pos
    local distance = offset.magnitude
    local dtLength = self._runSpeed * dt
    if distance > self._posOffSetLimit then
        local runDir = offset.normalized
        if distance < dtLength then
            if not leaderAgent._isMoving then
                selfAgent:ManualTickMove(targetPos, leaderAgent._currentDirectionNoPitch)
                self.stateMachine:ChangeState("CityExplorerStateIdle")
            else
                selfAgent:ManualTickMove(targetPos, Quaternion.LookRotation(runDir))
            end
            return
        else
            if distance > self._SpecialRunLimit then
                targetPos = dtLength * 2 * runDir + pos
            else
                targetPos = dtLength * runDir + pos
            end
        end
        selfAgent:ManualTickMove(targetPos, Quaternion.LookRotation(runDir))
    else
        if not leaderAgent._isMoving then
            selfAgent:ManualTickMove(targetPos, leaderAgent._currentDirectionNoPitch)
            self.stateMachine:ChangeState("CityExplorerStateIdle")
        end
    end
end

return CityExplorerStateFollowLeaderPos

