local Time = CS.UnityEngine.Time
local Mathf = CS.UnityEngine.Mathf
---@type CS.ScriptEngine

local GMHeader = require("GMHeader")

---@class GMHeaderFps:GMHeader
local GMHeaderFps = class('GMHeaderFps', GMHeader)
GMHeaderFps._updateInterval = 1.0

function GMHeaderFps:ctor()
    GMHeader.ctor(self)

    self._ms = 0
    self._fps = 0
    self._frames = 0
    self._lastInterval = 0
end

function GMHeaderFps:Init(panel)
    GMHeaderFps.super.Init(self, panel)
end

function GMHeaderFps:Release()
    GMHeaderFps.super.Release(self)
end

function GMHeaderFps:Tick()
    self._frames = self._frames + 1
    local timeNow = Time.realtimeSinceStartupAsDouble
    if timeNow > (self._lastInterval + GMHeaderFps._updateInterval) then
        self._fps = self._frames / (timeNow - self._lastInterval)
        self._ms = 1000.0 / Mathf.Max (self._fps, 0.00001)
        self._frames = 0
        self._lastInterval = timeNow
    end
end

function GMHeaderFps:DoText()
    return string.format("%0.2fms, %0.2fFPS", self._ms, self._fps)
end

return GMHeaderFps