local ConfigRefer = require("ConfigRefer")
local StoryTimeline = require("StoryTimeline")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionTimeline:StoryStepActionBase
---@field new fun():StoryStepActionTimeline
---@field super StoryStepActionBase
local StoryStepActionTimeline = class('StoryStepActionTimeline', StoryStepActionBase)

function StoryStepActionTimeline:ctor()
    StoryStepActionBase.ctor(self)
    ---@type StoryTimeline
    self._storyTimeLine = nil
end

function StoryStepActionTimeline:LoadConfig(actionParam)
    self._timeLineConfigId = tonumber(actionParam)
end

function StoryStepActionTimeline:OnEnter()
    self:SetGestureBlock()
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(self, self.OnTimePlayEnd))
    if self._timeLineConfigId then
        local cfg = ConfigRefer.TimelineInfo:Find(self._timeLineConfigId)
        if cfg then
            self._storyTimeLine = StoryTimeline.BuildWithConfig(cfg)
            self._storyTimeLine:PrepareAsset(true)
            return
        end
    end
    self:EndAction(false)
end

function StoryStepActionTimeline:OnLeave()
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(self, self.OnTimePlayEnd))
    if self._storyTimeLine then
        self._storyTimeLine:Stop(false)
        self._storyTimeLine:Release()
    end
    self._storyTimeLine = nil
    self:UnSetGestureBlock()
end

function StoryStepActionTimeline:OnTimePlayEnd(timeLineId)
    if timeLineId ~= self._timeLineConfigId then
        return
    end
    self:EndAction()
end

function StoryStepActionTimeline:OnSetEndStatus(isRestore)
    --do nothing, play timeline no need rebuild environment
end

return StoryStepActionTimeline