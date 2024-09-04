local KingdomPlacingState = require("KingdomPlacingState")
local KingdomPlacingBuildingList = require("KingdomPlacingBuildingList")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityType = require("DBEntityType")
local KingdomMapUtils = require("KingdomMapUtils")

---@class KingdomPlacingStateBehemoth : KingdomPlacingState
local KingdomPlacingStateBehemoth = class("KingdomPlacingStateBehemoth", KingdomPlacingState)

function KingdomPlacingStateBehemoth:OnStart()
    for _, type in ipairs(KingdomPlacingBuildingList) do
        g_Game.DatabaseManager:AddEntityNewByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
        g_Game.DatabaseManager:AddEntityDestroyByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
    end
end

function KingdomPlacingStateBehemoth:OnEnd()
    for _, type in ipairs(KingdomPlacingBuildingList) do
        g_Game.DatabaseManager:RemoveEntityNewByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
        g_Game.DatabaseManager:RemoveEntityDestroyByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
    end
end

function KingdomPlacingStateBehemoth:OnPlace()
end

function KingdomPlacingStateBehemoth:IsDirty()
    return self.buildingEntityChanged
end

function KingdomPlacingStateBehemoth:SetGridData(gridMeshManager, territoryYesList, territoryNoList, rectYesList, rectNoList, circleYesList, circleNoList)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    
    gridMeshManager:SetInitStatus(false)

    territoryYesList:Clear()
    circleYesList:Clear()
    rectNoList:Clear()
    
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if allianceData then
        local villages = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Village)
        ---@param village wds.Village
        for _, village in ipairs(villages) do
            if village.Owner.AllianceID == allianceData.ID then
                local territoryID = village.Village.VID
                territoryYesList:Add(territoryID)
            end
        end
        gridMeshManager:SetTerritories(territoryYesList, true)

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
        gridMeshManager:SetCircles(circleYesList, true)
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
    gridMeshManager:SetRects(rectNoList, false)
    
    gridMeshManager:RefreshData()
    self.buildingEntityChanged = false
end

function KingdomPlacingStateBehemoth:OnBuildingChanged()
    self.buildingEntityChanged = true
end

return KingdomPlacingStateBehemoth