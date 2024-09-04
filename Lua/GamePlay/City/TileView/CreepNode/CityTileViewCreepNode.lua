local CityTileView = require("CityTileView")
---@class CityTileViewCreepNode:CityTileView
---@field new fun():CityTileViewCreepNode
local CityTileViewCreepNode = class("CityTileViewCreepNode", CityTileView)
local CityTileAssetCreepNode = require("CityTileAssetCreepNode")

function CityTileViewCreepNode:ctor()
    CityTileView.ctor(self)
    self:AddMainAsset(CityTileAssetCreepNode.new())
end

return CityTileViewCreepNode