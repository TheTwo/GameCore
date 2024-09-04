---@class CityFurniturePlaceUIParameter
---@field new fun(city):CityFurniturePlaceUIParameter
local CityFurniturePlaceUIParameter = class("CityFurniturePlaceUIParameter")

---@param city City
---@param focusFurnitureTypCfgId number @CityFurnitureTypesConfigCell
---@param showPlaced boolean
function CityFurniturePlaceUIParameter:ctor(city, focusFurnitureTypCfgId, showPlaced)
    self.city = city
    self.focusFurnitureTypCfgId = focusFurnitureTypCfgId
    self.showPlaced = showPlaced or false
end

return CityFurniturePlaceUIParameter