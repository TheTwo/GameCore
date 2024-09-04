local MapTileView = require("MapTileView")
local PlayerTileAssetPetIcon = require("PlayerTileAssetPetIcon")
local PlayerTileAssetPet = require("PlayerTileAssetPet")
local PlayerTileAssetPetRadarBubble = require("PlayerTileAssetPetRadarBubble")
local PlayerTileAssetPetCatchEffect = require("PlayerTileAssetPetCatchEffect")

---@class PlayerTileViewPet : MapTileView
local PlayerTileViewPet = class("PlayerTileViewPet", MapTileView)

function PlayerTileViewPet:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PlayerTileAssetPet.new())
    self:AddAsset(PlayerTileAssetPetIcon.new())
    self:AddAsset(PlayerTileAssetPetRadarBubble.new())
    self:AddAsset(PlayerTileAssetPetCatchEffect.new())
end

return PlayerTileViewPet