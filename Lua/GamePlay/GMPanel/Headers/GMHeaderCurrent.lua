local GMHeader = require("GMHeader")

---@class GMHeaderCurrent:GMHeader
local GMHeaderCurrent = class('GMHeaderCurrent', GMHeader)

function GMHeaderCurrent:ctor()
    GMHeader.ctor(self)

    self._currentNow = 0
    self._valid = false
    self._manager = CS.Battery.BatteryManager()
end

function GMHeaderCurrent:DoText()
    local content = ""
    
    if self._valid then
        content = string.format("Current Now: %d", self._currentNow)
    else
        content = string.format("Current Now: N/A")
    end

    return content
end

function GMHeaderCurrent:Tick()
    if not self._display then
        return
    end

    if self._manager then
        self._valid, self._currentNow = self._manager:GetCurrentNowInt()
    end
end

function GMHeaderCurrent:Release()
    GMHeader.Release(self)

    if self._manager then
        self._manager:Dispose()
        self._manager = nil
    end
end

return GMHeaderCurrent
