local CityTileAssetSafeAreaWallOrDoorBubble = require("CityTileAssetSafeAreaWallOrDoorBubble")
local CityTileAssetSafeAreaDoorSelectedBox = require("CityTileAssetSafeAreaDoorSelectedBox")

local CityTileView = require("CityTileView")

---@class CityTileViewSafeAreaWall:CityTileView
---@field new fun():CityTileViewSafeAreaWall
---@field super CityTileView
---@field tile CitySafeAreaWallDoorTile
local CityTileViewSafeAreaWall = class('CityTileViewSafeAreaWall', CityTileView)

function CityTileViewSafeAreaWall:ctor()
    CityTileView.ctor(self)
    self:AddAsset(CityTileAssetSafeAreaWallOrDoorBubble.new())
    self:AddAsset(CityTileAssetSafeAreaDoorSelectedBox.new())
end

return CityTileViewSafeAreaWall