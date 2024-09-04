local CityTileView = require("CityTileView")
---@class CityTileViewBuildingBase:CityTileView
---@field new fun():CityTileViewBuildingBase
local CityTileViewBuildingBase = class("CityTileViewBuildingBase", CityTileView)
local CityTileAssetBuilding = require("CityTileAssetBuilding")
local CityTileAssetBuildingSLG = require("CityTileAssetBuildingSLG")
local CityTileAssetConstructionTimeBar = require("CityTileAssetConstructionTimeBar")
local CityTileAssetResidentMark = require("CityTileAssetResidentMark")
local CityTileAssetCanUpgradeBubble = require("CityTileAssetCanUpgradeBubble")
local CityTileAssetRepairGroup = require("CityTileAssetRepairGroup")
local CityTileAssetRoomWallAndDoor = require("CityTileAssetRoomWallAndDoor")
local CityTileAssetDoorGroup = require("CityTileAssetDoorGroup")
local CityTileAssetRoomFloor = require("CityTileAssetRoomFloor")
local CityTileAssetBuildingSLGUnitLifeBarTemp = require("CityTileAssetBuildingSLGUnitLifeBarTemp")
local CityTileAssetRibbonCuttingBubble = require("CityTileAssetRibbonCuttingBubble")
local CityTileAssetConstructingVfx = require("CityTileAssetConstructingVfx")

function CityTileViewBuildingBase:ctor()
    CityTileView.ctor(self)
    self:AddAssets()
end

function CityTileViewBuildingBase:OnRoofStateChanged(flag)
    for _, asset in pairs(self.assets) do
        if asset.OnRoofStateChanged then
            asset:OnRoofStateChanged(flag)
        end
    end
end

function CityTileViewBuildingBase:OnWallHideChanged(flag)
    for _, asset in pairs(self.assets) do
        if asset.OnWallHideChanged then
            asset:OnWallHideChanged(flag)
        end
    end
end

function CityTileViewBuildingBase:AddAssets()
    ---override this
    self:AddMainAsset(CityTileAssetBuilding.new())
    self:AddMainAsset(CityTileAssetBuildingSLG.new())
    self:AddAsset(CityTileAssetResidentMark.new())
    self:AddAsset(CityTileAssetConstructionTimeBar.new())
    self:AddAsset(CityTileAssetCanUpgradeBubble.new())
    self:AddAsset(CityTileAssetRepairGroup.new())
    self:AddAsset(CityTileAssetRoomWallAndDoor.new())
    self:AddAsset(CityTileAssetDoorGroup.new())
    self:AddAsset(CityTileAssetRoomFloor.new())
    self:AddAsset(CityTileAssetBuildingSLGUnitLifeBarTemp.new())
    self:AddAsset(CityTileAssetRibbonCuttingBubble.new())
    self:AddAsset(CityTileAssetConstructingVfx.new())
end

return CityTileViewBuildingBase