local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetDefenseTowerCircle:CityTileAsset
---@field new fun():CityTileAssetDefenseTowerCircle
local CityTileAssetDefenseTowerCircle = class("CityTileAssetDefenseTowerCircle", CityTileAsset)
local ConfigRefer = require("ConfigRefer")
local ManualResourceConst = require("ManualResourceConst")
local Utils = require("Utils")

function CityTileAssetDefenseTowerCircle:ctor()
    CityTileAsset.ctor(self)
    self.allowSelected = true
end

function CityTileAssetDefenseTowerCircle:GetPrefabName()
    if not self.isDefenseTower then
        return string.Empty
    end
    if not self.selected then
        return string.Empty
    end
    return ManualResourceConst.prefab_test_defense_tower_circle
end

function CityTileAssetDefenseTowerCircle:OnTileViewInit()
    ---@type CityFurnitureLevelConfigCell
    local lvCfg = self.tileView.tile:GetCell().furnitureCell
    self.mapBuildingBattleCfgId = lvCfg:RelatedMapBuilding():BattleInfo()
    self.isDefenseTower = self.mapBuildingBattleCfgId > 0
end

function CityTileAssetDefenseTowerCircle:OnTileViewRelease()
    self.mapBuildingBattleCfgId = nil
    self.isDefenseTower = nil
end

function CityTileAssetDefenseTowerCircle:SetSelected(flag)
    self.selected = flag
    self:ForceRefresh()
end

function CityTileAssetDefenseTowerCircle:GetRadius()
    if self.mapBuildingBattleCfgId > 0 then
        local cfg = ConfigRefer.CityMapBuildingBattle:Find(self.mapBuildingBattleCfgId)
        if cfg == nil then return 1 end
        local aiCfg = ConfigRefer.AiBase:Find(cfg:BaseAi())
        if aiCfg == nil then return 1 end
        return aiCfg:AlertRadius()
    end
    return 1
end

function CityTileAssetDefenseTowerCircle:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end
    
    local behaviour = go:GetLuaBehaviour("PvPTileAssetCircleRangeBehavior")
    if Utils.IsNull(go) then return end

    ---@type PvPTileAssetCircleRangeBehavior
    local range = behaviour.Instance
    range:ShowCityRange(self:GetRadius(), true)
    self.range = range
end

function CityTileAssetDefenseTowerCircle:OnAssetUnload(go)
    if self.range then
        self.range:HideRange()
        self.range = nil
    end
end

return CityTileAssetDefenseTowerCircle