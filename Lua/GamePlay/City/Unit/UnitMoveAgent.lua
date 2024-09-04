---@type CS.UnityEngine.Vector3
local Vector3 = CS.UnityEngine.Vector3
---@type CS.UnityEngine.Quaternion
local Quaternion = CS.UnityEngine.Quaternion

---@class UnitMoveAgent
---@field new fun(unitId:number, unitMoveManager:UnitMoveManager):UnitMoveAgent
local UnitMoveAgent = class('UnitMoveAgent')
UnitMoveAgent.MoveEpsilon = 0.000001
UnitMoveAgent.DirEpsilon = 0.000001
UnitMoveAgent.emptyArray = {}

---@param unitId number
---@param unitMoveManager UnitMoveManager
function UnitMoveAgent:ctor(unitId, unitMoveManager)
    self._unitId = unitId
    self._mgr = unitMoveManager
    ---@type CS.UnityEngine.Vector3[]
    self._waypoints = {}
    self._currentWayPoint = 1

    self._isMoving = false
    self._speed = 0
    self._finalPos = Vector3.zero
    self._currentPosition = Vector3.zero
    self._currentDirection = Quaternion.identity
    self._currentDirectionNoPitch = Quaternion.identity
    self._isPause = false
    self._rotateSpeed = 300
    self._speedMutli = nil

    self.Dirty = false
end

---@param pos CS.UnityEngine.Vector3
---@param dir CS.UnityEngine.Quaternion
---@param moveSpeed number
function UnitMoveAgent:Init(pos, dir, moveSpeed)
    self._isMoving = false
    self._speed = moveSpeed
    self._finalPos = pos
    self._currentPosition = pos
    self._currentDirection = dir
    self._currentDirectionNoPitch = UnitMoveAgent.NoPitchDir(dir)
    self.Dirty = true

    self:ClearWayPoints()
end

function UnitMoveAgent:Release()
    self._isMoving = false
    self:ClearWayPoints()
end

-- Move

---@param pos CS.UnityEngine.Vector3
---@param dir CS.UnityEngine.Quaternion
function UnitMoveAgent:StopMove(pos, dir)
    self._isMoving = false
    if pos then
        self._finalPos = pos
        self._currentPosition = pos
    end
    if dir then
        self._currentDirection = dir
        self._currentDirectionNoPitch = UnitMoveAgent.NoPitchDir(dir)
    end
    self.Dirty = true
    self:ClearWayPoints()
end

---@param pos CS.UnityEngine.Vector3
function UnitMoveAgent:StopMoveTurnToPos(pos)
    self._isMoving = false
    if pos and self._currentPosition then
        local offset = pos - self._currentPosition
        if offset.sqrMagnitude > UnitMoveAgent.MoveEpsilon then
            self._currentDirection = Quaternion.LookRotation(offset.normalized)
            offset.y = 0
            self._currentDirectionNoPitch = Quaternion.LookRotation(offset.normalized)
            self.Dirty = true
        end
    end
    self:ClearWayPoints()
end

---@param dir CS.UnityEngine.Vector3
function UnitMoveAgent:StopMoveTurnToDir(dir)
    self._isMoving = false
    if dir and self._currentPosition then
        local offset = self._currentPosition + dir
        if offset.sqrMagnitude > UnitMoveAgent.MoveEpsilon then
            self._currentDirection = Quaternion.LookRotation(offset.normalized)
            offset.y = 0
            self._currentDirectionNoPitch = Quaternion.LookRotation(offset.normalized)
            self.Dirty = true
        end
    end
    self:ClearWayPoints()
end

---@param dir CS.UnityEngine.Quaternion
function UnitMoveAgent:StopMoveTurnToRotation(rotation)
    self._isMoving = false
    if rotation and self._currentPosition then
        self._currentDirection = rotation
        self._currentDirectionNoPitch = rotation
        self.Dirty = true
    end
    self:ClearWayPoints()
end

