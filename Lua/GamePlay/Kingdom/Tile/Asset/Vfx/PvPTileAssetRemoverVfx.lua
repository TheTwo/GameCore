local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

local One = CS.UnityEngine.Vector3.one

---@class PvPTileAssetRemoverVfx : PvPTileAssetUnit
local PvPTileAssetRemoverVfx = class("PvPTileAssetRemoverVfx", PvPTileAssetUnit)

---@return string
function PvPTileAssetRemoverVfx:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        return ManualResourceConst.vfx_bigmap_xiaoshatongzhiwu01
    end
    return string.Empty
end

function PvPTileAssetRemoverVfx:GetScale()
    return 10 * One
end

function PvPTileAssetRemoverVfx:OnConstructionSetup()
    ---@type wds.SlgCreepTumorRemoverBuilding
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    local vfx = self.handle.Asset
    if Utils.IsNotNull(vfx) then
        local visible = ModuleRefer.MapCreepModule:IsPlacingRemover(entity.RemoverInfo)
        vfx:SetVisible(visible)
    end
end

function PvPTileAssetRemoverVfx:OnConstructionShutdown()
    ---@type wds.SlgCreepTumorRemoverBuilding
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end
    ModuleRefer.MapCreepModule:ClearPlacingRemover(entity.RemoverInfo)
end

return PvPTileAssetRemoverVfx