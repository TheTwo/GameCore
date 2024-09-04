---@class CityPathFindingUtils
local CityPathFindingUtils = {}

---@param wayPoints CS.UnityEngine.Vector3[]
---@return number
function CityPathFindingUtils.GetWayPointsTotalDistance(wayPoints)
    local count = #wayPoints
    if count < 2 then
        return 0.0
    end
    local ret = 0.0
    local lastPos = wayPoints[1]
    for i = 2, count do
        local currentPos = wayPoints[i]
        ret = ret + (currentPos - lastPos).magnitude
        lastPos = currentPos
    end
    return ret
end

---@param percent number @[0,1]
---@param wayPoints CS.UnityEngine.Vector3[]
---@return CS.UnityEngine.Vector3[]
function CityPathFindingUtils.PassPercentWayPoints(percent, wayPoints)
    local ret = {}
    local count = #wayPoints
    if count < 2 then
        return ret
    end
    if percent <= 0.0001 then
        table.insertto(ret, wayPoints, 1)
        return ret
    end
    --elseif percent >= 0.9999 then
    --    return ret
    --end
    local totalDistance = CityPathFindingUtils.GetWayPointsTotalDistance(wayPoints)
    local passDistance = percent * totalDistance
    local lastPos = wayPoints[1]
    local addPass = false
    for i = 2, count do
        local currentPos = wayPoints[i]
        if addPass then
            table.insert(ret, currentPos)
        else
            local offset = (lastPos - currentPos)
            local currentDistance = offset.magnitude
            if currentDistance < passDistance then
                passDistance = passDistance - currentDistance
            else
                local d = currentPos + offset.normalized * (currentDistance - passDistance)
                table.insert(ret, d)
                table.insert(ret, currentPos)
                addPass = true
            end
            lastPos = currentPos
        end
    end
    return ret
end

---@param speed number @float
---@param wayPoints CS.UnityEngine.Vector3[]
---@return number @seconds
function CityPathFindingUtils.PreCalculateWayTime(speed, wayPoints)
    if speed <= 0 then
        return 0
    end
    local distance = CityPathFindingUtils.GetWayPointsTotalDistance(wayPoints)
    return distance * 1.0 / speed
end

return CityPathFindingUtils

