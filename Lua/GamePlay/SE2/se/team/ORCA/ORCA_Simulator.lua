---@class ORCA_Simulator
---@field new fun():ORCA_Simulator
local ORCA_Simulator = class("ORCA_Simulator")
local ORCA_HalfPlaneLine = require("ORCA_HalfPlaneLine")
local ORCA_Math = require("ORCA_Math")

function ORCA_Simulator:ctor(maxSpeed, timeHorizon)
    self._maxSpeed = maxSpeed
    self._timeHorizon = timeHorizon
end

---默认此处传入的agents彼此之间都是邻居
---@param agents ORCA_Agent[]|table<number, ORCA_Agent>
---@param dt number
---@param skipFunc fun(l:number, r:number):boolean
function ORCA_Simulator:CalculateNewVelocity(agents, dt, skipFunc)
    ---@type table<ORCA_Agent, boolean>
    local neighbourMap = {}
    for _, agent in pairs(agents) do
        neighbourMap[agent] = true
    end

    for _, agent in pairs(agents) do
        local lines = {}
        local newVelocity = agent._prefVelocity
        for neighbour, _ in pairs(neighbourMap) do
            if neighbour == agent then goto continue end
            if skipFunc and skipFunc(agent._id, neighbour._id) then goto continue end

            local relativePos = neighbour._position - agent._position
            local relativeVel = agent._prefVelocity - neighbour._prefVelocity
            local dist = relativePos.magnitude
            local combinedRadius = agent._radius + neighbour._radius

            local line = ORCA_HalfPlaneLine.new()
            local u

            --- 已碰撞
            if dist <= combinedRadius then
                local invTimeStep = 1 / dt
                local w = relativeVel - relativePos * invTimeStep
                local unitW = w.normalized
                local wLength = w.magnitude
                line.direction = CS.UnityEngine.Vector2(unitW.y, -unitW.x)
                u = (combinedRadius * invTimeStep - wLength) * unitW
            else
                local invTimeHorizon = 1 / self._timeHorizon
                local w = relativeVel - relativePos * invTimeHorizon
                local unitW = w.normalized
                local dotProduct1 = CS.UnityEngine.Vector2.Dot(unitW, relativePos)
                --- 相对速度落在cut-off区内，对cut-off圆做过圆心的垂线方向
                if dotProduct1 < 0 and math.abs(dotProduct1) > combinedRadius then
                    local wLength = w.magnitude
                    line.direction = CS.UnityEngine.Vector2(unitW.y, -unitW.x)
                    u = (combinedRadius * invTimeHorizon - wLength) * unitW
                else
                    --- 相对速度落在cut-off区外，需要取两圆公共切线的垂线
                    local leg = math.sqrt(dist * dist - combinedRadius * combinedRadius)
                    local cos = leg / dist
                    local sin = combinedRadius / dist

                    --- 取行列式计算有向面积判断应该向左腿还是右腿作垂线
                    if ORCA_Math.det(relativePos, w) > 0 then
                        line.direction = CS.UnityEngine.Vector2(relativePos.x * cos - relativePos.y * sin, relativePos.x * sin + relativePos.y * cos).normalized
                    else
                        line.direction = -CS.UnityEngine.Vector2(relativePos.x * cos + relativePos.y * sin, -relativePos.x * sin + relativePos.y * cos).normalized
                    end

                    local dotProduct2 = CS.UnityEngine.Vector2.Dot(relativeVel, line.direction)
                    u = dotProduct2 * line.direction - relativeVel
                end
            end

            line.point = agent._prefVelocity + u * 0.5
            table.insert(lines, line)
            ::continue::
        end

        local lineFail
        --- 处理线性规划最优解速度
        lineFail, newVelocity = self:LinearProgram2(lines, self._maxSpeed, agent._prefVelocity, false, agent._prefVelocity)
        if lineFail < #lines + 1 then
            --- 原始半剪裁平面将整个二维平面剪光了，改为取基于速度向量到各个半平面最长垂线值作为基准校正各个半平面的位置
            newVelocity = self:LinearProgram3(lines, 0, lineFail, self._maxSpeed, newVelocity)
        end

        agent:SetNewVelocity(newVelocity)
    end
end

