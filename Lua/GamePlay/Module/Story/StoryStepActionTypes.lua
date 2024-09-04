local StoryActionType = require("StoryActionType")

---@class StoryStepActionTypes
---@field private _nameMap table<string, StoryStepActionBase>
local StoryStepActionTypes = {}

StoryStepActionTypes._nameMap = {
    ["debug"] = require("StoryStepActionDebug"),
    
    [StoryActionType.Dialog] = require("StoryStepActionDialog"),
    [StoryActionType.Choice] = require("StoryStepActionChoice"),
    [StoryActionType.Caption] = require("StoryStepActionCaption"),
    [StoryActionType.Movie] = require("StoryStepActionMovie"),
    [StoryActionType.Timeline] = require("StoryStepActionTimeline"),
    [StoryActionType.CameraMove] = require("StoryStepActionCameraMove"),
    [StoryActionType.CameraUIFreeze] = require("StoryStepActionCameraAndUIFreeze"),
    [StoryActionType.CameraUIUnFreeze] = require("StoryStepActionCameraAndUIUnFreeze"),
    [StoryActionType.WaitTime] = require("StoryStepActionWaitTime"),
    [StoryActionType.WaitEvent] = require("StoryStepActionWaitEvent"),
    [StoryActionType.SoundEvent] = require("StoryStepActionSoundEvent"),

    -- type holder, may use in feature
    ["bubble"] = require("StoryStepActionBubble"),
    ["create_npc"] = require("StoryStepActionCreateNpc"),
    ["create_item"] = require("StoryStepActionCreateItem"),
    ["unload_npc"] = require("StoryStepActionUnloadNpc"),
    ["unload_item"] = require("StoryStepActionUnloadItem"),
    ["walk_to"] = require("StoryStepActionWalkTo"),
    ["run_to"] = require("StoryStepActionRunTo"),
    ["play_animation"] = require("StoryStepActionPlayAnimation"),
    ["goto_public_scene"] = require("StoryStepActionGotoPublicScene"),
    ["goto_city_building"] = require("StoryStepActionGotoCityBuilding"),
    ["enter_gameplay"] = require("StoryStepActionEnterGameplay"),
    ["end_gameplay"] = require("StoryStepActionEndGameplay"),
}

---@field type number
---@return StoryStepActionBase
function StoryStepActionTypes.Get(type)
    return StoryStepActionTypes._nameMap[type]
end

return StoryStepActionTypes