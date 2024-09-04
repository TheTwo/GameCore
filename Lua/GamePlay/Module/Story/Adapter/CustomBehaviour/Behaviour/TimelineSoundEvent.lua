local EventConst = require("EventConst")

local BaseBehaviour = require("BaseBehaviour")

---@class TimelineSoundEvent:BaseBehaviour
---@field new fun():TimelineSoundEvent
---@field super BaseBehaviour
local TimelineSoundEvent = class('TimelineSoundEvent', BaseBehaviour)

---@type TimelineSoundEvent
local m_Instance = nil

function TimelineSoundEvent.Instance()
    if not m_Instance then
        m_Instance = TimelineSoundEvent.new()
    end
    return m_Instance
end

function TimelineSoundEvent:ctor()
    ---@type table<number, CS.DragonReborn.SoundPlayingHandle>
    self._inUsing = {}
end

function TimelineSoundEvent:OnStart(args)
    if not args or #args <= 0then
        return
    end
    local index = args[1]
    if not index then
        return
    end
    local key = args[2]
    local go = args[3]
    --local param = args[4]
    local handle = g_Game.SoundManager:Play(key, go, false)
    self._inUsing[index] = handle
end

function TimelineSoundEvent:OnEnd(args)
    if not args or #args <= 0then
        return
    end
    local index = args[1]
    if not index then
        return
    end
    local handle = self._inUsing[index]
    self._inUsing[index] = nil
    if not handle then
        return
    end
    g_Game.SoundManager:Stop(handle)
end

function TimelineSoundEvent:OnCurrentTimelineExit()
    for i, handle in pairs(self._inUsing) do
        g_Game.SoundManager:Stop(handle)
    end
    table.clear(self._inUsing)
end

return TimelineSoundEvent