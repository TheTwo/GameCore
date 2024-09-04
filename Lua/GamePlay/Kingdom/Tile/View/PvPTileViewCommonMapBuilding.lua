local PvPTileAssetCommonMapBuilding = require("PvPTileAssetCommonMapBuilding")
local PvPTileAssetHudBuild = require("PvPTileAssetHudBuild")
local PvPTileAssetHUDConstructionCommonMapBuilding = require("PvPTileAssetHUDConstructionCommonMapBuilding")
local PvPTileAssetBuildingConstructingVfx = require("PvPTileAssetBuildingConstructingVfx")
local PvPTileAssetBuildingCompleteVfx = require("PvPTileAssetBuildingCompleteVfx")
local PvPTileAssetBuildingBrokenVfx = require("PvPTileAssetBuildingBrokenVfx")
local PvPTileAssetBehemothDeviceDynamic = require("PvPTileAssetBehemothDeviceDynamic")
local PvPTileAssetHUDIconCommonMapBuilding = require("PvPTileAssetHUDIconCommonMapBuilding")
local PvPTileAssetHUDTroopHead = require("PvPTileAssetHUDTroopHead")

local MapTileView = require("MapTileView")

---@class PvPTileViewCommonMapBuilding:MapTileView
---@field new fun():PvPTileViewCommonMapBuilding
---@field super MapTileView
local PvPTileViewCommonMapBuilding = class('PvPTileViewCommonMapBuilding', MapTileView)

function PvPTileViewCommonMapBuilding:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetCommonMapBuilding.new())
    self:AddAsset(PvPTileAssetHudBuild.new())
    self:AddAsset(PvPTileAssetHUDConstructionCommonMapBuilding.new())
    self:AddAsset(PvPTileAssetBuildingConstructingVfx.new())
    self:AddAsset(PvPTileAssetBuildingCompleteVfx.new())
    self:AddAsset(PvPTileAssetBuildingBrokenVfx.new())
    self:AddAsset(PvPTileAssetBehemothDeviceDynamic.new())
    self:AddAsset(PvPTileAssetHUDIconCommonMapBuilding.new())
    self:AddAsset(PvPTileAssetHUDTroopHead.new())
end

return PvPTileViewCommonMapBuilding