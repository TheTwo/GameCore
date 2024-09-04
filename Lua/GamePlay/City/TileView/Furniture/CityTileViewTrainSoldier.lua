local CityTileAssetTrainBubble = require("CityTileAssetTrainBubble")
local CityTileAssetFurnitureTrain = require("CityTileAssetFurnitureTrain")
local CityTileViewFurniture = require("CityTileViewFurniture")
local CityTileAssetFurnitureSLG = require("CityTileAssetFurnitureSLG")
local CityTileAssetFurnitureBuildingEntry = require("CityTileAssetFurnitureBuildingEntry")
local CityTileAssetFurnitureDoor = require("CityTileAssetFurnitureDoor")
local CityTileAssetBubbleFurnitureWork = require("CityTileAssetBubbleFurnitureWork")
local CityTileAssetFurnitureUpgradeVfx = require("CityTileAssetFurnitureUpgradeVfx")
local CityTileAssetDefenseTowerCircle = require("CityTileAssetDefenseTowerCircle")
local CityTileAssetFurnitureBar = require("CityTileAssetFurnitureBar")
local CityTileAssetBubbleFurnitureRepair = require("CityTileAssetBubbleFurnitureRepair")
local CityTileAssetCanUpgradeFoot = require("CityTileAssetCanUpgradeFoot")
local CityTileAssetWaitRibbonCutting = require("CityTileAssetWaitRibbonCutting")

---@class CityTileViewTrainSoldier:CityTileView
---@field new fun():CityTileViewTrainSoldier
---@field super CityTileView
local CityTileViewTrainSoldier = class('CityTileViewTrainSoldier', CityTileViewFurniture)

function CityTileViewTrainSoldier:AddAssets()
    self:AddMainAsset(CityTileAssetFurnitureTrain.new())
    self:AddMainAsset(CityTileAssetFurnitureSLG.new())
    self:AddAsset(CityTileAssetTrainBubble.new())
    self:AddAsset(CityTileAssetFurnitureBuildingEntry.new())
    self:AddAsset(CityTileAssetFurnitureDoor.new())
    self:AddAsset(CityTileAssetBubbleFurnitureWork.new())
    self:AddAsset(CityTileAssetFurnitureUpgradeVfx.new())
    self:AddAsset(CityTileAssetDefenseTowerCircle.new())
    self:AddAsset(CityTileAssetFurnitureBar.new())
    self:AddAsset(CityTileAssetBubbleFurnitureRepair.new())
    self:AddAsset(CityTileAssetCanUpgradeFoot.new())
    self:AddAsset(CityTileAssetWaitRibbonCutting.new())
end

return CityTileViewTrainSoldier