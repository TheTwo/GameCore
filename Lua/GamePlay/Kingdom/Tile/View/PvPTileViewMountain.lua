local MapTileView = require("MapTileView")
local PvPTileAssetMountain = require("PvPTileAssetMountain")

---@class PvPTileViewMountain : MapTileView
local PvPTileViewMountain = class("PvPTileViewMountain", MapTileView)

function PvPTileViewMountain:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetMountain.new())
end

return PvPTileViewMountain