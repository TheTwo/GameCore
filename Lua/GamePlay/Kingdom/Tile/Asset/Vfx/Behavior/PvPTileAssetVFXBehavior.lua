---@class PvPTileAssetVFXBehavior
---@field vfxRoot CS.UnityEngine.GameObject
local PvPTileAssetVFXBehavior = class("PvPTileAssetVFXBehavior")

function PvPTileAssetVFXBehavior:ShowEffect(state)
    self.vfxRoot:SetVisible(state)
end

return PvPTileAssetVFXBehavior