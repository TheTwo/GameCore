local MapTileView = require("MapTileView")
local PvETileAssetSlgInteractor = require("PvETileAssetSlgInteractor")
local SEHudTroopMediatorDefine = require("SEHudTroopMediatorDefine")

---@class NewbieTileViewSlgInteractor : MapTileView
local NewbieTileViewSlgInteractor = class("NewbieTileViewSlgInteractor", MapTileView)

function NewbieTileViewSlgInteractor:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PvETileAssetSlgInteractor.new(SEHudTroopMediatorDefine.FromType.City, true, 20000))
end

return NewbieTileViewSlgInteractor