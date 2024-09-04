local PvPTileAssetUnit = require("PvPTileAssetUnit")

---@class PvPTileAssetMobileFortress : PvPTileAssetUnit
local PvPTileAssetMobileFortress = class("PvPTileAssetMobileFortress", PvPTileAssetUnit)

---@return string
function PvPTileAssetMobileFortress:GetLodPrefabName(lod)
    return string.Empty
end

return PvPTileAssetMobileFortress