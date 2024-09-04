local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require('KingdomMapUtils')
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Delegate = require("Delegate")

---@class PvPTileAssetEnergyTower : PvPTileAssetUnit
---@field super PvPTileAssetUnit
local PvPTileAssetEnergyTower = class("PvPTileAssetEnergyTower", PvPTileAssetUnit)

function PvPTileAssetEnergyTower:ctor()
    PvPTileAssetEnergyTower.super.ctor(self)
    ---@type MapUITrigger
    self._touchTrigger = nil
end

---@return string
function PvPTileAssetEnergyTower:GetLodPrefabName(lod)
    ---@type wds.EnergyTower
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end
    local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    if not KingdomMapUtils.CheckIsEnterOrHigherIconLodFlexible(entity.MapBasics.ConfID, lod) then
        if entity.Construction.Status == wds.BuildingConstructionStatus.BuildingConstructionStatusProcessing then
            return ArtResourceUtils.GetItem(buildingConfig:InConstructionModel())
        else
            return ArtResourceUtils.GetItem(buildingConfig:Model())
        end
    end
    return string.Empty
end

function PvPTileAssetEnergyTower:OnConstructionSetup()
    PvPTileAssetEnergyTower.super.OnConstructionSetup(self)
    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        return
    end
    local trigger = asset:GetLuaBehaviourInChildren("MapUITrigger", true)
    if Utils.IsNull(trigger) then
        return
    end
    self._touchTrigger = trigger.Instance
    if self._touchTrigger then
        self._touchTrigger:SetTrigger(Delegate.GetOrCreate(self, self.OnClickSelfTrigger))
    end
end

function PvPTileAssetEnergyTower:OnConstructionShutdown()
    if self._touchTrigger then
        self._touchTrigger:SetTrigger(nil)
    end
    self._touchTrigger = nil
end

function PvPTileAssetEnergyTower:OnClickSelfTrigger()
    local x, y = self:GetServerPosition()
    if x <= 0 or y <= 0 then
        return
    end
    local scene = KingdomMapUtils.GetKingdomScene()
    local coord = CS.DragonReborn.Vector2Short(math.floor(x + 0.5), math.floor(y + 0.5))
    scene.mediator:ChooseCoordTile(coord)
end

return PvPTileAssetEnergyTower