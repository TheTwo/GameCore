local ORCA_Math = {}

---@param vector1 CS.UnityEngine.Vector2
---@param vector2 CS.UnityEngine.Vector2
function ORCA_Math.det(vector1, vector2)
    return vector1.x * vector2.y - vector1.y * vector2.x
end

return ORCA_Math