---@param wayPoints CS.UnityEngine.Vector3[]
function UnitMoveAgent:BeginMove(wayPoints)
    self._isMoving = false
    self._isNotMovingYet = true
    self:ClearWayPoints()
    local wayPointsCount = (wayPoints and #wayPoints) or 0
    if wayPointsCount > 0 then
        local p = wayPoints[1]
        local offset = Vector3(p.x - self._currentPosition.x, p.y - self._currentPosition.y, p.z - self._currentPosition.z)
        if offset.sqrMagnitude > UnitMoveAgent.DirEpsilon then
            self._currentDirection = Quaternion.LookRotation(offset.normalized)
            offset.y = 0
            if offset.sqrMagnitude > 0 then
                self._currentDirectionNoPitch = Quaternion.LookRotation(offset.normalized)
            end
        end
        for index = 1, wayPointsCount do
            table.insert(self._waypoints, wayPoints[index])
        end
        self._isMoving = true
    end
    self.Dirty = true
end

function UnitMoveAgent:PredictTime(wayPoints, speed)
    if (not wayPoints) or (#wayPoints <= 1) or (speed <= 0) then
        return nil
    end
    local totalTime = 0
    for index = 1, (#wayPoints - 1)  do
        local offset = wayPoints[index + 1] - wayPoints[index]
        totalTime = totalTime + (offset.magnitude / speed)
    end
    return totalTime
end

function UnitMoveAgent:Move(deltaTimeSec)
    if self._isPause then
        return
    end
    if not self._isMoving then
        return
    end
    self._isNotMovingYet = false
    local offset = Vector3.zero
    local speedMutli = (self._speedMutli or 1)
    local moveDistance = deltaTimeSec * self._speed * speedMutli
    local wayPointCount = #self._waypoints
    local direction
    local rotate = self._rotateSpeed * deltaTimeSec * speedMutli
    while moveDistance > UnitMoveAgent.MoveEpsilon do
        if wayPointCount < self._currentWayPoint then
            break
        end
        local wayEnd = self:GetCurrentWayEnd()
        ---@type CS.UnityEngine.Vector3
        local way = Vector3(wayEnd.x - self._currentPosition.x - offset.x, wayEnd.y - self._currentPosition.y - offset.y, wayEnd.z - self._currentPosition.z - offset.z)
        local wayLength = way.magnitude
        direction = way.normalized
        if wayLength < moveDistance then
            offset = Vector3(wayEnd.x - self._currentPosition.x, wayEnd.y - self._currentPosition.y, wayEnd.z - self._currentPosition.z)
            moveDistance = moveDistance - wayLength
            self._currentWayPoint = self._currentWayPoint + 1
        else
            offset = Vector3(offset.x + direction.x * moveDistance, offset.y + direction.y * moveDistance, offset.z + direction.z * moveDistance)
            break
        end
    end
    if direction then
        local tarRotation = Quaternion.LookRotation(direction)
        local angle = Quaternion.Angle(self._currentDirection, tarRotation)
        local interpolation = angle == 0 and 1 or math.clamp01(rotate / angle)
        self._currentDirection = Quaternion.Slerp(self._currentDirection, tarRotation, interpolation)
        direction.y = 0
        if direction.sqrMagnitude > 0 then
            self._currentDirectionNoPitch = Quaternion.Slerp(self._currentDirectionNoPitch, Quaternion.LookRotation(direction), interpolation)
        end
    end
    self._currentPosition = Vector3(self._currentPosition.x + offset.x, self._currentPosition.y + offset.y, self._currentPosition.z + offset.z)
    self.Dirty = true
    if wayPointCount < self._currentWayPoint then
        self:StopMove(self._currentPosition)
    end
end

---@param pos CS.UnityEngine.Vector3
---@param dir CS.UnityEngine.Quaternion
function UnitMoveAgent:ManualTickMove(pos, dir)
    if pos then
        self._currentPosition = pos
    end
    if dir then
        self._currentDirection = dir
        self._currentDirectionNoPitch = UnitMoveAgent.NoPitchDir(dir)
    end
    self.Dirty = true
end

-- WayPoints

function UnitMoveAgent:ClearWayPoints()
    table.clear(self._waypoints)
    self._currentWayPoint = 1
end

---@return CS.UnityEngine.Vector3
function UnitMoveAgent:GetNextWayEnd()
    local index = self._currentWayPoint + 1
    if (index < 1) or (index > #self._waypoints) then
        return self._currentPosition
    end
    return self._waypoints[index] 
end

---@return CS.UnityEngine.Vector3
function UnitMoveAgent:GetCurrentWayEnd()
    local index = self._currentWayPoint
    if (index < 1) or (index > #self._waypoints) then
        return self._currentPosition
    end
    return self._waypoints[index] 
end

---@return CS.UnityEngine.Vector3
function UnitMoveAgent:GetCurrentWayStart()
    local index = self._currentWayPoint - 1
    if (index < 1) or (index > #self._waypoints) then
        return self._currentPosition
    end
    return self._waypoints[index] 
end

---@param gridRange CityPathFindingGridRange
---@param cityPathFinding CityPathFinding
---@return boolean
function UnitMoveAgent:CheckSelfPathInRange(g, cityPathFinding)
    g.x, g.y = cityPathFinding:GridToWalkable(g.x, g.y)
    g.xMax, g.yMax = cityPathFinding:GridToWalkable(g.xMax, g.yMax)
    return cityPathFinding:IsRangeEffectsPath(g.x, g.y, g.xMax - g.x, g.yMax - g.y, self:GetLeftWayPoints())
end

function UnitMoveAgent:OffsetMoveAndWayPoints(newPosition)
    if not newPosition then
        return
    end
    if self._currentPosition then
        local offset = newPosition - self._currentPosition
        if self._waypoints and #self._waypoints > 0 then
            for k,v in pairs(self._waypoints) do
                self._waypoints[k] = v + offset
            end
        end
    end
    self._currentPosition = newPosition
    self.Dirty = true
end

function UnitMoveAgent:GetLeftWayPoints()
    if (not self._waypoints) or self._currentWayPoint > #self._waypoints then
        return UnitMoveAgent.emptyArray
    end
    local ret = {}
    table.insert(ret, self._currentPosition)
    for i = self._currentWayPoint, #self._waypoints do
        table.insert(ret, self._waypoints[i])
    end
    return ret
end

---@param mutli number|nil @ nil for restore default
function UnitMoveAgent:SetTempSpeedMutli(mutli)
    self._speedMutli = mutli
end

---@param dir CS.UnityEngine.Quaternion|nil
function UnitMoveAgent.NoPitchDir(dir)
    if not dir then
        return nil
    end 
    local e = dir.eulerAngles
    e.x = 0
    return CS.UnityEngine.Quaternion.Euler(e)
end

return UnitMoveAgent