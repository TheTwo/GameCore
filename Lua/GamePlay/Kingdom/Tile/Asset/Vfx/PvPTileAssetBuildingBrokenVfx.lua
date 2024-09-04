local MapTileAssetSolo = require("MapTileAssetSolo")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local MapTileAssetUnit = require("MapTileAssetUnit")
local ManualResourceConst = require("ManualResourceConst")

local Vector3 = CS.UnityEngine.Vector3
local Quaternion = CS.UnityEngine.Quaternion

---@class PvPTileAssetBuildingBrokenVfx : MapTileAssetUnit
local PvPTileAssetBuildingBrokenVfx = class("PvPTileAssetBuildingBrokenVfx", MapTileAssetUnit)

function PvPTileAssetBuildingBrokenVfx:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        ---@type wds.EnergyTower
        local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
        if entity and ModuleRefer.KingdomConstructionModule:IsBuildingBroken(entity) then
            return ManualResourceConst.fx_building_broken
        end
    end
    return string.Empty
end

function PvPTileAssetBuildingBrokenVfx:GetPosition()
    --for test
    return self:CalculateCenterPosition() + Vector3.up * 50
end

function PvPTileAssetBuildingBrokenVfx:GetRotation()
    --for test
    return Quaternion.Euler(Vector3(270,0,0))
end

function PvPTileAssetBuildingBrokenVfx:GetScale()
    --for test
    return Vector3.one * 80
end

return PvPTileAssetBuildingBrokenVfx