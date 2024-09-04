local KingdomPlacingState = require("KingdomPlacingState")
local KingdomPlacingBuildingList = require("KingdomPlacingBuildingList")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityType = require("DBEntityType")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityPath = require("DBEntityPath")

---@class KingdomPlacingStateAllianceBuilding : KingdomPlacingState
local KingdomPlacingStateAllianceBuilding = class("KingdomPlacingStateAllianceBuilding", KingdomPlacingState)

---@param context FlexibleMapBuildingConfigCell
function KingdomPlacingStateAllianceBuilding:SetContext(context)
    self.toPlaceBuilding = context
    self.isAllianceCenterTerritoryOnly = self.toPlaceBuilding:AllianceCenterTerritoryOnly()
end

function KingdomPlacingStateAllianceBuilding:OnStart()
    for _, type in ipairs(KingdomPlacingBuildingList) do
        g_Game.DatabaseManager:AddEntityNewByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
        g_Game.DatabaseManager:AddEntityDestroyByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.VillageTransformInfo.Status.MsgPath, Delegate.GetOrCreate(self, self.OnKingdomVillageTransformStatusChanged))
end

function KingdomPlacingStateAllianceBuilding:OnEnd()
    for _, type in ipairs(KingdomPlacingBuildingList) do
        g_Game.DatabaseManager:RemoveEntityNewByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
        g_Game.DatabaseManager:RemoveEntityDestroyByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
    end
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.VillageTransformInfo.Status.MsgPath, Delegate.GetOrCreate(self, self.OnKingdomVillageTransformStatusChanged))
end

function KingdomPlacingStateAllianceBuilding:OnPlace()
end

function KingdomPlacingStateAllianceBuilding:IsDirty()
    return self.buildingEntityChanged
end

function KingdomPlacingStateAllianceBuilding:SetGridData(gridMeshManager, territoryYesList, territoryNoList, rectYesList, rectNoList, circleYesList, circleNoList)
    local staticMapData = KingdomMapUtils.GetStaticMapData()

    gridMeshManager:SetInitStatus(false)

    territoryYesList:Clear()
    rectNoList:Clear()
    circleYesList:Clear()

    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if allianceData then
        local villages = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Village)
        ---@param village wds.Village
        for _, village in ipairs(villages) do
            if village.Owner.AllianceID == allianceData.ID then
                if self.isAllianceCenterTerritoryOnly and village.VillageTransformInfo.Status ~= wds.VillageTransformStatus.VillageTransformStatusDone then
                    goto continue_village_range
                end
                local territoryID = village.Village.VID
                territoryYesList:Add(territoryID)
                ::continue_village_range::
            end
        end

        if not self.isAllianceCenterTerritoryOnly then
            local energyTowers = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.EnergyTower)
            ---@param energyTower wds.EnergyTower
            for _, energyTower in ipairs(energyTowers) do
                if energyTower.Owner.AllianceID == allianceData.ID then
                    local buildingConfig = ModuleRefer.MapBuildingTroopModule:GetBuildingConfig(energyTower.MapBasics.ConfID)
                    if buildingConfig then
                        self:FillCircle(circleYesList, energyTower.MapBasics.Position, buildingConfig:EffectRaid(), staticMapData)
                    end
                end
            end
        end
    end

    for _, typeId in ipairs(KingdomPlacingBuildingList) do
        local entities = g_Game.DatabaseManager:GetEntitiesByType(typeId)
        ---@param entity wds.EnergyTower
        for _, entity in ipairs(entities) do
            local layoutConfigId = entity.MapBasics.LayoutCfgId
            local positionX, positionY = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
            local sizeX, sizeY, margin = KingdomMapUtils.GetLayoutSize(layoutConfigId)
            local buildingConfig = ModuleRefer.MapBuildingTroopModule:GetBuildingConfig(entity.MapBasics.ConfID)
            if buildingConfig then
                self:FillBuildingRect(rectNoList, positionX, positionY, sizeX, sizeY, margin)
            end
        end
    end

    gridMeshManager:SetTerritories(territoryYesList, true)
    gridMeshManager:SetRects(rectNoList, false)
    gridMeshManager:SetCircles(circleYesList, true)
    gridMeshManager:RefreshData()

    self.buildingEntityChanged = false
end

function KingdomPlacingStateAllianceBuilding:OnKingdomVillageTransformStatusChanged()
    if not self.isAllianceCenterTerritoryOnly then return end
    self.buildingEntityChanged = true
end

function KingdomPlacingStateAllianceBuilding:OnBuildingChanged()
    self.buildingEntityChanged = true
end

return KingdomPlacingStateAllianceBuilding