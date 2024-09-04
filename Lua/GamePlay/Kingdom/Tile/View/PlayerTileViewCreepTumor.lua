local MapTileView = require("MapTileView")
local PlayerTileAssetCreepTumor = require("PlayerTileAssetCreepTumor")
local PlayerTileAssetHUDIconCreepTumor = require("PlayerTileAssetHUDIconCreepTumor")
local PlayerTileAssetCreepTumorExplosion = require("PlayerTileAssetCreepTumorExplosion")
local PlayerTileAssetCreepHUD = require("PlayerTileAssetCreepHUD")

---@class PlayerTileViewCreepTumor : MapTileView
local PlayerTileViewCreepTumor = class("PlayerTileViewCreepTumor", MapTileView)

function PlayerTileViewCreepTumor:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PlayerTileAssetCreepTumor.new())
    --self:AddAsset(PlayerTileAssetHUDIconCreepTumor.new())
    self:AddAsset(PlayerTileAssetCreepTumorExplosion.new())
    self:AddAsset(PlayerTileAssetCreepHUD.new())
end

return PlayerTileViewCreepTumor