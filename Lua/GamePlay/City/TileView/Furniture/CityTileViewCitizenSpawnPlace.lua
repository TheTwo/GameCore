local CityTileAssetCitizenSpawnPlace = require("CityTileAssetCitizenSpawnPlace")
local CityTileAssetCitizenSpawnPlaceBubble = require("CityTileAssetCitizenSpawnPlaceBubble")

local CityTileView = require("CityTileView")

---@class CityTileViewCitizenSpawnPlace:CityTileView
---@field new fun():CityTileViewCitizenSpawnPlace
---@field super CityTileView
local CityTileViewCitizenSpawnPlace = class('CityTileViewCitizenSpawnPlace', CityTileView)

function CityTileViewCitizenSpawnPlace:ctor()
    CityTileView.ctor(self)
    self:AddMainAsset(CityTileAssetCitizenSpawnPlace.new())
    self:AddAsset(CityTileAssetCitizenSpawnPlaceBubble.new())
end

return CityTileViewCitizenSpawnPlace