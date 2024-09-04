local CityTileViewFurniture = require("CityTileViewFurniture")
---@class CityTileViewPetSystem:CityTileViewFurniture
---@field new fun():CityTileViewPetSystem
local CityTileViewPetSystem = class("CityTileViewPetSystem", CityTileViewFurniture)
local CityTileAssetFurnitureEggBubble = require("CityTileAssetFurnitureEggBubble")

function CityTileViewPetSystem:AddAssets()
    CityTileViewFurniture.AddAssets(self)
    self:AddAsset(CityTileAssetFurnitureEggBubble.new())
end

return CityTileViewPetSystem