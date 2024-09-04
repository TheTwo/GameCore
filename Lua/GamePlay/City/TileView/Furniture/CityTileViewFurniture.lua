local CityTileView = require("CityTileView")
---@class CityTileViewFurniture:CityTileView
---@field new fun():CityTileViewFurniture
local CityTileViewFurniture = class("CityTileViewFurniture", CityTileView)
local CityTileAssetFurniture = require("CityTileAssetFurniture")
local CityTileAssetFurnitureSLG = require("CityTileAssetFurnitureSLG")
local CityTileAssetFurnitureBuildingEntry = require("CityTileAssetFurnitureBuildingEntry")
local CityTileAssetFurnitureDoor = require("CityTileAssetFurnitureDoor")
local CityTileAssetBubbleFurnitureWork = require("CityTileAssetBubbleFurnitureWork")
local CityTileAssetFurnitureUpgradeVfx = require("CityTileAssetFurnitureUpgradeVfx")
local CityTileAssetDefenseTowerCircle = require("CityTileAssetDefenseTowerCircle")
local CityTileAssetFurnitureBar = require("CityTileAssetFurnitureBar")
local CityTileAssetBubbleFurnitureRepair = require("CityTileAssetBubbleFurnitureRepair")
local CityTileAssetCanUpgradeFoot = require("CityTileAssetCanUpgradeFoot")
local CityTileAssetFurnitureStorage = require("CityTileAssetFurnitureStorage")
local CityTileAssetFurnitureCrop = require("CityTileAssetFurnitureCrop")
local CityTileAssetWaitRibbonCutting = require("CityTileAssetWaitRibbonCutting")

function CityTileViewFurniture:ctor()
    CityTileView.ctor(self)
    self:AddAssets()
end

function CityTileViewFurniture:AddAssets()
    self:AddMainAsset(CityTileAssetFurniture.new())
    self:AddMainAsset(CityTileAssetFurnitureSLG.new())
    self:AddAsset(CityTileAssetFurnitureBuildingEntry.new())
    self:AddAsset(CityTileAssetFurnitureDoor.new())
    self:AddAsset(CityTileAssetBubbleFurnitureWork.new())
    self:AddAsset(CityTileAssetFurnitureUpgradeVfx.new())
    self:AddAsset(CityTileAssetDefenseTowerCircle.new())
    self:AddAsset(CityTileAssetFurnitureBar.new())
    self:AddAsset(CityTileAssetBubbleFurnitureRepair.new())
    self:AddAsset(CityTileAssetCanUpgradeFoot.new())
    self:AddAsset(CityTileAssetFurnitureStorage.new())
    self:AddAsset(CityTileAssetFurnitureCrop.new())
    self:AddAsset(CityTileAssetWaitRibbonCutting.new())
end

function CityTileViewFurniture:OnRoofStateChanged(flag)
    for _, asset in pairs(self.assets) do
        if asset.OnRoofStateChanged then
            asset:OnRoofStateChanged(flag)
        end
    end
end

function CityTileViewFurniture:ToString()
    local furniture = self.tile:GetCell()
    return ("[id:%d, cfg:%d]"):format(furniture.singleId, furniture.configId)
end

return CityTileViewFurniture