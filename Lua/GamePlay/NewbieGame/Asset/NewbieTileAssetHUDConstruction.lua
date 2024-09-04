local MapTileAssetUnit = require("MapTileAssetUnit")
local PvPTileAssetHUDConstruction = require("PvPTileAssetHUDConstruction")
local NewbieTileAssetHUDConstruction = class("NewbieTileAssetHUDConstruction", PvPTileAssetHUDConstruction)

function NewbieTileAssetHUDConstruction:OnLodChanged(oldLod, newLod)
    MapTileAssetUnit.OnLodChanged(self, oldLod, newLod)
end

return NewbieTileAssetHUDConstruction