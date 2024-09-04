local PvPTileAssetHUDConstruction = require("PvPTileAssetHUDConstruction")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityType = require('DBEntityType')

---@class PvPTileAssetHUDConstructionGate : PvPTileAssetHUDConstruction
local PvPTileAssetHUDConstructionGate = class("PvPTileAssetHUDConstructionGate", PvPTileAssetHUDConstruction)

function PvPTileAssetHUDConstructionGate:OnConstructionSetup()
    PvPTileAssetHUDConstructionGate.super.OnConstructionSetup(self)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecond))
end

function PvPTileAssetHUDConstructionGate:OnConstructionShutdown()
    PvPTileAssetHUDConstructionGate.super.OnConstructionShutdown(self)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecond))
end

function PvPTileAssetHUDConstructionGate:OnSecond()
    local entity = self:GetData()
    if not entity then
        return
    end

    local textKey, timestamp = ModuleRefer.GateModule:GetCountDown(entity, ModuleRefer.AllianceModule:GetAllianceId())
    self:RefreshStateTime(textKey, timestamp)
end

---@param entity wds.Pass
function PvPTileAssetHUDConstructionGate:OnRefresh(entity)
    local buildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)

    local durability = entity.Battle.Durability
    local maxDurability = entity.Battle.MaxDurability
    if maxDurability <= 0 then
        if buildingConfig then
            maxDurability = buildingConfig:InitialDuration()
        end
    end
    local showDurabilityText = not KingdomMapUtils.InMapMediumLod()
    self:RefreshDurability(durability, maxDurability, showDurabilityText)

    local troopCount = 0
    local myTroopCount = 0
    if entity.Army then
        troopCount = table.nums(entity.Army.PlayerTroopIDs)
        myTroopCount = ModuleRefer.MapBuildingTroopModule:GetMyTroopCount(entity.Army)
    end
    self:RefreshTroopQuantity(troopCount, myTroopCount)

    self:RefreshAllianceLogo(entity.Owner.AllianceBadgeAppearance, entity.Owner.AllianceBadgePattern)

    local textKey, timestamp = ModuleRefer.GateModule:GetCountDown(entity, ModuleRefer.AllianceModule:GetAllianceId())
    self:RefreshStateTime(textKey, timestamp)
end

return PvPTileAssetHUDConstructionGate
