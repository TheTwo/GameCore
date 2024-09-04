
local BaseBehaviour = require("BaseBehaviour")
local Delegate = require("Delegate")

---@class TimelineVibrate:BaseBehaviour
---@field new fun():TimelineVibrate
---@field super BaseBehaviour
local TimelineVibrate = class('TimelineVibrate', BaseBehaviour)

---@type TimelineVibrate
local m_Instance

function TimelineVibrate.Instance()
    if not m_Instance then
        m_Instance = TimelineVibrate.new()
    end
    return m_Instance
end

function TimelineVibrate:ctor()
    self._inUsingVibrateClipIdx = {}
    self._inVibrate = 0
    self._nextVibrate = 0
end

function TimelineVibrate:OnStart(args)
    if not args or #args <= 0 then
        return
    end
    local index = args[1]
    if self._inUsingVibrateClipIdx[index] then
        return
    end
    self._inUsingVibrateClipIdx[index] = true
    local oldCount = self._inVibrate
    self._inVibrate = self._inVibrate + 1
    if oldCount <= 0 then
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.SelfTick))
    end
end

function TimelineVibrate:OnEnd(args)
    if not args or #args <= 0 then
        return
    end
    local index = args[1]
    if not self._inUsingVibrateClipIdx[index] then
        return
    end
    self._inUsingVibrateClipIdx[index] = nil
    local oldCount = self._inVibrate
    self._inVibrate = self._inVibrate - 1
    if oldCount > 0 and self._inVibrate <= 0 then
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.SelfTick))
    end
end

function TimelineVibrate:SelfTick(dt)
    if self._inVibrate <= 0 then
        return
    end
    self._nextVibrate = self._nextVibrate - dt
    if self._nextVibrate <= 0 then
        CS.UnityEngine.Handheld.Vibrate()
        self._nextVibrate = 0.5
    end
end

function TimelineVibrate:CleanUp()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.SelfTick))
end

return TimelineVibrate