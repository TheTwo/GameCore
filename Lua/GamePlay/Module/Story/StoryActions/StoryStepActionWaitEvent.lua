local EventConst = require("EventConst")
local Delegate = require("Delegate")

local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionWaitEvent:StoryStepActionBase
---@field new fun():StoryStepActionWaitEvent
---@field super StoryStepActionBase
local StoryStepActionWaitEvent = class('StoryStepActionWaitEvent', StoryStepActionBase)

function StoryStepActionWaitEvent:LoadConfig(actionParam)
    self._waitEvent = actionParam and EventConst[actionParam] or nil
end

function StoryStepActionWaitEvent:OnEnter()
    if not self._waitEvent then
        self:EndAction(false)
        return
    end
    self:SetGestureBlock()
    g_Game.EventManager:AddListener(self._waitEvent, Delegate.GetOrCreate(self, self.OnEvent))
end

function StoryStepActionWaitEvent:OnLeave()
    if not self._waitEvent then
        return
    end
    self:UnSetGestureBlock()
    g_Game.EventManager:RemoveListener(self._waitEvent, Delegate.GetOrCreate(self, self.OnEvent))
end

function StoryStepActionWaitEvent:OnEvent()
    self:EndAction()
end

function StoryStepActionWaitEvent:OnSetEndStatus(isRestore)
    -- do nothing
end

return StoryStepActionWaitEvent