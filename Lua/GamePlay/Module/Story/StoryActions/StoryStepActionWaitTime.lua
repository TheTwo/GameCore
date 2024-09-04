local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionWaitTime:StoryStepActionBase
---@field new fun():StoryStepActionWaitTime
---@field super StoryStepActionBase
local StoryStepActionWaitTime = class('StoryStepActionWaitTime', StoryStepActionBase)

function StoryStepActionWaitTime:LoadConfig(actionParam)
    self._waitTimeSec = actionParam and tonumber(actionParam) or 0
    self._tickEndTime = 0
end

function StoryStepActionWaitTime:OnEnter()
    self:SetGestureBlock()
    self._tickEndTime = g_Game.ServerTime:GetServerTimestampInSeconds() + self._waitTimeSec
end

function StoryStepActionWaitTime:OnExecute()
    if self._tickEndTime < g_Game.ServerTime:GetServerTimestampInSeconds() then
        self:EndAction()
    end
end

function StoryStepActionWaitTime:OnLeave()
    self:UnSetGestureBlock()
end

function StoryStepActionWaitTime:OnSetEndStatus(isRestore)
    -- do nothing
end

return StoryStepActionWaitTime