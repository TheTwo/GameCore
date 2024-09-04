local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local ModuleRefer = require("ModuleRefer")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")

local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local Utils = require("Utils")

---@class PvPTileAssetHUDIconVillage : PvPTileAssetHUDIcon
---@field super PvPTileAssetHUDIcon
local PvPTileAssetHUDIconVillage = class("PvPTileAssetHUDIconVillage", PvPTileAssetHUDIcon)

function PvPTileAssetHUDIconVillage:DisplayIcon(lod)
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return false
    end
    if entity.VillageTransformInfo.Status == wds.VillageTransformStatus.VillageTransformStatusDone then
        return KingdomMapUtils.CheckIsEnterOrHigherIconLodFixed(entity.MapBasics.ConfID, lod)
    end
    return KingdomMapUtils.CheckIconLodByFixedConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconVillage:DisplayText(lod)
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return false
    end
    if entity.VillageTransformInfo.Status == wds.VillageTransformStatus.VillageTransformStatusDone then
        return true
    end
    return KingdomMapUtils.CheckTextLodByFixedConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconVillage:DisplayName(lod)
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return false
    end
    if entity.VillageTransformInfo.Status == wds.VillageTransformStatus.VillageTransformStatusDone then
        return true
    end
    return KingdomMapUtils.CheckNameLodByFixedConfig(entity.MapBasics.ConfID, lod)
end

function PvPTileAssetHUDIconVillage:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.VillageTransformInfo.Status.MsgPath, Delegate.GetOrCreate(self, self.OnTransformStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))
end

function PvPTileAssetHUDIconVillage:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.Owner.MsgPath, Delegate.GetOrCreate(self, self.OnOwnerChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.VillageTransformInfo.Status.MsgPath, Delegate.GetOrCreate(self, self.OnTransformStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.MapStates.StateWrapper2.CreepInfected.MsgPath, Delegate.GetOrCreate(self, self.OnCreepInfectedChanged))
end

function PvPTileAssetHUDIconVillage:OnRefresh(entity)
    ---@type wds.Village
    local villageEntity = entity
    local isCreepInfected = KingdomMapUtils.IsMapEntityCreepInfected(villageEntity)
	local isAllianceCenter = ModuleRefer.VillageModule:IsAllianceCenter(villageEntity)
    local icon = ModuleRefer.VillageModule:GetVillageIcon(villageEntity.Owner.AllianceID, villageEntity.Owner.PlayerID, villageEntity.MapBasics.ConfID, isAllianceCenter, isCreepInfected)
    local levelBase = ModuleRefer.VillageModule:GetVillageLevelBaseSprite(villageEntity.MapBasics.ConfID)
    local color = ModuleRefer.MapBuildingTroopModule:GetColor(villageEntity.Owner, isCreepInfected)
    local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(villageEntity)
    local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(villageEntity)
    self.behavior:SetIcon(icon)
    self.behavior:SetLevelBase(levelBase)
    self.behavior:AdjustNameLevel(name, level)
    self.behavior:SetNameColor(color)
end

---@param villageEntity wds.Village
function PvPTileAssetHUDIconVillage:OnOwnerChanged(villageEntity)
    if Utils.IsNull(self.behavior) then
        return
    end
    if villageEntity.ID == self.view.uniqueId and self.behavior then
        local isCreepInfected = KingdomMapUtils.IsMapEntityCreepInfected(villageEntity)
        local color = ModuleRefer.MapBuildingTroopModule:GetColor(villageEntity.Owner, isCreepInfected)
        local name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(villageEntity)
        local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(villageEntity)
        self.behavior:AdjustNameLevel(name, level)
        self.behavior:SetNameColor(color)
    end
end

---@param villageEntity wds.Village
function PvPTileAssetHUDIconVillage:OnCreepInfectedChanged(villageEntity)
    if Utils.IsNull(self.behavior) then
        return
    end
    if villageEntity.ID == self.view.uniqueId and self.behavior then
        self:OnRefresh(villageEntity)
    end
end

---@param villageEntity wds.Village
function PvPTileAssetHUDIconVillage:OnTransformStatusChanged(villageEntity, _)
    if Utils.IsNull(self.behavior) then
        return
    end
    if villageEntity.ID == self.view.uniqueId then
        self:OnRefresh(villageEntity)
    end
end

function PvPTileAssetHUDIconVillage:OnIconClick()
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

return PvPTileAssetHUDIconVillage
