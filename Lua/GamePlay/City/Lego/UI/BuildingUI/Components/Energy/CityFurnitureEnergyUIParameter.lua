---@class CityFurnitureEnergyUIParameter
---@field new fun():CityFurnitureEnergyUIParameter
local CityFurnitureEnergyUIParameter = class("CityFurnitureEnergyUIParameter")

---@param cellTile CityFurnitureTile
function CityFurnitureEnergyUIParameter:ctor(cellTile)
    self.configId = cellTile:GetCell():ConfigId()
    self.furnitureId = cellTile:GetCell():UniqueId()
end

return CityFurnitureEnergyUIParameter