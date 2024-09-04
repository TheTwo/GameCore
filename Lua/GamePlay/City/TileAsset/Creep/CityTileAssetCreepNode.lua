local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetCreepNode:CityTileAsset
---@field new fun():CityTileAssetCreepNode
local CityTileAssetCreepNode = class("CityTileAssetCreepNode", CityTileAsset)
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local ArtResourceUtils = require("ArtResourceUtils")
local Delegate = require("Delegate")

function CityTileAssetCreepNode:ctor()
    CityTileAsset.ctor(self)
    self.allowSelected = true
end

function CityTileAssetCreepNode:GetPrefabName()
    local cell = self.tileView.tile:GetCell()
    if cell == nil then
        g_Logger.Error("fatal error")
        return string.Empty
    end

    local element = ConfigRefer.CityElementData:Find(cell.configId)
    if element == nil then
        g_Logger.Error(("Can't find config row id : %d in CityElementData"):format(cell.configId))
        return string.Empty
    end

    local creepElementCell = ConfigRefer.CityElementCreep:Find(element:ElementId())
    if creepElementCell == nil then
        g_Logger.Error(("Can't find config row id : %d in CityTileAssetCreepNode"):format(element:ElementId()))
        return string.Empty
    end

    local creepManager = self:GetCity().creepManager
    local creepCfg = creepManager:GetCreepConfig(cell.configId)
    if creepCfg == nil then
        g_Logger.Error(("Can't find relative creep config, id: %d"):format(cell.configId))
        return string.Empty
    end

    local creepDB = creepManager:GetCreepDB(creepCfg:Id())
    if creepDB == nil then
        return string.Empty
    end

    local mdlId = creepElementCell:Model()
    if creepDB.Removed and creepElementCell:DyingModel() > 0 then
        mdlId = creepElementCell:DyingModel()
    end

    return ArtResourceUtils.GetItem(mdlId)
end

function CityTileAssetCreepNode:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then
        return
    end
    local collider = go:GetComponentInChildren(typeof(CS.UnityEngine.Collider))
    if Utils.IsNotNull(collider) then
        local trigger = go:AddMissingLuaBehaviour("CityTrigger")
        trigger.Instance:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickCellTile), self.tileView.tile, true)
        self.cityTrigger = trigger.Instance
    end
end

function CityTileAssetCreepNode:OnAssetUnload()
    if self.cityTrigger then
        self.cityTrigger:SetOnTrigger(nil, nil, false)
        self.cityTrigger = nil
    end
end

return CityTileAssetCreepNode