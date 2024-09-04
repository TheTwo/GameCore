local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetFurnitureUpgradeVfx:CityTileAsset
---@field new fun():CityTileAssetFurnitureUpgradeVfx
local CityTileAssetFurnitureUpgradeVfx = class("CityTileAssetFurnitureUpgradeVfx", CityTileAsset)
local Utils = require("Utils")
local ArtResourceUtils = require("ArtResourceUtils")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")

function CityTileAssetFurnitureUpgradeVfx:GetPrefabName()
    self.modelId = nil
    if not self:ShouldShow() then
        return string.Empty
    end

    ---@type CityFurniture
    local furniture = self.tileView.tile:GetCell()
    self.modelId = furniture.furnitureCell:ScaffoldingModel()
    return ArtResourceUtils.GetItem(self.modelId)
end

function CityTileAssetFurnitureUpgradeVfx:ShouldShow()
    local castleFurniture = self.tileView.tile:GetCastleFurniture()
    if castleFurniture == nil then return false end

    if not castleFurniture.LevelUpInfo.Working then
        return false
    end

    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    if not lvCfg then
        return false
    end

    local nextLevelCfg = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(lvCfg:Type(), lvCfg:Level() + 1)
    if nextLevelCfg == nil then
        return false
    end

    local furnitureManager = self:GetCity().furnitureManager
    return furnitureManager:GetFurnitureUpgradeCostTime(nextLevelCfg) > 0 and castleFurniture.LevelUpInfo.CurProgress < castleFurniture.LevelUpInfo.TargetProgress
end

function CityTileAssetFurnitureUpgradeVfx:GetScale()
    if self.modelId then
        return ArtResourceUtils.GetScale(self.modelId)
    end
    return CityTileAsset.GetScale(self)
end

function CityTileAssetFurnitureUpgradeVfx:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then
        handle:Delete()
        return
    end

    local cell = self.tileView.tile:GetCell()
    local transform = go.transform
    transform:SetPositionAndRotation(self:GetCity():GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY), CS.UnityEngine.Quaternion.identity)
end

return CityTileAssetFurnitureUpgradeVfx