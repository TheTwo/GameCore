--- scene:scene_timeline_skip

local Delegate = require("Delegate")

local BaseUIMediator = require("BaseUIMediator")

---@class StoryTimelineControlMediatorParameter
---@field onSkipClick fun(param:StoryTimelineControlMediatorParameter):boolean

---@class StoryTimelineControlMediator:BaseUIMediator
---@field new fun():StoryTimelineControlMediator
---@field super BaseUIMediator
local StoryTimelineControlMediator = class('StoryTimelineControlMediator', BaseUIMediator)

function StoryTimelineControlMediator:ctor()
    StoryTimelineControlMediator.super.ctor(self)
    self._delayExit = false
end

function StoryTimelineControlMediator:OnCreate(param)
    self._p_btn_skip = self:Button("p_btn_skip", Delegate.GetOrCreate(self, self.OnClickSkip))
    self._p_text_skip = self:Text("p_text_skip", "Story_SkipUI_Disc")
end

----@param param StoryTimelineControlMediatorParameter
function StoryTimelineControlMediator:OnOpened(param)
    self._delayExit = false
    ---@type StoryTimelineControlMediatorParameter
    self._parameter = param
end

function StoryTimelineControlMediator:OnShow(param)
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function StoryTimelineControlMediator:OnHide(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function StoryTimelineControlMediator:OnClickSkip()
    if not self._parameter or not self._parameter.onSkipClick then return end
    local p = self._parameter
    self._parameter = nil
    if p.onSkipClick(p) then
        self._delayExit = true
    end
end

function StoryTimelineControlMediator:Tick()
    if not self._delayExit then return end
    self:CloseSelf()
end

return StoryTimelineControlMediator