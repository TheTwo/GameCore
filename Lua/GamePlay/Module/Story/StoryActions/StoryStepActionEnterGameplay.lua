local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionEnterGameplay:StoryStepActionBase
---@field new fun():StoryStepActionEnterGameplay
---@field super StoryStepActionBase
local StoryStepActionEnterGameplay = class('StoryStepActionEnterGameplay', StoryStepActionBase)

return StoryStepActionEnterGameplay