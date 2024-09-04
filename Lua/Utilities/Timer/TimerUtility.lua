local TimerUtility = {}
local Timer = require("Timer")

---@param func function
---@param delay number
---@param logicTick boolean|nil 是否使用逻辑帧
---@return Timer 延迟delay秒后执行一次
function TimerUtility.DelayExecute(func, delay, logicTick, param)
    local timer = Timer.Timer.new(func, delay, 1, logicTick, param)
    timer:Start();
    return timer;
end

---@param func function
---@param delayFrame number
---@param logicTick boolean|nil 是否使用逻辑帧
---@return Timer 延迟delayFrame帧后执行一次
function TimerUtility.DelayExecuteInFrame(func, delayFrame, logicTick, param)
    delayFrame = delayFrame or 1
    local timer = Timer.FrameTimer.new(func, delayFrame, 1, logicTick, param)
    timer:Start()
    return timer
end

---@param func function
---@param interval number 间隔时长
---@param loopTimes number 重复次数，-1为无限循环
---@param logicTick boolean|nil 是否使用逻辑帧
---@return Timer 每间隔interval秒后执行一次, 重复loopTimes次(-1时无限重复)
function TimerUtility.IntervalRepeat(func, interval, loopTimes, logicTick, param)
    local timer = Timer.Timer.new(func, interval, loopTimes, logicTick, param)
    timer:Start();
    return timer;
end

---@param func function
---@param frameCount number 间隔帧数
---@param loop number 重复次数，-1为无限循环
---@param logicTick boolean|nil 是否使用逻辑帧
---@return FrameTimer
function TimerUtility.StartFrameTimer(func, frameCount, loop, logicTick, param)
    local frameTimer = Timer.FrameTimer.new(func, frameCount, loop, logicTick, param)
    frameTimer:Start();
    return frameTimer;
end

---@param timer Timer|FrameTimer
---@return nil 手动停止计时器并回收
function TimerUtility.StopAndRecycle(timer)
    timer:Stop();
end

return TimerUtility