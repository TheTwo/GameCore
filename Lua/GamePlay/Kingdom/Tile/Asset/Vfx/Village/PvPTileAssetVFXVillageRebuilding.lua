local PvPTileAssetUnit = require("PvPTileAssetUnit")
local ModuleRefer = require("ModuleRefer")
local ManualResourceConst = require("ManualResourceConst")
local KingdomMapUtils = require("KingdomMapUtils")

---@class PvPTileAssetVFXVillageRebuilding : PvPTileAssetUnit
local PvPTileAssetVFXVillageRebuilding = class("PvPTileAssetVFXVillageRebuilding", PvPTileAssetUnit)

function PvPTileAssetVFXVillageRebuilding:GetLodPrefab(lod)
    PvPTileAssetVFXVillageRebuilding.super.GetLodPrefab(self, lod)
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end

    if not KingdomMapUtils.CheckIsEnterOrHigherIconLodFixed(entity.MapBasics.ConfID, lod) then
        if ModuleRefer.VillageModule:IsVillageRuinRebuilding(entity) then
            return ManualResourceConst.vfx_w_slg_building
        end
    end
    return string.Empty
end


return PvPTileAssetVFXVillageRebuilding