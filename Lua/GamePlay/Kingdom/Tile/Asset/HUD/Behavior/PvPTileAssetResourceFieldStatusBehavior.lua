---@class PvPTileAssetResourceFieldStatusBehavior
---@field p_base CS.U2DSpriteMesh
local PvPTileAssetResourceFieldStatusBehavior = class("PvPTileAssetResourceFieldStatusBehavior")

function PvPTileAssetResourceFieldStatusBehavior:SetBaseSprite(sprite)
    g_Game.SpriteManager:LoadSpriteAsync(sprite, self.p_base)
end

return PvPTileAssetResourceFieldStatusBehavior