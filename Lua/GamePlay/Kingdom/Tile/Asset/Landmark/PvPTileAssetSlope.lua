local PvPTileAssetLandmark = require("PvPTileAssetLandmark")

---@class PvPTileAssetSlope : PvPTileAssetLandmark
local PvPTileAssetSlope = class("PvPTileAssetSlope", PvPTileAssetLandmark)

function PvPTileAssetSlope:OnConstructionSetup()
    local go = self.handle.Asset
    local instanceID = self.view.uniqueId
    local idStart, idEnd, level = self.view.staticMapData:GetSlopeRoadData(instanceID)
    self.view.mapSystem:RegisterSlope(go, idStart, idEnd, level)
end

function PvPTileAssetSlope:OnConstructionShutdown()
    local instanceID = self.view.uniqueId
    local idStart, idEnd, level = self.view.staticMapData:GetSlopeRoadData(instanceID)
    level = 1
    self.view.mapSystem:UnregisterSlope(idStart, idEnd, level)
end

return PvPTileAssetSlope