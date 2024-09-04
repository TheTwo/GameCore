local MapTileView = require("MapTileView")
local PvPTileAssetBridge = require("PvPTileAssetBridge")
local PvPTileAssetSymbolBridge = require("PvPTileAssetSymbolBridge")

---@class PvPTileViewBridge : MapTileView
local PvPTileViewBridge = class("PvPTileViewBridge", MapTileView)

function PvPTileViewBridge:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetBridge.new())
    self:AddAsset(PvPTileAssetSymbolBridge.new())
end

return PvPTileViewBridge