local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require('KingdomMapUtils')
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")

---@class PvPTileAssetTransferTower : PvPTileAssetUnit
local PvPTileAssetTransferTower = class("PvPTileAssetTransferTower", PvPTileAssetUnit)

---@return string
function PvPTileAssetTransferTower:GetLodPrefabName(lod)
    ---@type wds.TransferTower
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

return PvPTileAssetTransferTower