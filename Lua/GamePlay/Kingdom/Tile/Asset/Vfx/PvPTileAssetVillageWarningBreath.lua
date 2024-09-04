local MapTileAssetUnit = require("MapTileAssetUnit")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ManualResourceConst = require("ManualResourceConst")

---@class PvPTileAssetVillageWarningBreath : MapTileAssetUnit
local PvPTileAssetVillageWarningBreath = class("PvPTileAssetVillageWarningBreath", MapTileAssetUnit)

function PvPTileAssetVillageWarningBreath:GetLodPrefabName(lod)
    local data = self:GetData()
    if not data then
        return string.Empty
    end
    
    if KingdomMapUtils.InSymbolMapDetailLod(lod) and KingdomMapUtils.IsMapEntityCreepInfected(data) then
        return ManualResourceConst.WarnDecal
    end
    return string.Empty
end

function PvPTileAssetVillageWarningBreath:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetVillageWarningBreath:GetScale()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayoutByEntity(entity)
    return math.max(layout.SizeX, layout.SizeY, 1)  * CS.UnityEngine.Vector3.one
end

return PvPTileAssetVillageWarningBreath