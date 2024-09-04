local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local CityStaticObjectTile = require("CityStaticObjectTile")
local ArtResourceUtils = require("ArtResourceUtils")

---@class CityStaticObjectTileSpawnerRangeCircle:CityStaticObjectTile
---@field new fun(gridView:CityGridView, spawner:CityElementSpawner):CityStaticObjectTileSpawnerRangeCircle
---@field super CityStaticObjectTile
local CityStaticObjectTileSpawnerRangeCircle = class('CityStaticObjectTileSpawnerRangeCircle', CityStaticObjectTile)

---@param gridView CityGridView
---@param spawner CityElementSpawner
function CityStaticObjectTileSpawnerRangeCircle:ctor(gridView, spawner)
    self.eleSpawner = spawner
    self.circleAsset = "vfx_Common_tuozhanquan"
    self.circleAssetScale = 1
    local config = ConfigRefer.CityElementSpawner:Find(spawner.configId)
    local assetId = config and config:RangeCircleAsset() or 0
    if assetId ~= 0 then
        self.circleAsset, self.circleAssetScale = ArtResourceUtils.GetItemAndScale(config:RangeCircleAsset())
    end
    CityStaticObjectTileSpawnerRangeCircle.super.ctor(self, gridView, spawner.x, spawner.y, 1, 1, self.circleAsset)
    self.cityUid = gridView.city.uid
end

---@param go CS.UnityEngine.GameObject
function CityStaticObjectTileSpawnerRangeCircle:OnAssetLoaded(go, userdata)
    CityStaticObjectTile.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    go:SetLayerRecursively("City", true)
    local trans = go.transform
    trans.localScale = CS.UnityEngine.Vector3.one * self.circleAssetScale
    local p = trans.localPosition
    p.y = p.y + 0.1
    trans.localPosition = p
end

return CityStaticObjectTileSpawnerRangeCircle