local PvETileAssetCreepCenter = require("PvETileAssetCreepCenter")

local MapTileView = require("MapTileView")

---@class PvETileViewCreepCenter:MapTileView
---@field new fun():PvETileViewCreepCenter
---@field super MapTileView
local PvETileViewCreepCenter = class('PvETileViewCreepCenter', MapTileView)

function PvETileViewCreepCenter:ctor()
    PvETileViewCreepCenter.super.ctor(self)
    self:AddAsset(PvETileAssetCreepCenter.new())
end

return PvETileViewCreepCenter