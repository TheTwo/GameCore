local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local ArtResourceUtils = require("ArtResourceUtils")
local ConfigRefer = require("ConfigRefer")

---@class PvPTileAssetHUDIconEnergyTower :PvPTileAssetHUDIcon
local PvPTileAssetHUDIconEnergyTower = class("PvPTileAssetHUDIconEnergyTower", PvPTileAssetHUDIcon)

function PvPTileAssetHUDIconEnergyTower:DisplayIcon(lod)
    ---@type wds.EnergyTower
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckIconLodByFlexibleConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconEnergyTower:DisplayText(lod)
    ---@type wds.EnergyTower
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckTextLodByFlexibleConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconEnergyTower:DisplayName(lod)
    ---@type wds.EnergyTower
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckNameLodByFlexibleConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconEnergyTower:OnRefresh(entity)
    ---@type wds.EnergyTower
    local energyTower = entity
    local lod = KingdomMapUtils.GetLOD()

    local name
    if not KingdomMapUtils.InMapMediumLod() then
        name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(energyTower)
    end   
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(energyTower)
    local color = ModuleRefer.MapBuildingTroopModule:GetColor(energyTower.Owner)
    local icon = ModuleRefer.MapBuildingTroopModule:GetBuildingIcon(entity, lod)
    self.behavior:SetIcon(icon)
    self.behavior:AdjustNameLevel(name, level)
    self.behavior:SetNameColor(color)
end

function PvPTileAssetHUDIconEnergyTower:OnIconClick()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(entity)
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
    local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(tileX, tileZ, name, level)
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

return PvPTileAssetHUDIconEnergyTower