---@class StoryTimelineTalkBubbleSchema
local StoryTimelineTalkBubbleSchema = {
    {"root", typeof(CS.UnityEngine.GameObject)},
    {"facingCamera", typeof(CS.U2DFacingCamera)},
    {"StyleWithName", typeof(CS.DragonReborn.LuaBehaviour)},
    {"StyleWithoutName", typeof(CS.DragonReborn.LuaBehaviour)},
    {"ExtraStyles", typeof(CS.System.Collections.Generic.List(CS.DragonReborn.LuaBehaviour))},
}
return StoryTimelineTalkBubbleSchema