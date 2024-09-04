local PvPTileAssetDecoration = require("PvPTileAssetDecoration")
local MapTileView = require("MapTileView")

---@class PvPTileViewDecoration : MapTileView
local PvPTileViewDecoration = class("PvPTileViewDecoration", MapTileView)

function PvPTileViewDecoration:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetDecoration.new())
end

return PvPTileViewDecoration