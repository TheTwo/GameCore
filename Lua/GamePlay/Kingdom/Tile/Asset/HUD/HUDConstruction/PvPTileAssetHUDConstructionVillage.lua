local PvPTileAssetHUDConstruction = require("PvPTileAssetHUDConstruction")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ManualResourceConst = require("ManualResourceConst")
local DBEntityPath = require("DBEntityPath")

---@class PvPTileAssetHUDConstructionVillage : PvPTileAssetHUDConstruction
---@field stateTimeChanged boolean
local PvPTileAssetHUDConstructionVillage = class("PvPTileAssetHUDConstructionVillage", PvPTileAssetHUDConstruction)

function PvPTileAssetHUDConstruction:AutoRefresh()
    return false
end

function PvPTileAssetHUDConstructionVillage:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.Battle.Durability.MsgPath, Delegate.GetOrCreate(self, self.OnDurabilityChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
end

function PvPTileAssetHUDConstructionVillage:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.Battle.Durability.MsgPath, Delegate.GetOrCreate(self, self.OnDurabilityChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
end

function PvPTileAssetHUDConstructionVillage:OnConstructionSetup()
    PvPTileAssetHUDConstructionVillage.super.OnConstructionSetup(self)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecond))
end

function PvPTileAssetHUDConstructionVillage:OnConstructionShutdown()
    PvPTileAssetHUDConstructionVillage.super.OnConstructionShutdown(self)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecond))
end

function PvPTileAssetHUDConstructionVillage:OnSecond()
    local entity = self:GetData()
    if not entity then
        return
    end

    if self.stateTimeChanged then
        local buildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
        self:RefreshVillageDurability(entity, buildingConfig)
        self:RefreshVillageStateTime(entity)
        self.stateTimeChanged = false
    end
end

function PvPTileAssetHUDConstructionVillage:OnArmyChanged()
    local entity = self:GetData()
    if not entity then
        return
    end
    
    local troopCount = 0
    local myTroopCount = 0
    if entity.Army then
        troopCount = table.nums(entity.Army.PlayerTroopIDs)
        myTroopCount = ModuleRefer.MapBuildingTroopModule:GetMyTroopCount(entity.Army)
    end
    self:RefreshTroopQuantity(troopCount, myTroopCount)
end

function PvPTileAssetHUDConstructionVillage:OnDurabilityChanged()
    self.stateTimeChanged = true
end

---@param buildingConfig FixedMapBuildingConfigCell
---@param entity wds.Village
function PvPTileAssetHUDConstructionVillage:RefreshVillageDurability(entity, buildingConfig)
    local showDurabilityText = not KingdomMapUtils.InSymbolMapLod()
    if entity.VillageTransformInfo.Status == wds.VillageTransformStatus.VillageTransformStatusProcessing then
        local v,targetV,_ = ModuleRefer.VillageModule:GetGetTransformToAllianceCenterBuildProgress(entity)
        self:RefreshDurability(math.floor(v + 0.5), math.floor(targetV + 0.5), showDurabilityText)
    elseif ModuleRefer.VillageModule:IsVillageRuinRebuilding(entity) then
        local durability = entity.Battle.Durability
        local maxDurability = entity.Battle.MaxDurability
        if maxDurability <= 0 then
            if buildingConfig then
                maxDurability = buildingConfig:InitialDuration()
            end
        end
        local color = ModuleRefer.PlayerModule:IsFriendlyById(entity.BuildingRuinRebuild.AllianceId)
                and ModuleRefer.MapHUDModule.colorFriendly
                or ModuleRefer.MapHUDModule.colorHostile
        self:RefreshDurability(durability, maxDurability, showDurabilityText, color)
    else
        local durability = entity.Battle.Durability
        local maxDurability = entity.Battle.MaxDurability
        if maxDurability <= 0 then
            if buildingConfig then
                maxDurability = buildingConfig:InitialDuration()
            end
        end
        self:RefreshDurability(durability, maxDurability, showDurabilityText)
    end
end

---@param entity wds.Village
function PvPTileAssetHUDConstructionVillage:RefreshVillageStateTime(entity)
    if ModuleRefer.VillageModule:IsVillageRuinRebuilding(entity) then
        local textKey, timestamp = ModuleRefer.VillageModule:GetVillageCountDown(entity, ModuleRefer.AllianceModule:GetAllianceId())
        local icon = ManualResourceConst.sp_comp_icon_build
        self:RefreshStateTime(textKey, timestamp, icon)
    else
        local textKey, timestamp = ModuleRefer.VillageModule:GetVillageCountDown(entity, ModuleRefer.AllianceModule:GetAllianceId())
        local icon = ManualResourceConst.sp_common_icon_time_01
        self:RefreshStateTime(textKey, timestamp, icon)
    end
end


return PvPTileAssetHUDConstructionVillage
