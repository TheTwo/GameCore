local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local MapTileAssetUnit = require("MapTileAssetUnit")
local NewbieTileAssetHUDIcon = class("NewbieTileAssetHUDIcon", PvPTileAssetHUDIcon)

function NewbieTileAssetHUDIcon:OnLodChanged(oldLod, newLod)
    MapTileAssetUnit.OnLodChanged(self, oldLod, newLod)
end

return NewbieTileAssetHUDIcon