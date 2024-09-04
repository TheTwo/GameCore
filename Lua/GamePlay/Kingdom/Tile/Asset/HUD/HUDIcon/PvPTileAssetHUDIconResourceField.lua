local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local ModuleRefer = require("ModuleRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ConfigRefer = require("ConfigRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomConstant = require("KingdomConstant")

---@class PvPTileAssetHUDIconResourceField : PvPTileAssetHUDIcon
local PvPTileAssetHUDIconResourceField = class("PvPTileAssetHUDIconResourceField", PvPTileAssetHUDIcon)

function PvPTileAssetHUDIconResourceField:OnRefresh(entity)
    local lod = KingdomMapUtils.GetLOD()
    local icon = ModuleRefer.MapBuildingTroopModule:GetBuildingIcon(entity, lod)
    local name = nil
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
    self.behavior:SetIcon(icon)
    self.behavior:AdjustNameLevel(name, level)
end

function PvPTileAssetHUDIconResourceField:OnIconClick()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
    local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(tileX, tileZ, ModuleRefer.MapBuildingTroopModule:GetBuildingName(entity), level)
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

function PvPTileAssetHUDIconResourceField:DisplayIcon(lod)
    ---@type wds.ResourceField
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckIconLodByFixedConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconResourceField:DisplayText(lod)
    ---@type wds.ResourceField
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckTextLodByFixedConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconResourceField:DisplayName(lod)
    ---@type wds.ResourceField
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckNameLodByFixedConfig(entity.MapBasics.ConfID, lod)
end

return PvPTileAssetHUDIconResourceField