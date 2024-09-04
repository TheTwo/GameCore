local CityTileAssetSafeAreaDoor = require("CityTileAssetSafeAreaDoor")
local CityTileAssetSafeAreaDoorBroken = require("CityTileAssetSafeAreaDoorBroken")
local CityTileAssetSafeAreaWallOrDoorBubble = require("CityTileAssetSafeAreaWallOrDoorBubble")
local CityTileAssetSafeAreaWallSLGUnitLifeBarTemp = require("CityTileAssetSafeAreaWallSLGUnitLifeBarTemp")
local CityTileAssetSafeAreaDoorSelectedBox = require("CityTileAssetSafeAreaDoorSelectedBox")

local CityTileView = require("CityTileView")

---@class CityTileViewSafeAreaDoor:CityTileView
---@field new fun():CityTileViewSafeAreaDoor
---@field super CityTileView
---@field tile CitySafeAreaWallDoorTile
local CityTileViewSafeAreaDoor = class('CityTileViewSafeAreaDoor', CityTileView)

function CityTileViewSafeAreaDoor:ctor()
    CityTileView.ctor(self)
    self:AddMainAsset(CityTileAssetSafeAreaDoor.new())
    self:AddAsset(CityTileAssetSafeAreaDoorBroken.new())
    self:AddAsset(CityTileAssetSafeAreaWallOrDoorBubble.new())
    self:AddAsset(CityTileAssetSafeAreaWallSLGUnitLifeBarTemp.new())
    self:AddAsset(CityTileAssetSafeAreaDoorSelectedBox.new())
end

return CityTileViewSafeAreaDoor