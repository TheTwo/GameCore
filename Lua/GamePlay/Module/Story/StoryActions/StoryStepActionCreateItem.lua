local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionCreateItem:StoryStepActionBase
---@field new fun():StoryStepActionCreateItem
---@field super StoryStepActionBase
local StoryStepActionCreateItem = class('StoryStepActionCreateItem', StoryStepActionBase)

return StoryStepActionCreateItem