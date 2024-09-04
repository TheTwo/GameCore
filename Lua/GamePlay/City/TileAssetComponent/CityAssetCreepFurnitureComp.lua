---@class CityAssetCreepFurnitureComp
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field new fun():CityAssetCreepFurnitureComp
---@field active CS.UnityEngine.GameObject[]
---@field inactive CS.UnityEngine.GameObject[]
local CityAssetCreepFurnitureComp = class("CityAssetCreepFurnitureComp")

---@param one number @0是显示没药, 1显示有药, 其他不显示任何物体
---@param two number @0是显示没药, 1显示有药, 其他不显示任何物体
---@param three number @0是显示没药, 1显示有药, 其他不显示任何物体
function CityAssetCreepFurnitureComp:ShowUnitState(one, two, three)
    self.active[0]:SetActive(one == 1)
    self.inactive[0]:SetActive(one == 0)
    self.active[1]:SetActive(two == 1)
    self.inactive[1]:SetActive(two == 0)
    self.active[2]:SetActive(three == 1)
    self.inactive[2]:SetActive(three == 0)
end

return CityAssetCreepFurnitureComp