local MapTileView = require("MapTileView")
local PvPTileAssetTransferTower = require("PvPTileAssetTransferTower")
local PvPTileAssetHudBuild = require("PvPTileAssetHudBuild")
local PvPTileAssetHUDConstruction = require("PvPTileAssetHUDConstruction")
local PvPTileAssetBuildingConstructingVfx = require("PvPTileAssetBuildingConstructingVfx")
local PvPTileAssetBuildingCompleteVfx = require("PvPTileAssetBuildingCompleteVfx")
local PvPTileAssetBuildingBrokenVfx = require("PvPTileAssetBuildingBrokenVfx")

---@class PvPTileViewTransferTower : MapTileView
local PvPTileViewTransferTower = class("PvPTileViewTransferTower", MapTileView)

function PvPTileViewTransferTower:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetTransferTower.new())
    self:AddAsset(PvPTileAssetHudBuild.new())
    self:AddAsset(PvPTileAssetHUDConstruction.new())
    self:AddAsset(PvPTileAssetBuildingConstructingVfx.new())
    self:AddAsset(PvPTileAssetBuildingCompleteVfx.new())
    self:AddAsset(PvPTileAssetBuildingBrokenVfx.new())
end

return PvPTileViewTransferTower