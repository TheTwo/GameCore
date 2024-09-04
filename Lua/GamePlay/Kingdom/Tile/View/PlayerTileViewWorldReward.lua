local MapTileView = require("MapTileView")
local PlayerTileAssetWorldReward = require("PlayerTileAssetWorldReward")
local PlayerTileAssetWorldRewardHUD = require("PlayerTileAssetWorldRewardHUD")

---@class PlayerTileViewWorldReward : MapTileView
local PlayerTileViewWorldReward = class("PlayerTileViewWorldReward", MapTileView)

function PlayerTileViewWorldReward:ctor()
    MapTileView.ctor(self)
    self:AddAsset(PlayerTileAssetWorldReward.new())
    self:AddAsset(PlayerTileAssetWorldRewardHUD.new())
end

return PlayerTileViewWorldReward