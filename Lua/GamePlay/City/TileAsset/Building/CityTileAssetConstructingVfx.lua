local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetConstructingVfx:CityTileAsset
---@field new fun():CityTileAssetConstructingVfx
local CityTileAssetConstructingVfx = class("CityTileAssetConstructingVfx", CityTileAsset)
local Utils = require("Utils")
local CityUtils = require("CityUtils")
local ManualResourceConst = require("ManualResourceConst")

function CityTileAssetConstructingVfx:GetPrefabName()
    if not self:ShouldShow() then
        return string.Empty
    end
    return ManualResourceConst.vfx_common_build_Box_02
end

function CityTileAssetConstructingVfx:ShouldShow()
    local building = self.tileView.tile:GetCastleBuildingInfo()
    if building == nil then return false end

    return CityUtils.IsConstruction(building.Status)
end

function CityTileAssetConstructingVfx:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then
        handle:Delete()
        return
    end

    local cell = self.tileView.tile:GetCell()
    local X = cell.sizeX * 0.1
    local Y = cell.sizeY * 0.1
    local scale = CS.UnityEngine.Vector3(X, 0.6, Y)
    local trans = go.transform
    trans:SetPositionAndRotation(self:GetCity():GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY), CS.UnityEngine.Quaternion.identity)
    trans.localScale = scale
end

return CityTileAssetConstructingVfx