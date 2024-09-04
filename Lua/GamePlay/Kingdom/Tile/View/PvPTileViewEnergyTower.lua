local MapTileView = require("MapTileView")
local PvPTileAssetEnergyTower = require("PvPTileAssetEnergyTower")
local PvPTileAssetCircleRange = require("PvPTileAssetCircleRange")
local PvPTileAssetHudBuild = require("PvPTileAssetHudBuild")
local PvPTileAssetHUDConstructionEnergyTower = require("PvPTileAssetHUDConstructionEnergyTower")
local PvPTileAssetHUDIconEnergyTower = require("PvPTileAssetHUDIconEnergyTower")
local PvPTileAssetBuildingConstructingVfx = require("PvPTileAssetBuildingConstructingVfx")
local PvPTileAssetBuildingCompleteVfx = require("PvPTileAssetBuildingCompleteVfx")
local PvPTileAssetBuildingBrokenVfx = require("PvPTileAssetBuildingBrokenVfx")
local PvPTileAssetHUDTroopHead = require("PvPTileAssetHUDTroopHead")

---@class PvPTileViewEnergyTower : MapTileView
local PvPTileViewEnergyTower = class("PvPTileViewEnergyTower", MapTileView)

function PvPTileViewEnergyTower:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetEnergyTower.new())
    self:AddAsset(PvPTileAssetCircleRange.new())
    self:AddAsset(PvPTileAssetHudBuild.new())
    self:AddAsset(PvPTileAssetHUDConstructionEnergyTower.new())
    self:AddAsset(PvPTileAssetHUDIconEnergyTower.new())
    self:AddAsset(PvPTileAssetBuildingConstructingVfx.new())
    self:AddAsset(PvPTileAssetBuildingCompleteVfx.new())
    self:AddAsset(PvPTileAssetBuildingBrokenVfx.new())
    self:AddAsset(PvPTileAssetHUDTroopHead.new())
end

return PvPTileViewEnergyTower