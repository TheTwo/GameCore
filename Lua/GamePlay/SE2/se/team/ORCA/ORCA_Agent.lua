---@class ORCA_Agent
---@field new fun():ORCA_Agent
local ORCA_Agent = class("ORCA_Agent")

---@param id number
---@param radius number
---@param position CS.UnityEngine.Vector2
---@param prefVelocity CS.UnityEngine.Vector2
function ORCA_Agent:ctor(id, radius, position, prefVelocity)
    self._id = id
    self._radius = radius
    self._position = position
    self._prefVelocity = prefVelocity
end

---@param position CS.UnityEngine.Vector2
function ORCA_Agent:UpdatePosition(position)
    self._position = position
end

---@param prefVelocity CS.UnityEngine.Vector2
function ORCA_Agent:UpdatePrefVelocity(prefVelocity)
    self._prefVelocity = prefVelocity
end

---@param newVelocity CS.UnityEngine.Vector2
function ORCA_Agent:SetNewVelocity(newVelocity)
    self._newVelocity = newVelocity
end

function ORCA_Agent:MarkAlive()
    self._dirty = true
end

return ORCA_Agent