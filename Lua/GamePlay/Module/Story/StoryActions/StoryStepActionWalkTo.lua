local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionWalkTo:StoryStepActionBase
---@field new fun():StoryStepActionWalkTo
---@field super StoryStepActionBase
local StoryStepActionWalkTo = class('StoryStepActionWalkTo', StoryStepActionBase)

return StoryStepActionWalkTo