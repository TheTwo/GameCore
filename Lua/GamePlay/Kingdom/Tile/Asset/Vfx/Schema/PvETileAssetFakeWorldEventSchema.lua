---@class PvETileAssetFakeWorldEventSchema
---@field new fun():PvETileAssetFakeWorldEventSchema
local PvETileAssetFakeWorldEventSchema = {
    {"facingCamera", typeof(CS.U2DFacingCamera) },
    {"colliderTrans", typeof(CS.UnityEngine.Transform)},
    {"progressImage",typeof(CS.U2DSpriteMesh)},
    {"lvText",typeof(CS.U2DTextMesh)},
    {"icon",typeof(CS.U2DSpriteMesh)},
    {"bgIcon",typeof(CS.U2DSpriteMesh)},
    {"groupIcon",typeof(CS.UnityEngine.GameObject)},
    {"goSelected",typeof(CS.UnityEngine.GameObject)},
    {"goLv",typeof(CS.UnityEngine.GameObject)},
    {"progressText",typeof(CS.U2DTextMesh)},
    {"goInfo",typeof(CS.UnityEngine.GameObject)},
}

return PvETileAssetFakeWorldEventSchema