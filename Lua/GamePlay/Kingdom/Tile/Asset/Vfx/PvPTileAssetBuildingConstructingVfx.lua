local MapTileAssetSolo = require("MapTileAssetSolo")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local MapTileAssetUnit = require("MapTileAssetUnit")
local ManualResourceConst = require("ManualResourceConst")

local Vector3 = CS.UnityEngine.Vector3

---@class PvPTileAssetBuildingConstructingVfx : MapTileAssetUnit
local PvPTileAssetBuildingConstructingVfx = class("PvPTileAssetBuildingConstructingVfx", MapTileAssetUnit)

function PvPTileAssetBuildingConstructingVfx:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
        if entity and ModuleRefer.KingdomConstructionModule:IsBuildingConstructing(entity) then
            return ManualResourceConst.vfx_common_base_process
        end
    end
    return string.Empty
end

function PvPTileAssetBuildingConstructingVfx:GetPosition()
    return self:CalculateCenterPosition()
end

return PvPTileAssetBuildingConstructingVfx