local ConfigRefer = require("ConfigRefer")

---@class CityFurnitureCatchPetUIParameter
---@field new fun():CityFurnitureCatchPetUIParameter
local CityFurnitureCatchPetUIParameter = class("CityFurnitureCatchPetUIParameter")

---@param cellTile CityFurnitureTile
function CityFurnitureCatchPetUIParameter:ctor(cellTile)
    self.cellTile = cellTile
    self.furnitureId = cellTile:GetCell():UniqueId()
    self.furnitureLevelCfgId = cellTile:GetCell():ConfigId()
    self.furnitureLevelCfgCell = ConfigRefer.CityFurnitureLevel:Find(self.furnitureLevelCfgId)
    self.furnitureLevel = self.furnitureLevelCfgCell:Level()
end

return CityFurnitureCatchPetUIParameter