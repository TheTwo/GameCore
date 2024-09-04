local CityTileView = require("CityTileView")
---@class CityTileViewResource:CityTileView
---@field new fun():CityTileViewResource
local CityTileViewResource = class("CityTileViewResource", CityTileView)
local CityTileAssetResource = require("CityTileAssetResource")
local CityTileAssetViewVisibleModifier = require("CityTileAssetViewVisibleModifier")
local CityTileAssetBubbleResourceCollectedByCitizen = require("CityTileAssetBubbleResourceCollectedByCitizen")
local CityTileAssetResourceUnloadVfx = require("CityTileAssetResourceUnloadVfx")

function CityTileViewResource:ctor()
    CityTileView.ctor(self)
    self:AddMainAsset(CityTileAssetResource.new())
    self:AddAsset(CityTileAssetViewVisibleModifier.new())
    self:AddAsset(CityTileAssetBubbleResourceCollectedByCitizen.new())
    self:AddAsset(CityTileAssetResourceUnloadVfx.new())
end

function CityTileViewResource:ToString()
    local cell = self.tile:GetCell()
    return ("[Resource: cfg:%d]"):format(cell.configId)
end

return CityTileViewResource