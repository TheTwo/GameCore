local MapTileView = require("MapTileView")
local NewbieTileAssetCity = require("NewbieTileAssetCity")
local NewbieTileAssetHUDIcon = require("NewbieTileAssetHUDIcon")
local NewbieTileAssetHUDConstruction = require("NewbieTileAssetHUDConstruction")

---@class NewbieTileViewCity : MapTileView
local NewbieTileViewCity = class("NewbieTileViewCity", MapTileView)

function NewbieTileViewCity:ctor()
    MapTileView.ctor(self)
    self:AddAsset(NewbieTileAssetCity.new())
    self:AddAsset(NewbieTileAssetHUDIcon.new())
    self:AddAsset(NewbieTileAssetHUDConstruction.new())
end

return NewbieTileViewCity