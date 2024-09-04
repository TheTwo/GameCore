local Spherical = {}
local Quaternion = CS.UnityEngine.Quaternion

---@param radius number 半径
---@param azimuth number @"经度[0, 360)"
---@param altitude number @"纬度(0, 180)"
function Spherical.Position(radius, azimuth, altitude)
    local sinAngleXZ = math.sin(math.rad(altitude))
    local cosAngleXZ = math.cos(math.rad(altitude))
    local sinAngleY = math.sin(math.rad(azimuth))
    local cosAngleY = math.cos(math.rad(azimuth))

    local x = cosAngleXZ * radius * sinAngleY
    local y = sinAngleXZ * radius
    local z = cosAngleXZ * radius * cosAngleY

    return x, y, z
end

function Spherical.Rotation(azimuth, altitude)
    return Quaternion.Euler(180 - altitude, azimuth, 0)
end

function Spherical.Radius(y, altitude)
    local sinAngleXZ = math.sin(math.rad(altitude))
    return y / sinAngleXZ
end

return Spherical