local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionUnloadNpc:StoryStepActionBase
---@field new fun():StoryStepActionUnloadNpc
---@field super StoryStepActionBase
local StoryStepActionUnloadNpc = class('StoryStepActionUnloadNpc', StoryStepActionBase)

return StoryStepActionUnloadNpc