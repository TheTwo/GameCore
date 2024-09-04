local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionCreateNpc:StoryStepActionBase
---@field new fun():StoryStepActionCreateNpc
---@field super StoryStepActionBase
local StoryStepActionCreateNpc = class('StoryStepActionCreateNpc', StoryStepActionBase)

return StoryStepActionCreateNpc