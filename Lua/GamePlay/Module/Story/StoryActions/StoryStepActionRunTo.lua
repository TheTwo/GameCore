local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionRunTo:StoryStepActionBase
---@field new fun():StoryStepActionRunTo
---@field super StoryStepActionBase
local StoryStepActionRunTo = class('StoryStepActionRunTo', StoryStepActionBase)

return StoryStepActionRunTo