local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionEndGameplay:StoryStepActionBase
---@field new fun():StoryStepActionEndGameplay
---@field super StoryStepActionBase
local StoryStepActionEndGameplay = class('StoryStepActionEndGameplay', StoryStepActionBase)

return StoryStepActionEndGameplay