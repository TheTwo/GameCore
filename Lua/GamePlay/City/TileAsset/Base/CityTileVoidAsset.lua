local CityTileAsset = require("CityTileAsset")
---@class CityTileVoidAsset:CityTileAsset @没有实体的Asset, 接受TileView的管理控制Show和Hide
---@field new fun():CityTileVoidAsset
local CityTileVoidAsset = class("CityTileVoidAsset", CityTileAsset)

function CityTileVoidAsset:Show()
    ---override this
end

function CityTileVoidAsset:Hide()
    ---override this
end

return CityTileVoidAsset