local MapTileView = require("MapTileView")
local PvPTileAssetCity = require("PvPTileAssetCity")
local PvPTileAssetHUDIconCastle = require("PvPTileAssetHUDIconCastle")
local PvPTileAssetProtectionShield = require("PvPTileAssetProtectionShield")
local PvPTileAssetRelocateEffect = require("PvPTileAssetRelocateEffect")
local PvPTileAssetHUDConstructionCastle = require("PvPTileAssetHUDConstructionCastle")

---@class PvPTileViewCity : MapTileView
local PvPTileViewCity = class("PvPTileViewCity", MapTileView)

function PvPTileViewCity:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetCity.new())
    self:AddAsset(PvPTileAssetHUDIconCastle.new())
    self:AddAsset(PvPTileAssetProtectionShield.new())
    self:AddAsset(PvPTileAssetRelocateEffect.new())
    self:AddAsset(PvPTileAssetHUDConstructionCastle.new())
end

return PvPTileViewCity