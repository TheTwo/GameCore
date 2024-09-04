local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionPlayAnimation:StoryStepActionBase
---@field new fun():StoryStepActionPlayAnimation
---@field super StoryStepActionBase
local StoryStepActionPlayAnimation = class('StoryStepActionPlayAnimation', StoryStepActionBase)

return StoryStepActionPlayAnimation