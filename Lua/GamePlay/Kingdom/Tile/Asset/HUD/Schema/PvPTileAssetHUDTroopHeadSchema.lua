---@class PvPTileAssetHUDTroopHeadSchema
local PvPTileAssetHUDTroopHeadSchema =
{
    {"p_trigger", typeof(CS.DragonReborn.LuaBehaviour)},
    {"root", typeof(CS.UnityEngine.Transform)},
    {"p_img_base", typeof(CS.U2DSpriteMesh)},
    {"p_image_monster", typeof(CS.U2DSpriteMesh)},
    {"p_health", typeof(CS.UnityEngine.GameObject)},
    {"p_progress", typeof(CS.U2DSlider)},
    {"p_group_village_monsters", typeof(CS.UnityEngine.GameObject)},
    {"p_text_monsters_num", typeof(CS.U2DTextMesh)},
    {"p_image_dange", typeof(CS.U2DSpriteMesh)},
}

return PvPTileAssetHUDTroopHeadSchema