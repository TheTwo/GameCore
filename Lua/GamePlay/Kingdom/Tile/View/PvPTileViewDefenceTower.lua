local MapTileView = require("MapTileView")
local PvPTileAssetDefenceTower = require("PvPTileAssetDefenceTower")
local PvPTileAssetCircleRange = require("PvPTileAssetCircleRange")
local PvPTileAssetHudBuild = require("PvPTileAssetHudBuild")
local PvPTileAssetHUDConstructionDefenseTower = require("PvPTileAssetHUDConstructionDefenseTower")
local PvPTileAssetHUDIconDefenseTower = require("PvPTileAssetHUDIconDefenseTower")
local PvPTileAssetBuildingConstructingVfx = require("PvPTileAssetBuildingConstructingVfx")
local PvPTileAssetBuildingCompleteVfx = require("PvPTileAssetBuildingCompleteVfx")
local PvPTileAssetBuildingBrokenVfx = require("PvPTileAssetBuildingBrokenVfx")
local PvPTileAssetHUDTroopHead = require("PvPTileAssetHUDTroopHead")

---@class PvPTileViewDefenceTower : MapTileView
local PvPTileViewDefenceTower = class("PvPTileViewDefenceTower", MapTileView)

function PvPTileViewDefenceTower:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetDefenceTower.new())
    self:AddAsset(PvPTileAssetCircleRange.new())
    self:AddAsset(PvPTileAssetHudBuild.new())
    self:AddAsset(PvPTileAssetHUDConstructionDefenseTower.new())
    self:AddAsset(PvPTileAssetHUDIconDefenseTower.new())
    self:AddAsset(PvPTileAssetBuildingConstructingVfx.new())
    self:AddAsset(PvPTileAssetBuildingCompleteVfx.new())
    self:AddAsset(PvPTileAssetBuildingBrokenVfx.new())
    self:AddAsset(PvPTileAssetHUDTroopHead.new())
end

return PvPTileViewDefenceTower