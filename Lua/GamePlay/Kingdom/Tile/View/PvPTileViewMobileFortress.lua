local MapTileView = require("MapTileView")
local PvPTileAssetMobileFortress = require("PvPTileAssetMobileFortress")
local PvPTileAssetHudBuild = require("PvPTileAssetHudBuild")
local PvPTileAssetHUDConstruction = require("PvPTileAssetHUDConstruction")
local PvPTileAssetBuildingConstructingVfx = require("PvPTileAssetBuildingConstructingVfx")
local PvPTileAssetBuildingCompleteVfx = require("PvPTileAssetBuildingCompleteVfx")
local PvPTileAssetBuildingBrokenVfx = require("PvPTileAssetBuildingBrokenVfx")

---@class PvPTileViewMobileFortress : MapTileView
local PvPTileViewMobileFortress = class("PvPTileViewMobileFortress", MapTileView)

function PvPTileViewMobileFortress:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetMobileFortress.new())
    self:AddAsset(PvPTileAssetHudBuild.new())
    self:AddAsset(PvPTileAssetHUDConstruction.new())
    self:AddAsset(PvPTileAssetBuildingConstructingVfx.new())
    self:AddAsset(PvPTileAssetBuildingCompleteVfx.new())
    self:AddAsset(PvPTileAssetBuildingBrokenVfx.new())
end

return PvPTileViewMobileFortress