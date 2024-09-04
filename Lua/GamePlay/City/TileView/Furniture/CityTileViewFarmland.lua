local CityTileAssetFurnitureFarmland = require("CityTileAssetFurnitureFarmland")
local CityTileAssetFurnitureFarmlandCrop = require("CityTileAssetFurnitureFarmlandCrop")
local CityTileAssetFurnitureFarmlandTimeBar = require("CityTileAssetFurnitureFarmlandTimeBar")
local CityTileAssetFurnitureSLGUnitLifeBarTemp = require("CityTileAssetFurnitureSLGUnitLifeBarTemp")

local CityTileView = require("CityTileView")

---@class CityTileViewFarmland:CityTileView
---@field new fun():CityTileViewFarmland
---@field super CityTileView
local CityTileViewFarmland = class('CityTileViewFarmland', CityTileView)

function CityTileViewFarmland:ctor()
    CityTileView.ctor(self)
    self:AddMainAsset(CityTileAssetFurnitureFarmland.new())
    self:AddAsset(CityTileAssetFurnitureFarmlandCrop.new())
    self:AddAsset(CityTileAssetFurnitureFarmlandTimeBar.new())
    self:AddAsset(CityTileAssetFurnitureSLGUnitLifeBarTemp.new())
end

return CityTileViewFarmland