---@prefabName:ui3d_bubble_building_icon
local PvPTileAssetHUDIconSchema = {
    {"root", typeof(CS.UnityEngine.Transform)},
    {"p_icon_building", typeof(CS.U2DSpriteMesh)},
    {"p_icon_building_base", typeof(CS.U2DSpriteMesh)},
    {"p_group_name", typeof(CS.UnityEngine.GameObject)},
    {"p_text_name", typeof(CS.U2DTextMesh)},
    {"p_text_lv", typeof(CS.U2DTextMesh)},
    {"p_lv_base", typeof(CS.U2DSpriteMesh)},
    {"p_anchor_lv", typeof(CS.U2DAnchor)},
    {"p_trigger", typeof(CS.DragonReborn.LuaBehaviour)},
    {"iconMaterialSetter", typeof(CS.Lod.U2DWidgetMaterialSetter)},
    {"textMaterialSetter", typeof(CS.Lod.U2DWidgetMaterialSetter)},
    {"facingCamera", typeof(CS.U2DFacingCamera)},
}
return PvPTileAssetHUDIconSchema