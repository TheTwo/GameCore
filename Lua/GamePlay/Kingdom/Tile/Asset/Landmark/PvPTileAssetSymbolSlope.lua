local PvPTileAssetLandmark = require("PvPTileAssetLandmark")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ManualResourceConst = require("ManualResourceConst")

---@class PvPTileAssetSymbolSlope : PvPTileAssetLandmark
local PvPTileAssetSymbolSlope = class("PvPTileAssetSymbolSlope", PvPTileAssetLandmark)
local PrefabName = ManualResourceConst.mdl_world_uientrance_01

function PvPTileAssetSymbolSlope:GetLodPrefab(lod)
    if KingdomMapUtils.InSymbolMapDetailLod(lod) then
        local instanceID = self.view.uniqueId
        --local idStart, idEnd, level = self.view.staticMapData:GetBridgeRoadData(instanceID)
        local instance, asset = self.view.staticMapData:GetDecorationInstance(instanceID)
        self.position, self.rotation, _ = instance:GetTransform()
        --if ModuleRefer.RoadModule:BridgeHasCreep(idStart, idEnd) then
        --    return asset.PrefabName .. "_creep"
        --end
        --return asset.PrefabName
        
        return PrefabName
        
    end
    return string.Empty
end

return PvPTileAssetSymbolSlope