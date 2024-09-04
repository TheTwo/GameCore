local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local TimeFormatter = require("TimeFormatter")

---@class HUDUTCClockParameter
---@field overrideTimeFormat string

---@class HUDUTCClock : BaseUIComponent
---@field super BaseUIComponent
local HUDUTCClock = class("HUDUTCClock", BaseUIComponent)


function HUDUTCClock:ctor()
    HUDUTCClock.super.ctor(self)
    self.timeFormat = "HH:mm"
end

function HUDUTCClock:OnCreate()
    self.imgIconDay = self:Image("p_icon_time_day")
    self.imgIconNight = self:Image("p_icon_time_night")
    self.textTime = self:Text("p_text_time")
end

---@param param HUDUTCClockParameter
function HUDUTCClock:OnFeedData(param)
    if param and param.overrideTimeFormat then
        self.timeFormat = param.overrideTimeFormat
    else
        self.timeFormat = "HH:mm"
    end
end

function HUDUTCClock:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function HUDUTCClock:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function HUDUTCClock:OnSecondTick()
    local timeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    local timeStr = TimeFormatter.TimeToDateTimeStringUseFormat(timeSec, self.timeFormat)
    self.textTime.text = ("UTC %s"):format(timeStr)
end

return HUDUTCClock