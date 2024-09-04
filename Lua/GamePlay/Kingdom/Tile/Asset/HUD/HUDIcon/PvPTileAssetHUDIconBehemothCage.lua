local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityPath = require("DBEntityPath")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local ConfigRefer = require("ConfigRefer")

local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")

---@class PvPTileAssetHUDIconBehemothCage:PvPTileAssetHUDIcon
---@field new fun():PvPTileAssetHUDIconBehemothCage
---@field super PvPTileAssetHUDIcon
local PvPTileAssetHUDIconBehemothCage = class('PvPTileAssetHUDIconBehemothCage', PvPTileAssetHUDIcon)

function PvPTileAssetHUDIconBehemothCage:DisplayIcon(lod)
    ---@type wds.BehemothCage
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckIconLodByFixedConfig(entity.BehemothCage.ConfigId, lod)
end

function PvPTileAssetHUDIconBehemothCage:DisplayText(lod)
    ---@type wds.BehemothCage
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckTextLodByFixedConfig(entity.BehemothCage.ConfigId, lod)
end

function PvPTileAssetHUDIconBehemothCage:DisplayName(lod)
    ---@type wds.BehemothCage
    local entity = self:GetData()
    if not entity then
        return false
    end
    return KingdomMapUtils.CheckNameLodByFixedConfig(entity.BehemothCage.ConfigId, lod)
end

function PvPTileAssetHUDIconBehemothCage:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.BehemothCage.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.BehemothCage.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))
end

function PvPTileAssetHUDIconBehemothCage:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.BehemothCage.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.BehemothCage.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))
end

---@param behemothCage wds.BehemothCage
function PvPTileAssetHUDIconBehemothCage:OnRefresh(behemothCage)
    local isCreepInfected = KingdomMapUtils.IsMapEntityCreepInfected(behemothCage)
    local icon = ModuleRefer.VillageModule:GetVillageIcon(behemothCage.Owner.AllianceID, behemothCage.Owner.PlayerID, behemothCage.BehemothCage.ConfigId, false, isCreepInfected)
    local levelBase = ModuleRefer.VillageModule:GetVillageLevelBaseSprite(behemothCage.BehemothCage.ConfigId)
    local color = ModuleRefer.MapBuildingTroopModule:GetColor(behemothCage.Owner, isCreepInfected)
    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(behemothCage)
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(behemothCage)
    self.behavior:SetIcon(icon)
    self.behavior:SetLevelBase(levelBase)
    self.behavior:AdjustNameLevel(name, level)
    self.behavior:SetNameColor(color)
end

---@param behemothCage wds.BehemothCage
function PvPTileAssetHUDIconBehemothCage:OnOwnerChanged(behemothCage)
    if Utils.IsNull(self.behavior) then
        return
    end
    if behemothCage.ID == self.view.uniqueId and self.behavior then
        local isCreepInfected = KingdomMapUtils.IsMapEntityCreepInfected(behemothCage)
        local icon = ModuleRefer.VillageModule:GetVillageIcon(behemothCage.Owner.AllianceID, behemothCage.Owner.PlayerID, behemothCage.BehemothCage.ConfigId, false, isCreepInfected)
        local color = ModuleRefer.MapBuildingTroopModule:GetColor(behemothCage.Owner, isCreepInfected)
        local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(behemothCage)
        local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(behemothCage)
        self.behavior:SetIcon(icon)
        self.behavior:AdjustNameLevel(name, level)
        self.behavior:SetNameColor(color)
    end
end

---@param behemothCage wds.BehemothCage
function PvPTileAssetHUDIconBehemothCage:OnCreepInfectedChanged(behemothCage)
    if Utils.IsNull(self.behavior) then
        return
    end
    if behemothCage.ID == self.view.uniqueId and self.behavior then
        self:OnRefresh(behemothCage)
    end
end

function PvPTileAssetHUDIconBehemothCage:OnIconClick()
    ---@type wds.BehemothCage
    local entity = self:GetData()
    if not entity then
        return
    end

    local touchData = KingdomTouchInfoFactory.CreateBehemothCageLod3(entity)
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

return PvPTileAssetHUDIconBehemothCage