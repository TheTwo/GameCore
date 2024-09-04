local PvPTileAssetLandmark = require("PvPTileAssetLandmark")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local EventConst = require("EventConst")

---@class PvPTileAssetBridge : PvPTileAssetLandmark
local PvPTileAssetBridge = class("PvPTileAssetBridge", PvPTileAssetLandmark)

function PvPTileAssetBridge:GetLodPrefab(lod)
    if not KingdomMapUtils.InSymbolMapLod(lod) then
        local instanceID = self.view.uniqueId
        local idStart, idEnd, _ = self.view.staticMapData:GetBridgeRoadData(instanceID)
        local instance, asset = self.view.staticMapData:GetDecorationInstance(instanceID)
        self.position, self.rotation, self.scale = instance:GetTransform()
        if ModuleRefer.RoadModule:BridgeHasCreep(idStart, idEnd) then
            return asset.PrefabName .. "_creep"
        end
        return asset.PrefabName
    end
    return string.Empty
end

function PvPTileAssetBridge:OnConstructionSetup()
    g_Game.EventManager:AddListener(EventConst.TERRITORY_OCCUPY_CHANGED, Delegate.GetOrCreate(self, self.OnTerritoryOccupyChanged))
end

function PvPTileAssetBridge:OnConstructionShutdown()
    g_Game.EventManager:RemoveListener(EventConst.TERRITORY_OCCUPY_CHANGED, Delegate.GetOrCreate(self, self.OnTerritoryOccupyChanged))
end

function PvPTileAssetBridge:OnTerritoryOccupyChanged()
    self:Refresh()
end

return PvPTileAssetBridge