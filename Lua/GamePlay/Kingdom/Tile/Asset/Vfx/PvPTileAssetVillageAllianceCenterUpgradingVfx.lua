local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local KingdomMapUtils = require("KingdomMapUtils")
local ManualResourceConst = require("ManualResourceConst")

local PvPTileAssetBuildingConstructingVfx = require("PvPTileAssetBuildingConstructingVfx")

---@class PvPTileAssetVillageAllianceCenterUpgradingVfx:PvPTileAssetBuildingConstructingVfx
---@field new fun():PvPTileAssetVillageAllianceCenterUpgradingVfx
---@field super PvPTileAssetBuildingConstructingVfx
local PvPTileAssetVillageAllianceCenterUpgradingVfx = class('PvPTileAssetVillageAllianceCenterUpgradingVfx', PvPTileAssetBuildingConstructingVfx)

function PvPTileAssetVillageAllianceCenterUpgradingVfx:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
        if entity and ModuleRefer.KingdomConstructionModule:IsBuildingConstructing(entity) then
            return ManualResourceConst.vfx_common_base_process
        end
    end
    return string.Empty
end

return PvPTileAssetVillageAllianceCenterUpgradingVfx