local MapTileView = require("MapTileView")
local PvPTileAssetSlope = require("PvPTileAssetSlope")
local PvPTileAssetSymbolSlope = require("PvPTileAssetSymbolSlope")

---@class PvPTileViewSlope : MapTileView
local PvPTileViewSlope = class("PvPTileViewSlope", MapTileView)

function PvPTileViewSlope:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetSlope.new())
    self:AddAsset(PvPTileAssetSymbolSlope.new())
end

return PvPTileViewSlope