---@class PvPTileAssetRadarBubbleSchema
---@field new fun():PvPTileAssetRadarBubbleSchema
local PvPTileAssetRadarBubbleSchema = {
    {"facingCamera", typeof(CS.U2DFacingCamera) },
    {"colliderTrans", typeof(CS.UnityEngine.Transform)},
    {"goTime", typeof(CS.UnityEngine.GameObject)},
    {"timeText",typeof(CS.U2DTextMesh)},
    {"goBubble", typeof(CS.UnityEngine.GameObject)},
    {"goLodIcon", typeof(CS.UnityEngine.GameObject)},
    {"imgBaseBubble",typeof(CS.U2DSpriteMesh)},
    {"imgFrameCystBubble",typeof(CS.U2DSpriteMesh)},
    {"imgIconBubble",typeof(CS.U2DSpriteMesh)},
    {"imgFrameLodIcon",typeof(CS.U2DSpriteMesh)},
    {"imgIconLodIcon",typeof(CS.U2DSpriteMesh)},
    {"goGroupPetReward", typeof(CS.UnityEngine.GameObject)},
    {"imgGroupPetReward",typeof(CS.U2DSpriteMesh)},
    {"imgCitizenTaskIcon",typeof(CS.U2DSpriteMesh)},
}

return PvPTileAssetRadarBubbleSchema