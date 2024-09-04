local KingdomPlacingState = require("KingdomPlacingState")
local KingdomPlacingBuildingList = require("KingdomPlacingBuildingList")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityType = require("DBEntityType")
local KingdomMapUtils = require("KingdomMapUtils")

---@class KingdomPlacingStateRelocate : KingdomPlacingState
local KingdomPlacingStateRelocate = class("KingdomPlacingStateRelocate", KingdomPlacingState)

function KingdomPlacingStateRelocate:OnStart()
    for _, type in ipairs(KingdomPlacingBuildingList) do
        g_Game.DatabaseManager:AddEntityNewByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
        g_Game.DatabaseManager:AddEntityDestroyByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
    end
end

function KingdomPlacingStateRelocate:OnEnd()
    for _, type in ipairs(KingdomPlacingBuildingList) do
        g_Game.DatabaseManager:RemoveEntityNewByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
        g_Game.DatabaseManager:RemoveEntityDestroyByType(type, Delegate.GetOrCreate(self, self.OnBuildingChanged))
    end
end

function KingdomPlacingStateRelocate:OnPlace()
end

function KingdomPlacingStateRelocate:IsDirty()
    return self.buildingEntityChanged
end

function KingdomPlacingStateRelocate:SetGridData(gridMeshManager, territoryYesList, territoryNoList, rectYesList, rectNoList, circleYesList, circleNoList)
    local staticMapData = KingdomMapUtils.GetStaticMapData()

    gridMeshManager:SetInitStatus(true)

    rectNoList:Clear()
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

function KingdomPlacingStateRelocate:OnBuildingChanged()
    self.buildingEntityChanged = true
end

return KingdomPlacingStateRelocate