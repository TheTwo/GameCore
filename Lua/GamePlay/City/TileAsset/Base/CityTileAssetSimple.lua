local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetSimple:CityTileAsset
---@field new fun():CityTileAssetSimple
local CityTileAssetSimple = class("CityTileAssetSimple", CityTileAsset)

function CityTileAssetSimple:ctor(prefabName)
    CityTileAssetSimple.super.ctor(self)
    self.prefabName = prefabName
end

function CityTileAssetSimple:GetPrefabName()
    return self.prefabName
end

return CityTileAssetSimple