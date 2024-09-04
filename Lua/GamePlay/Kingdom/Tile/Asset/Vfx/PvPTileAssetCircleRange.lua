local Vector3 = CS.UnityEngine.Vector3

local MapTileAssetSolo = require("MapTileAssetSolo")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local DBEntityType = require("DBEntityType")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local MapTileAssetUnit = require("MapTileAssetUnit")
local ManualResourceConst = require("ManualResourceConst")

---@class PvPTileAssetCircleRange : MapTileAssetUnit
---@field isSelected boolean
local PvPTileAssetCircleRange = class("PvPTileAssetCircleRange", MapTileAssetUnit)

function PvPTileAssetCircleRange:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        return PvPTileAssetCircleRange.RangePrefabTable[self.view.typeId] or string.Empty
    end
    return string.Empty
end

function PvPTileAssetCircleRange:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetCircleRange:OnConstructionSetup()
    self:UpdateRange()
    KingdomMapUtils.DirtyMapMark()

    g_Game.EventManager:AddListener(EventConst.MAP_SELECT_BUILDING, Delegate.GetOrCreate(self, self.OnSelected))
    g_Game.EventManager:AddListener(EventConst.MAP_UNSELECT_BUILDING, Delegate.GetOrCreate(self, self.OnUnselected))
end

function PvPTileAssetCircleRange:OnConstructionUpdate()
    self:UpdateRange()
end

function PvPTileAssetCircleRange:OnConstructionShutdown()
    g_Game.EventManager:RemoveListener(EventConst.MAP_SELECT_BUILDING, Delegate.GetOrCreate(self, self.OnSelected))
    g_Game.EventManager:RemoveListener(EventConst.MAP_UNSELECT_BUILDING, Delegate.GetOrCreate(self, self.OnUnselected))
    self.isSelected = false
end

function PvPTileAssetCircleRange:OnSelected(entity)
    if entity == nil then
        return
    end

    if entity.ID == self.view:GetUniqueId() then
        self.isSelected = true
        self:UpdateRange()
    end
end

function PvPTileAssetCircleRange:OnUnselected(entity)
    if entity == nil then
        return
    end
    
    if entity.ID == self.view:GetUniqueId() then
        self.isSelected = false
        self:UpdateRange()
    end
end

function PvPTileAssetCircleRange:UpdateRange()
    ---@type wds.EnergyTower
    local towerEntity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not towerEntity then
        return
    end
    local towerConfig = ConfigRefer.FlexibleMapBuilding:Find(towerEntity.BasicInfo.ConfID)
    if not towerConfig then
        return
    end
    
    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        return
    end

    ---@type PvPTileAssetCircleRangeBehavior
    local behavior = asset:GetLuaBehaviour("PvPTileAssetCircleRangeBehavior").Instance
    
    local isPlacing = ModuleRefer.KingdomPlacingModule:IsPlacing()
    local targetBuildingConfig = ModuleRefer.KingdomPlacingModule:GetPlacingBuildingConfig()
    local isMyBuilding = ModuleRefer.KingdomConstructionModule:IsBuildingSameAlliance(towerEntity.Owner)
    if isPlacing and isMyBuilding and targetBuildingConfig:Type() == towerConfig:Type() then
        local spaceLimit = towerConfig:SpaceLimit()
        behavior:ShowRange(spaceLimit, self.view.staticMapData, false)
    elseif self.isSelected then
        local radius = towerConfig:EffectRaid()
        behavior:ShowRange(radius, self.view.staticMapData, true)
    else
        behavior:HideRange()
    end
end

PvPTileAssetCircleRange.RangePrefabTable =
{
    [DBEntityType.EnergyTower] = ManualResourceConst.prefab_test_defense_tower_circle,
    [DBEntityType.DefenceTower] = ManualResourceConst.prefab_test_defense_tower_circle,
}

return PvPTileAssetCircleRange