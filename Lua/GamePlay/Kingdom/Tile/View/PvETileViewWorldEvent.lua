local MapTileView = require("MapTileView")
local PvETileAssetWorldEventCircleRange = require("PvETileAssetWorldEventCircleRange")
local PvETileAssetWorldEvent = require('PvETileAssetWorldEvent')

---@class PvETileViewWorldEvent : MapTileView
local PvETileViewWorldEvent = class("PvETileViewWorldEvent", MapTileView)

function PvETileViewWorldEvent:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvETileAssetWorldEventCircleRange.new())
    self:AddAsset(PvETileAssetWorldEvent.new())
end

return PvETileViewWorldEvent