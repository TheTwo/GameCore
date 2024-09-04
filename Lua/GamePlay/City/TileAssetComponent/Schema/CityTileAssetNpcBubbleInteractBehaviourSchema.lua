
---@class CityTileAssetNpcBubbleInteractBehaviourSchema
local CityTileAssetNpcBubbleInteractBehaviourSchema = {
    {"p_icon_status", typeof(CS.U2DSpriteMesh)},
    {"p_icon_pollution", typeof(CS.UnityEngine.GameObject)},
    {"p_icon_danger", typeof(CS.U2DSpriteMesh)},
    {"p_icon_creep", typeof(CS.U2DSpriteMesh)},
    {"p_group_talk", typeof(CS.UnityEngine.GameObject)},
    {"p_text_talk", typeof(CS.U2DTextMesh)},
    {"p_click_trigger", typeof(CS.DragonReborn.LuaBehaviour)},
}

return CityTileAssetNpcBubbleInteractBehaviourSchema