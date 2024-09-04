local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local ModuleRefer = require("ModuleRefer")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

---@class PlayerTileAssetHUDIconCreepTumor : PvPTileAssetHUDIcon
local PlayerTileAssetHUDIconCreepTumor = class("PlayerTileAssetHUDIconCreepTumor", PvPTileAssetHUDIcon)

function PlayerTileAssetHUDIconCreepTumor:CanShow()
    if not PlayerTileAssetHUDIconCreepTumor.super.CanShow(self) then
        return false
    end
    local entity = self:GetData()
    if not ModuleRefer.MapCreepModule:IsTumorAlive(entity) then
        return false
    end
    return true
end

function PlayerTileAssetHUDIconCreepTumor:GetLodPrefab(lod)
    if KingdomMapUtils.InMapIconLod(lod) then
        return PvPTileAssetHUDIcon.PrefabName
    end
    return string.Empty
end

function PlayerTileAssetHUDIconCreepTumor:OnConstructionUpdate()
    local entity = self:GetData()
    if not ModuleRefer.MapCreepModule:IsTumorAlive(entity) then
        self:Hide()
        return
    end
end

function PlayerTileAssetHUDIconCreepTumor:OnConstructionShutdown()
    PlayerTileAssetHUDIconCreepTumor.super.OnConstructionShutdown(self)
end

function PlayerTileAssetHUDIconCreepTumor:OnRefresh(entity)
    ---@type wds.PlayerMapCreep
    local creepData = entity
    local configCell = ConfigRefer.SlgCreepTumor:Find(creepData.CfgId)

    local icon = "sp_icon_lod_leida_juntan"
    local name = configCell and I18N.Get(configCell:CenterName()) or string.Empty
    local level = configCell and tostring(configCell:Level()) or string.Empty
    self.behavior:SetIcon(icon)
    self.behavior:AdjustNameLevel(name, level)
end

function PlayerTileAssetHUDIconCreepTumor:OnIconClick()
    ---@type wds.PlayerMapCreep
    local entity = self:GetData()
    if not entity then
        return
    end

    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(entity)
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
    local tileX, tileZ = self:GetServerPosition()
    local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(tileX, tileZ, name, level)
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

return PlayerTileAssetHUDIconCreepTumor