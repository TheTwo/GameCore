local MapTileView = require("MapTileView")
local PvPTileAssetResourceField = require("PvPTileAssetResourceField")
local PvPTileAssetHUDIconResourceField = require("PvPTileAssetHUDIconResourceField")
local PvPTileAssetResourceFieldTroopHead = require("PvPTileAssetResourceFieldTroopHead")
--local PvETileAssetHudResourceFieldBar = require("PvETileAssetHudResourceFieldBar")
local PvPTileAssetResourceFieldStatus = require("PvPTileAssetResourceFieldStatus")

---@class PvPTileViewResourceField : MapTileView
local PvPTileViewResourceField = class("PvPTileViewResourceField", MapTileView)

function PvPTileViewResourceField:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvPTileAssetResourceField.new())
    self:AddAsset(PvPTileAssetHUDIconResourceField.new())
    self:AddAsset(PvPTileAssetResourceFieldTroopHead.new())
    --self:AddAsset(PvETileAssetHudResourceFieldBar.new())
    self:AddAsset(PvPTileAssetResourceFieldStatus.new())
end

return PvPTileViewResourceField