local CityTileViewFurniture = require("CityTileViewFurniture")
---@class CityTileViewStoreroomFurniture:CityTileViewFurniture
---@field new fun():CityTileViewStoreroomFurniture
local CityTileViewStoreroomFurniture = class("CityTileViewStoreroomFurniture", CityTileViewFurniture)
local CityTileAssetFurnitureStoreroom = require("CityTileAssetFurnitureStoreroom")
local CityTileAssetBubbleFurnitureWork = require("CityTileAssetBubbleFurnitureWork")
local CityTileAssetFurnitureUpgradeVfx = require("CityTileAssetFurnitureUpgradeVfx")
local CityTileAssetFurnitureBar = require("CityTileAssetFurnitureBar")
local CityTileAssetBubbleFurnitureRepair = require("CityTileAssetBubbleFurnitureRepair")
local CityTileAssetCanUpgradeFoot = require("CityTileAssetCanUpgradeFoot")
local CityTileAssetWaitRibbonCutting = require("CityTileAssetWaitRibbonCutting")

function CityTileViewStoreroomFurniture:ctor()
    CityTileViewFurniture.ctor(self)
end

function CityTileViewStoreroomFurniture:AddAssets()
    self:AddMainAsset(CityTileAssetFurnitureStoreroom.new())
    self:AddAsset(CityTileAssetBubbleFurnitureWork.new())
    self:AddAsset(CityTileAssetFurnitureUpgradeVfx.new())
    self:AddAsset(CityTileAssetFurnitureBar.new())
    self:AddAsset(CityTileAssetBubbleFurnitureRepair.new())
    self:AddAsset(CityTileAssetCanUpgradeFoot.new())
    self:AddAsset(CityTileAssetWaitRibbonCutting.new())
end

return CityTileViewStoreroomFurniture