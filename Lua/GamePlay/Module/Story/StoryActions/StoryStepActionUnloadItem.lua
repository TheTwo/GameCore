local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionUnloadItem:StoryStepActionBase
---@field new fun():StoryStepActionUnloadItem
---@field super StoryStepActionBase
local StoryStepActionUnloadItem = class('StoryStepActionUnloadItem', StoryStepActionBase)

return StoryStepActionUnloadItem