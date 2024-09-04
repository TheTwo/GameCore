-- UE那边有一个通用活动倒计时组件，绑定CommonActivityTimer脚本
---@see CommonActivityTimer
-- 还有一个更通用的倒计时组件，绑定CommonTimer
---@see CommonTimer
-- 但是如果场景里都没有使用它们
-- 而你又懒得找ue改了
-- 使用该脚本凑活下也是可以的
local TimeFormatter = require("TimeFormatter")
local Delegate = require("Delegate")
---@class ActivityTimerHolder
local ActivityTimerHolder = class("ActivityTimerHolder")

local DisplayMode = {
    Split = 1,
    Single = 2,
}

ActivityTimerHolder.DisplayMode = DisplayMode

---@param textDay CS.UnityEngine.UI.Text
---@param textHour CS.UnityEngine.UI.Text
---@param textMinute CS.UnityEngine.UI.Text
---@param textSecond CS.UnityEngine.UI.Text
function ActivityTimerHolder:ctor(textDay, textHour, textMinute, textSecond)
    self.textDay = textDay
    self.textHour = textHour
    self.textMinute = textMinute
    self.textSecond = textSecond

    self.tick = false
    self.endTimeSec = 0
    self.tickSec = 0
    self.callback = nil
    self.displayMode = DisplayMode.Split
end

function ActivityTimerHolder:Setup()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function ActivityTimerHolder:Release()
    self.callback = nil
    self.tick = false
    self.endTimeSec = 0
    self.tickSec = 0
    self.textDay = nil
    self.textHour = nil
    self.textMinute = nil
    self.textSecond = nil
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
end

---@param sec number @结束时间戳 - 秒
function ActivityTimerHolder:StartTick(sec)
    self.endTimeSec = sec
    self.tick = true
end

function ActivityTimerHolder:StopTick()
    self.tick = false
end

function ActivityTimerHolder:SetDisplayMode(mode)
    self.displayMode = mode
end

---@param callback fun()
function ActivityTimerHolder:SetCallback(callback)
    self.callback = callback
end

function ActivityTimerHolder:OnTick()
    if not self.tick then
        return
    end

    self.tickSec = math.max(self.endTimeSec - g_Game.ServerTime:GetServerTimestampInSeconds(), 0)

    if self.displayMode == DisplayMode.Split then
        self:TickSplit()
    elseif self.displayMode == DisplayMode.Single then
        self:TickSingle()
    end

    if self.tickSec <= 0 then
        if self.callback then
            self.callback()
        end
        self.tick = false
    end
end

function ActivityTimerHolder:TickSplit()
    local timeTable = TimeFormatter.GetTimeTableInDHMS(self.tickSec)
    if not self.textDay then
        timeTable.hour = timeTable.hour + timeTable.day * 24
    end
    if self.textDay then
        self.textDay.text = string.format("%dd", timeTable.day)
    end
    if self.textHour then
        self.textHour.text = string.format("%02d", timeTable.hour)
    end
    if self.textMinute then
        self.textMinute.text = string.format("%02d", timeTable.minute)
    end
    if self.textSecond then
        self.textSecond.text = string.format("%02d", timeTable.second)
    end
end

function ActivityTimerHolder:TickSingle()
    local timeStr = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(self.tickSec)
    if self.textDay then
        self.textDay.text = timeStr
    elseif self.textHour then
        self.textHour.text = timeStr
    elseif self.textMinute then
        self.textMinute.text = timeStr
    elseif self.textSecond then
        self.textSecond.text = timeStr
    end
end

return ActivityTimerHolder