local MapTileView = require("MapTileView")
local PlayerTileAssetSlgInteractor = require("PlayerTileAssetSlgInteractor")
local PlayerTileAssetSlgInteractorHUD = require("PlayerTileAssetSlgInteractorHUD")

---@class PlayerTileViewSlgInteractor : MapTileView
local PlayerTileViewSlgInteractor = class("PlayerTileViewSlgInteractor", MapTileView)

function PlayerTileViewSlgInteractor:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PlayerTileAssetSlgInteractor.new())
    self:AddAsset(PlayerTileAssetSlgInteractorHUD.new())
end

return PlayerTileViewSlgInteractor