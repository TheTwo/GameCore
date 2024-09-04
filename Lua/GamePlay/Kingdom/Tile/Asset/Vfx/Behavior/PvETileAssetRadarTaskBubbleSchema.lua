---@class PvETileAssetRadarTaskBubbleSchema
---@field new fun():PvETileAssetRadarTaskBubbleSchema
local PvETileAssetRadarTaskBubbleSchema = {
    {"facingCamera", typeof(CS.U2DFacingCamera) },
    {"colliderTrans", typeof(CS.UnityEngine.Transform)},
    {"bgIcon", typeof(CS.U2DSpriteMesh)},
    {"goRedDot", typeof(CS.UnityEngine.GameObject)},
    {"goFrameNormal", typeof(CS.UnityEngine.GameObject)},
    {"goFrameSelect", typeof(CS.UnityEngine.GameObject)},
    {"iconStatus", typeof(CS.U2DSpriteMesh)},
}

return PvETileAssetRadarTaskBubbleSchema