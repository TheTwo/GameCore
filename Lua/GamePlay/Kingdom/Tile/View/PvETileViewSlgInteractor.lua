local MapTileView = require("MapTileView")
local PvETileAssetSlgInteractor = require("PvETileAssetSlgInteractor")
local SEHudTroopMediatorDefine = require("SEHudTroopMediatorDefine")
local PvPTileAssetHUDIconSlgInteractor = require("PvPTileAssetHUDIconSlgInteractor")
local PvPTileAssetSlgInteractorRadarBubble = require("PvPTileAssetSlgInteractorRadarBubble")
---@class PvETileViewSlgInteractor : MapTileView
local PvETileViewSlgInteractor = class("PvETileViewSlgInteractor", MapTileView)

function PvETileViewSlgInteractor:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvETileAssetSlgInteractor.new(SEHudTroopMediatorDefine.FromType.World, false, 0))
    -- self:AddAsset(PvPTileAssetHUDIconSlgInteractor.new())
    self:AddAsset(PvPTileAssetSlgInteractorRadarBubble.new())
end

return PvETileViewSlgInteractor