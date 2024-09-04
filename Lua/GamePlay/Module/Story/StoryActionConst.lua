local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@class StoryActionConst
local StoryActionConst = {}

---@class StoryActionConst.StepContextKey
StoryActionConst.StepContextKey = {
    StoryStepActionCameraAndUIFreeze = "StoryStepActionCameraAndUIFreeze",
}

return StoryActionConst