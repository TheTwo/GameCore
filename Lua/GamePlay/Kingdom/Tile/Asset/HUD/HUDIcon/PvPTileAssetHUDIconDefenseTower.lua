local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local ArtResourceUtils = require("ArtResourceUtils")
local ConfigRefer = require("ConfigRefer")

---@class PvPTileAssetHUDIconDefenseTower :PvPTileAssetHUDIcon
local PvPTileAssetHUDIconDefenseTower = class("PvPTileAssetHUDIconDefenseTower", PvPTileAssetHUDIcon)

function PvPTileAssetHUDIconDefenseTower:DisplayIcon(lod)
    ---@type wds.DefenceTower
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckIconLodByFlexdefenibleConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconDefenseTower:DisplayText(lod)
    ---@type wds.DefenceTower
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckTextLodByFlexibleConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconDefenseTower:DisplayName(lod)
    ---@type wds.DefenceTower
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckNameLodByFlexibleConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconDefenseTower:OnRefresh(entity)
    ---@type wds.DefenceTower
    local defenceTower = entity
    local lod = KingdomMapUtils.GetLOD()
    
    local name
    if not KingdomMapUtils.InMapMediumLod() then
        name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(defenceTower)
    end
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(defenceTower)
    local color = ModuleRefer.MapBuildingTroopModule:GetColor(defenceTower.Owner)
    local icon = ModuleRefer.MapBuildingTroopModule:GetBuildingIcon(defenceTower, lod)
    self.behavior:SetIcon(icon)
    self.behavior:AdjustNameLevel(name, level)
    self.behavior:SetNameColor(color)
end

function PvPTileAssetHUDIconDefenseTower:OnIconClick()
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

return PvPTileAssetHUDIconDefenseTower