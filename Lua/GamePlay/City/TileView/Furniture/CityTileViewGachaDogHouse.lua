local CityTileAssetGachaBubble = require("CityTileAssetGachaBubble")
local CityTileViewFurniture = require("CityTileViewFurniture")

---@class CityTileViewGachaDogHouse:CityTileView
---@field new fun():CityTileViewGachaDogHouse
---@field super CityTileView
local CityTileViewGachaDogHouse = class('CityTileViewGachaDogHouse', CityTileViewFurniture)

function CityTileViewGachaDogHouse:ctor()
    CityTileViewFurniture.ctor(self)
    self:AddAsset(CityTileAssetGachaBubble.new())
end

return CityTileViewGachaDogHouse