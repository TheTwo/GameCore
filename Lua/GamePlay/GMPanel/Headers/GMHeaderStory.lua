local GMHeader = require("GMHeader")

---@class GMHeaderStory:GMHeader
---@field new fun():GMHeaderStory
---@field super GMHeader
local GMHeaderStory = class('GMHeaderStory', GMHeader)

function GMHeaderStory:Init(panel)
    ---@type StoryModule
    self._storyModule = g_Game.ModuleManager:RetrieveModule("StoryModule")
end

function GMHeaderStory:Release()
    self._storyModule = nil
end

function GMHeaderStory:DoText()
    local g,c = self._storyModule:GetStatus()
    if not g then
        return nil
    end
    local step = g:GetCurrentStep()
    if not step then
        return string.format("%d|%s:%s|%d:",g:Id(), g:Name(), "nil", c)
    end
    return string.format("%d|%s:%s|%d", g:Id(), g:Name() ,step:Print(), c)
end

return GMHeaderStory