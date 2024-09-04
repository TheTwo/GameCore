local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionDebug:StoryStepActionBase
---@field new fun():StoryStepActionDebug
---@field super StoryStepActionBase
local StoryStepActionDebug = class('StoryStepActionDebug', StoryStepActionBase)

function StoryStepActionDebug:OnExecute()
    self:EndAction()
end

function StoryStepActionDebug:OnSetEndStatus(isRestore)
    g_Logger.LogChannel("Story", "StoryStepActionDebug:OnSetEndStatus(%s)", isRestore)
end

return StoryStepActionDebug