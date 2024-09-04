
---@class CitySeMapInfo
local CitySeMapInfo = sealedClass("CitySeMapInfo")

function CitySeMapInfo:ctor()
    ---@type City
    self._city = nil
end

---@param city City
function CitySeMapInfo:SetCity(city)
    self._city = city
end

---@param serverPos CS.UnityEngine.Vector3
---@return CS.UnityEngine.Vector3
function CitySeMapInfo:ServerPos2Client(serverPos)
    local pos = self._city:GetWorldPositionFromCoord(serverPos.x, serverPos.y)
    return pos
end

---@param clientPos CS.UnityEngine.Vector3
---@return CS.UnityEngine.Vector3
function CitySeMapInfo:ClientPos2Server(clientPos)
    local x, z = self._city:GetCoordFromPosition(clientPos, true)
    return CS.UnityEngine.Vector3(x, z, 0)
end

return CitySeMapInfo