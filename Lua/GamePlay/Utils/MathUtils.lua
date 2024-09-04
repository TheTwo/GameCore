local MathUtils = {}
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3

function MathUtils.Dampen(velocity, damping, strength, dt)
    local time_per_frame = 1 / 60
    local loop = math.max(1, math.round(dt / time_per_frame))
    local offset = 0
    local tail = dt - time_per_frame * loop

    for i = 1, loop do
        offset = offset + velocity * time_per_frame
        velocity = math.clamp01(damping ^ (strength * time_per_frame)) * velocity
    end

    if tail > 0 then
        offset = offset + velocity * tail
        velocity = math.clamp01(damping ^ (strength * tail)) * velocity
    end

    return offset, velocity
end

---计算距离
---@param pos CS.UnityEngine.Vector3
---@param targetPos CS.UnityEngine.Vector3
function MathUtils.Distance(v1, v2)
    local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    local dz = v1.z - v2.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- 贝塞尔曲线
-- 二阶 a,b为起点终点
function MathUtils.Bezier2(a, b, t)
    return Vector3.Lerp(a, b, t)
end

-- 三阶 a,c为起点终点，b为控制点
function MathUtils.Bezier3(a, b, c, t)
    return Vector3.Lerp(MathUtils.Bezier2(a, b, t), MathUtils.Bezier2(b, c, t), t)
end

-- 四阶 a,d为起点终点，b,c为控制点
function MathUtils.Bezier4(a, b, c, d, t)
    return Vector3.Lerp(MathUtils.Bezier3(a, b, c, t), MathUtils.Bezier3(b, c, d, t), t)
end

-- 抛物线
function MathUtils.Paracurve(trans, startPos, endPos, pivot, height, resolution, duration, ease)
    -- 不定义锚点时，默认抛物线为拱形
    if pivot == nil then
        pivot = Vector3.up
    end
    local bezierControlPoint = 0.5 * (startPos + endPos) + (pivot * height)
    local path = {}
    for i = 1, resolution do
        local t = i / resolution
        path[i] = MathUtils.Bezier3(startPos, bezierControlPoint, endPos, t)
    end

    if (ease) then
        trans:DOPath(path, duration):SetEase(ease)
    else
        trans:DOPath(path, duration):SetEase(CS.DG.Tweening.Ease.InOutQuad)
    end
end

return MathUtils;
