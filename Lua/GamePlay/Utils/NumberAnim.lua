---@class NumberAnim
---@field new fun(startNum, endNum, duration, callback):NumberAnim
local NumberAnim = class("NumberAnim")

function NumberAnim:ctor(startNum, endNum, duration, callback)
    self.startNum = startNum
    self.endNum = endNum
    self.duration = duration
    self.callback = callback
end

function NumberAnim:Start()
    self.active = true
    self.progress = 0
    self:Tick(0)
end

function NumberAnim:Stop()
    self.active = false
end

function NumberAnim:Tick(delta)
    if not self.active then return end

    self.progress = self.progress + delta
    if self.progress >= self.duration then
        self.progress = self.duration
        self.active = false

        if self.callback then
            self.callback()
        end
    end
end

function NumberAnim:GetText()
    local percent
    if self.duration == 0 then
        percent = 1
    else
        percent = math.clamp01(self.progress / self.duration)
    end

    local value = math.lerp(self.startNum, self.endNum, percent)
    return string.format("%.0f", value)
end

return NumberAnim