---@class Vector3Calculation
local Vector3Calculation = class("Vector3Calculation")

function Vector3Calculation.Add(x1, y1, z1, x2, y2, z2)
    return x1 + x2, y1 + y2, z1 + z2
end

function Vector3Calculation.Subtract(x1, y1, z1, x2, y2, z2)
    return x1 - x2, y1 - y2, z1 - z2
end

function Vector3Calculation.SqrDist(x1, y1, z1, x2, y2, z2)
    return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2) + (z1 - z2) * (z1 - z2)
end

function Vector3Calculation.Dist(x1, y1, z1, x2, y2, z2)
    local sqrDist = Vector3Calculation.SqrDist(x1, y1, z1, x2, y2, z2)
    return math.sqrt(sqrDist)
end

function Vector3Calculation.SqrDist2D(x1, y1, x2, y2)
    return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
end

function Vector3Calculation.Dist2D(x1, y1, x2, y2)
    local sqrDist = Vector3Calculation.SqrDist2D(x1, y1, x2, y2)
    return math.sqrt(sqrDist)
end

function Vector3Calculation.Dot(x1, y1, z1, x2, y2, z2)
    return x1 * x2 + y1 * y2 + z1 * z2
end

function Vector3Calculation.LengthSquared(x1, y1, z1)
    return Vector3Calculation.Dot(x1, y1, z1, x1, y1, z1)
end

function Vector3Calculation.Length(x1, y1, z1)
    local lengthSquared = Vector3Calculation.LengthSquared(x1, y1, z1)
    return math.sqrt(lengthSquared)
end

function Vector3Calculation.Normalize(x1, y1, z1)
    local length = Vector3Calculation.Length(x1, y1, z1)
    if length > 0 then
        return x1 / length, y1 / length, z1 / length
    end
    return 0, 0, 0
end

return Vector3Calculation