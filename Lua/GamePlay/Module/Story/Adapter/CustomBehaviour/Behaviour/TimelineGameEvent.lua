local EventConst = require("EventConst")
local BaseBehaviour = require("BaseBehaviour")

---@class TimelineGameEvent:BaseBehaviour
---@field new fun():TimelineGameEvent
---@field super BaseBehaviour
local TimelineGameEvent = class('TimelineGameEvent', BaseBehaviour)

---@type TimelineGameEvent
local m_Instance = nil

function TimelineGameEvent:ctor()
    self._currentArgs = nil
end

function TimelineGameEvent.Instance()
    if not m_Instance then
        m_Instance = TimelineGameEvent.new()
    end
    return m_Instance
end

function TimelineGameEvent:OnStart(args)
    if not args or #args <= 0 then
        return
    end
    self._currentArgs = args
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_GAME_EVENT_START, args)
end

function TimelineGameEvent:OnEnd(args)
    if not args or #args <= 0 then
        return
    end
    self._currentArgs = nil
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_GAME_EVENT_END, args)
end

function TimelineGameEvent:OnCurrentTimelineExit()
    if not self._currentArgs then return end
    local v = self._currentArgs
    self._currentArgs = nil
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_GAME_EVENT_END, v)
end

return TimelineGameEvent