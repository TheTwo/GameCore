local Delegate = require("Delegate")

---@class Timer
---@field func function
---@field duration number
---@field loop number
---@field running boolean
---@field time number
---@field param any
local Timer = class("Timer", nil, true)
--local Time = g_Game.Time

function Timer:ctor(func, duration, loop, logicTick, param)
    self.func = func
    self.duration = duration or 0
    self.loop = loop or 1
    self.time = duration or 0
    self.running = false
    self.logicTick = logicTick or false
    self.param = param
end

function Timer:Reset(func, duration, loop, logicTick, param)
    if self.running then
        self:Stop()
    end

    self.func = func
    self.duration = duration or 0
    self.loop = loop or 1
    self.time = duration or 0
    self.logicTick = logicTick or false
    self.param = param
end

function Timer:__reset()
    self:Reset()
end

function Timer:Start()
    if type(self.func) ~= "function" then
        g_Logger.Error("Attemp to Start a Second Timer without any callback")
        return
    end

    if self.running then
        return
    end

    self.running = true
    if self.logicTick then
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Update))
    else
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Update))
    end
end

function Timer:Stop()
    if not self.running then
        return
    end

    self.running = false
    if self.logicTick then
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Update))
    else
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Update))
    end
end

function Timer:Update()
    if not self.running then
        return;
    end

    if self.time <= 0 then
        if self.func then
            self.func(self.param)
        end

        if self.loop > 0 then
            self.loop = self.loop - 1
            self.time = self.time + self.duration
        end

        if self.loop == 0 then
            self:Stop();
        elseif self.loop < 0 then
            self.time = self.time + self.duration
        end
    end

    if self.logicTick then
        self.time = self.time - g_Game.Time.deltaTime
    else
        self.time = self.time - g_Game.RealTime.deltaTime
    end
end

---@class FrameTimer
---@field func function
---@field duration integer
---@field loop integer
---@field running boolean
---@field count integer
local FrameTimer = class("FrameTimer", nil, true)

function FrameTimer:ctor(func, frameCount, loop, logicTick, param)
    self.func = func
    self.duration = frameCount
    self.loop = loop or 1
    self.logicTick = logicTick or false
    if self.logicTick then
        self.count = g_Game.Time.frameCount + frameCount
    else
        self.count = g_Game.RealTime.frameCount + frameCount
    end
    self.param = param
    self.running = false
end

function FrameTimer:Reset(func, frameCount, loop, logicTick, param)
    if self.running then
        self:Stop()
    end
    self.func = func
    self.duration = frameCount or 0
    self.loop = loop or 1
    self.logicTick = logicTick or false
    if self.logicTick then
        self.count = g_Game.Time.frameCount + frameCount
    else
        self.count = g_Game.RealTime.frameCount + frameCount
    end
    self.param = param
end

function FrameTimer:__reset()
    self:Reset()
end

function FrameTimer:Start()
    if type(self.func) ~= "function" then
        g_Logger.Error("Attemp to Start a Frame Timer without any callback")
        return
    end

    if self.running then
        return
    end

    self.running = true
    if self.logicTick then
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Update))
    else
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Update))
    end
end

function FrameTimer:Stop()
    if not self.running then
        return
    end

    self.running = false
    if self.logicTick then
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Update))
    else
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Update));
    end
end

function FrameTimer:Update()
    if not self.running then
        return;
    end

    local frameCount = self.logicTick and g_Game.Time.frameCount or g_Game.RealTime.frameCount
    if frameCount >= self.count then
        if self.func then
            self.func(self.param);
        end

        if self.loop > 0 then
            self.loop = self.loop - 1;
        end

        if self.loop == 0 then
            self:Stop();
        else
            self.count = frameCount + self.duration;
        end
    end
end

return {
    Timer = Timer,
    FrameTimer = FrameTimer
}