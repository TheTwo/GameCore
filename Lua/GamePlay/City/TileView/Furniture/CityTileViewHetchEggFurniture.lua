local CityTileAssetFurnitureHatchEgg = require("CityTileAssetFurnitureHatchEgg")
local CityTileViewFurniture = require("CityTileViewFurniture")
---@class CityTileViewHetchEggFurniture:CityTileViewFurniture
---@field new fun():CityTileViewHetchEggFurniture
local CityTileViewHetchEggFurniture = class("CityTileViewHetchEggFurniture", CityTileViewFurniture)
local CityTileAssetFurnitureHatchEggFacility = require("CityTileAssetFurnitureHatchEggFacility")
local CityTileAssetFurnitureBuildingEntry = require("CityTileAssetFurnitureBuildingEntry")
local CityTileAssetFurnitureDoor = require("CityTileAssetFurnitureDoor")
local CityTileAssetBubbleFurnitureWork = require("CityTileAssetBubbleFurnitureWork")
local CityTileAssetFurnitureUpgradeVfx = require("CityTileAssetFurnitureUpgradeVfx")
local CityTileAssetDefenseTowerCircle = require("CityTileAssetDefenseTowerCircle")
local CityTileAssetFurnitureBar = require("CityTileAssetFurnitureBar")
local CityTileAssetBubbleFurnitureRepair = require("CityTileAssetBubbleFurnitureRepair")
local CityTileAssetCanUpgradeFoot = require("CityTileAssetCanUpgradeFoot")
local CityTileAssetFurnitureStorage = require("CityTileAssetFurnitureStorage")
local CityTileAssetWaitRibbonCutting = require("CityTileAssetWaitRibbonCutting")

function CityTileViewHetchEggFurniture:ctor()
    CityTileViewFurniture.ctor(self)
    self:AddAsset(CityTileAssetFurnitureHatchEgg.new())
end

function CityTileViewHetchEggFurniture:AddAssets()
    self:AddMainAsset(CityTileAssetFurnitureHatchEggFacility.new())
    self:AddAsset(CityTileAssetFurnitureBuildingEntry.new())
    self:AddAsset(CityTileAssetFurnitureDoor.new())
    self:AddAsset(CityTileAssetBubbleFurnitureWork.new())
    self:AddAsset(CityTileAssetFurnitureUpgradeVfx.new())
    self:AddAsset(CityTileAssetDefenseTowerCircle.new())
    self:AddAsset(CityTileAssetFurnitureBar.new())
    self:AddAsset(CityTileAssetBubbleFurnitureRepair.new())
    self:AddAsset(CityTileAssetCanUpgradeFoot.new())
    self:AddAsset(CityTileAssetFurnitureStorage.new())
    self:AddAsset(CityTileAssetWaitRibbonCutting.new())
end

return CityTileViewHetchEggFurniture