---@param lines ORCA_HalfPlaneLine[]
function ORCA_Simulator:LinearProgram1(lines, lineNo, radius, optVelocity, directionOpt, lastResult)
    local dotProduct = CS.UnityEngine.Vector2.Dot(lines[lineNo].point, lines[lineNo].direction)
    local discrimant = dotProduct * dotProduct + radius * radius - lines[lineNo].point.sqrMagnitude
    if discrimant < 0 then
        return false, lastResult
    end

    local sqrtDiscrimant = discrimant ^ 0.5
    local tLeft = -dotProduct - sqrtDiscrimant
    local tRight = -dotProduct + sqrtDiscrimant

    for i = 1, lineNo do
        local denominator = ORCA_Math.det(lines[lineNo].direction, lines[i].direction)
        local numerator = ORCA_Math.det(lines[i].direction, lines[lineNo].point - lines[i].point)

        if math.abs(denominator) <= 0.0001 then
            if numerator < 0 then
                return false, lastResult
            else
                goto continue
            end
        end

        local t = numerator / denominator
        if denominator >= 0 then
            tRight = math.min(tRight, t)
        else
            tLeft = math.max(tLeft, t)
        end

        if tLeft > tRight then
            return false, lastResult
        end

        ::continue::
    end

    if directionOpt then
        if CS.UnityEngine.Vector2.Dot(optVelocity, lines[lineNo].direction) > 0 then
            lastResult = lines[lineNo].point + tRight * lines[lineNo].direction
        else
            lastResult = lines[lineNo].point + tLeft * lines[lineNo].direction
        end
    else
        local t = CS.UnityEngine.Vector2.Dot(lines[lineNo].direction, (optVelocity - lines[lineNo].point))

        if t < tLeft then
            lastResult = lines[lineNo].point + tLeft * lines[lineNo].direction
        elseif t > tRight then
            lastResult = lines[lineNo].point + tRight * lines[lineNo].direction
        else
            lastResult = lines[lineNo].point + t * lines[lineNo].direction
        end
    end

    return true, lastResult
end

---@param lines ORCA_HalfPlaneLine[]
function ORCA_Simulator:LinearProgram2(lines, radius, optVelocity, directionOpt, lastResult)
    if directionOpt then
        lastResult = optVelocity * radius
    elseif optVelocity.magnitude > radius then
        lastResult = optVelocity.normalized * radius
    else
        lastResult = optVelocity
    end

    local flag = false
    for i, line in ipairs(lines) do
        if ORCA_Math.det(line.direction, line.point - lastResult) > 0 then
            local tempResult = lastResult
            flag, lastResult = self:LinearProgram1(lines, i, radius, optVelocity, directionOpt, lastResult)
            if not flag then
                return i, tempResult
            end
        end
    end

    return #lines + 1, lastResult
end

---@param lines ORCA_HalfPlaneLine[]
function ORCA_Simulator:LinearProgram3(lines, numObstLines, beginLine, radius, lastResult)
    local distance = 0
    
    for i = beginLine, #lines do
        if ORCA_Math.det(lines[i].direction, lines[i].point - lastResult) > distance then
            local projLines = {}
            for j = 1, i - 1 do
                local line = ORCA_HalfPlaneLine.new()
                local determinant = ORCA_Math.det(lines[i].direction, lines[j].direction)
                if math.abs(determinant) <= 0.001 then
                    if CS.UnityEngine.Vector2.Dot(lines[i].direction, lines[j].direction) > 0 then
                        goto continue
                    else
                        line.point = 0.5 * (lines[i].point + lines[j].point)
                    end
                else
                    line.point = lines[i].point + ORCA_Math.det(lines[j].direction, lines[i].point - lines[j].point) / determinant * lines[i].direction
                end

                line.direction = (lines[j].direction - lines[i].direction).normalized
                table.insert(projLines, line)
                ::continue::
            end

            local tempResult = lastResult
            local lineFail, lastResult = self:LinearProgram2(projLines, radius, CS.UnityEngine.Vector2.zero, true, lastResult)
            if lineFail < #projLines then
                return tempResult
            end

            distance = ORCA_Math.det(lines[i].direction, lines[i].point - lastResult)
        end
    end

    return lastResult
end

return ORCA_Simulator