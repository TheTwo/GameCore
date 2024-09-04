local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local ModuleRefer = require("ModuleRefer")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local Utils = require("Utils")
local DBEntityType = require('DBEntityType')

---@class PvPTileAssetHUDIconGate : PvPTileAssetHUDIcon
local PvPTileAssetHUDIconGate = class("PvPTileAssetHUDIconGate", PvPTileAssetHUDIcon)

function PvPTileAssetHUDIconGate:DisplayIcon(lod)
    ---@type wds.Pass
    local entity = self:GetData()
    if not entity then
        return false
    end

    return KingdomMapUtils.CheckIconLodByFixedConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconGate:DisplayText(lod)
    ---@type wds.Pass
    local entity = self:GetData()
    if not entity then
        return false
    end

    return KingdomMapUtils.CheckTextLodByFixedConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconGate:DisplayName(lod)
    ---@type wds.Pass
    local entity = self:GetData()
    if not entity then
        return false
    end

    return KingdomMapUtils.CheckNameLodByFixedConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconGate:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Pass.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Pass.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))
end

function PvPTileAssetHUDIconGate:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Pass.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Pass.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))
end

---@param entity wds.Pass
function PvPTileAssetHUDIconGate:OnRefresh(entity)
    local isCreepInfected = KingdomMapUtils.IsMapEntityCreepInfected(entity)
    local icon = ModuleRefer.VillageModule:GetVillageIcon(entity.Owner.AllianceID, entity.Owner.PlayerID, entity.MapBasics.ConfID, false, isCreepInfected)
    local levelBase = ModuleRefer.VillageModule:GetVillageLevelBaseSprite(entity.MapBasics.ConfID)
    local color = ModuleRefer.MapBuildingTroopModule:GetColor(entity.Owner, isCreepInfected)
    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(entity)
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
    self.behavior:SetIcon(icon)
    self.behavior:SetLevelBase(levelBase)
    self.behavior:AdjustNameLevel(name, level)
    self.behavior:SetNameColor(color)
end

---@param entity wds.Pass
function PvPTileAssetHUDIconGate:OnOwnerChanged(entity)
    if Utils.IsNull(self.behavior) then
        return
    end
    if entity.ID == self.view.uniqueId and self.behavior then
        local isCreepInfected = KingdomMapUtils.IsMapEntityCreepInfected(entity)
        local color = ModuleRefer.MapBuildingTroopModule:GetColor(entity.Owner, isCreepInfected)
        local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(entity)
        local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
        self.behavior:AdjustNameLevel(name, level)
        self.behavior:SetNameColor(color)
    end
end

---@param entity wds.Pass
function PvPTileAssetHUDIconGate:OnCreepInfectedChanged(entity)
    if Utils.IsNull(self.behavior) then
        return
    end
    if entity.ID == self.view.uniqueId and self.behavior then
        self:OnRefresh(entity)
    end
end

function PvPTileAssetHUDIconGate:OnIconClick()
    local entity = self:GetData()
    if not entity then
        return
    end

    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(entity)
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
    local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(tileX, tileZ, name, level)
    ModuleRefer.MapBuildingTroopModule:ExtraHighLodDataProcessor(entity, touchData)
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

return PvPTileAssetHUDIconGate
