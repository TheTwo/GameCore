---@class PvETileAssetWorldEventSchema
---@field new fun():PvETileAssetWorldEventSchema
local PvETileAssetWorldEventSchema = {
    {"facingCamera", typeof(CS.U2DFacingCamera) },
    {"timeText",typeof(CS.U2DTextMesh)},
    {"scaleRoot", typeof(CS.UnityEngine.Transform)},
    {"progressImage",typeof(CS.U2DSpriteMesh)},
    {"lvText",typeof(CS.U2DTextMesh)},
    {"icon",typeof(CS.U2DSpriteMesh)},
    {"frame",typeof(CS.U2DSpriteMesh)},
    {"materialSetter",typeof(CS.Lod.U2DWidgetMaterialSetter)},
    {"trigger", typeof(CS.DragonReborn.LuaBehaviour)},
    {"lv", typeof(CS.UnityEngine.GameObject)},
    {"openTime", typeof(CS.UnityEngine.GameObject)},
    {"timeOpenText",typeof(CS.U2DTextMesh)},
    {"openText",typeof(CS.U2DTextMesh)},
}

return PvETileAssetWorldEventSchema