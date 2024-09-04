---@class CityFurnitureDetailsUIParameter
---@field new fun():CityFurnitureDetailsUIParameter
local CityFurnitureDetailsUIParameter = class("CityFurnitureDetailsUIParameter")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

---@param cellTile CityFurnitureTile
---@param payload LegoUIPage_SpecialData
function CityFurnitureDetailsUIParameter:ctor(cellTile, payload)
    self.cellTile = cellTile
    self.furLvCfg = self.cellTile:GetCell().furnitureCell
    self.furTypeCfg = ConfigRefer.CityFurnitureTypes:Find(self.furLvCfg:Type())
    self.name = I18N.Get(self.furTypeCfg:Name())
    self.description = I18N.Get(self.furTypeCfg:Description())
    self.specialData = payload
end

return CityFurnitureDetailsUIParameter