local PvPTileAssetHUDIconBehemothCage = require("PvPTileAssetHUDIconBehemothCage")
local PvPTileAssetBehemothSealedVFX = require("PvPTileAssetBehemothSealedVFX")
local PvPTileAssetBehemothCageRadarBubble = require("PvPTileAssetBehemothCageRadarBubble")

local MapTileView = require("MapTileView")

---@class PvPTileViewBehemothCage:MapTileView
---@field new fun():PvPTileViewBehemothCage
---@field super MapTileView
local PvPTileViewBehemothCage = class('PvPTileViewBehemothCage', MapTileView)

function PvPTileViewBehemothCage:ctor()
    PvPTileViewBehemothCage.super.ctor(self)

    self:AddAsset(PvPTileAssetBehemothSealedVFX.new())
    self:AddAsset(PvPTileAssetBehemothCageRadarBubble.new())
    self:AddAsset(PvPTileAssetHUDIconBehemothCage.new())
end

return PvPTileViewBehemothCage