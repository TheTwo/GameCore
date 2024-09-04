local PvPTileAssetLandmark = require("PvPTileAssetLandmark")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ManualResourceConst = require("ManualResourceConst")

local Up = CS.UnityEngine.Vector3.up

---@class PvPTileAssetSymbolBridge : PvPTileAssetLandmark
local PvPTileAssetSymbolBridge = class("PvPTileAssetSymbolBridge", PvPTileAssetLandmark)
local PrefabName = ManualResourceConst.mdl_world_uibridge_02

function PvPTileAssetSymbolBridge:GetLodPrefab(lod)
    if KingdomMapUtils.InSymbolMapLod(lod) then
        local instanceID = self.view.uniqueId
        local instance, _ = self.view.staticMapData:GetDecorationInstance(instanceID)
        self.position, self.rotation, _ = instance:GetTransform()
        self.position = self.position + Up * 30
        --if ModuleRefer.RoadModule:BridgeHasCreep(idStart, idEnd) then
        --    return asset.PrefabName .. "_creep"
        --end
        --return asset.PrefabName
        return PrefabName
    end
    return string.Empty
end

return PvPTileAssetSymbolBridge