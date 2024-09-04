local MapTileAssetUnit = require("MapTileAssetUnit")
local KingdomMapUtils = require('KingdomMapUtils')

---@class NewbieTileAssetCity : MapTileAssetUnit
local NewbieTileAssetCity = class("NewbieTileAssetCity", MapTileAssetUnit)

---@return string
function NewbieTileAssetCity:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        return "mdl_b_castle_01"
    end
    return string.Empty
end

return NewbieTileAssetCity