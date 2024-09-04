local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionGotoPublicScene:StoryStepActionBase
---@field new fun():StoryStepActionGotoPublicScene
---@field super StoryStepActionBase
local StoryStepActionGotoPublicScene = class('StoryStepActionGotoPublicScene', StoryStepActionBase)

return StoryStepActionGotoPublicScene