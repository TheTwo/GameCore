local MapTileView = require("MapTileView")
local PvPTileAssetGate = require("PvPTileAssetGate")

---@class PvPTileViewGateDecoration : MapTileView
local PvPTileViewGateDecoration = class("PvPTileViewGateDecoration", MapTileView)

function PvPTileViewGateDecoration:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetGate.new())
end

return PvPTileViewGateDecoration
