
---@class CityCitizenBubbleTipSchema
local CityCitizenBubbleTipSchema = {
    {"p_bubble_npc", typeof(CS.UnityEngine.GameObject)},
    {"p_npc_bubble_base", typeof(CS.U2DSpriteMesh)},
    {"p_effect_holder", typeof(CS.UnityEngine.Transform)},
    {"p_icon_npc", typeof(CS.U2DSpriteMesh)},
    {"p_bubble_npc_trigger", typeof(CS.DragonReborn.LuaBehaviour)},
    {"p_escape", typeof(CS.UnityEngine.GameObject)},
    {"p_bubble_talk", typeof(CS.UnityEngine.GameObject)},
    {"p_text_talk", typeof(CS.U2DTextMesh)},
    {"p_bubble_evaluation", typeof(CS.UnityEngine.GameObject)},
    {"p_text_evaluation", typeof(CS.U2DTextMesh)},
    {"p_icon_evaluation", typeof(CS.U2DSpriteMesh)},
    {"p_emoji", typeof(CS.UnityEngine.GameObject)},
    {"p_emoji_icon", typeof(CS.U2DSpriteMesh)},
    {"p_trigger_new", typeof(CS.FpAnimation.FpAnimationCommonTrigger)},
}

return CityCitizenBubbleTipSchema