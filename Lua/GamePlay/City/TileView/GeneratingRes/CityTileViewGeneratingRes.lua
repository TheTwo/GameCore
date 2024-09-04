local CityTileView = require("CityTileView")
---@class CityTileViewGeneratingRes:CityTileView
---@field new fun():CityTileViewGeneratingRes
local CityTileViewGeneratingRes = class("CityTileViewGeneratingRes", CityTileView)
local CityTileAssetGeneratingRes = require("CityTileAssetGeneratingRes")

function CityTileViewGeneratingRes:ctor()
    CityTileView.ctor(self)
    self:AddAsset(CityTileAssetGeneratingRes.new())
end

return CityTileViewGeneratingRes