local NativeArrayVector3 = CS.Unity.Collections.NativeArray(CS.UnityEngine.Vector3)

---@class MapCreepLine
---@field new fun():MapCreepLine
---@field renderer CS.UnityEngine.LineRenderer
local MapCreepLine = class('MapCreepLine')

---@param linePosArray CS.UnityEngine.Vector3[]
function MapCreepLine:SetLineArray(linePosArray)
    local c = #linePosArray
    local array = NativeArrayVector3(c, CS.Unity.Collections.Allocator.Temp)
    for i, v in ipairs(linePosArray) do
        array[i - 1] = v
    end
    self.renderer.positionCount = c
    self.renderer:SetPositions(array)
    array:Dispose()
end

return MapCreepLine