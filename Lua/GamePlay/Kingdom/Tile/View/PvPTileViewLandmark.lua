local MapTileView = require("MapTileView")
local PvPTileAssetLandmark = require("PvPTileAssetLandmark")

---@class PvPTileViewLandmark : MapTileView
local PvPTileViewLandmark = class("PvPTileViewLandmark", MapTileView)

function PvPTileViewLandmark:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetLandmark.new())
end

return PvPTileViewLandmark