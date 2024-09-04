local BaseUIComponent = require ('BaseUIComponent')
local TimeFormatter = require("TimeFormatter")
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')

local TextAnchor = CS.UnityEngine.TextAnchor

---@class CommonTimer:BaseUIComponent
local CommonTimer = class('CommonTimer', BaseUIComponent)

---@class CommonTimerData
---@field endTime number @in second timespan
---@field needTimer boolean
---@field intervalTime number
---@field fixTime number
---@field color CS.UnityEngine.Color
---@field callBack function
---@field overrideTimeFormat fun(leftSeconds):string
---@field alignment CS.UnityEngine.TextAnchorZ
---@field deadline number 秒数
---@field deadlineColor CS.UnityEngine.Color
---@field textFormat string     不同的倒计时样式
---@field infoString string     倒计时前面的文本

function CommonTimer:ctor()

end

function CommonTimer:OnCreate()
    self.icon = self:Image("icon_time")
    self.infoText = self:Text("p_text_info")
    self.timerText = self:Text("p_text_ad_time")
end

function CommonTimer:OnClose()
    self:RecycleTimer()
end

function CommonTimer:RecycleTimer()
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
        self.tickTimer = nil
    end
end

---@param param CommonTimerData
function CommonTimer:OnFeedData(param)
    if not param then
        return
    end
    self.param = param
    if self.param.color then
        if self.icon then
            self.icon.color = self.param.color
        end
        self.timerText.color = self.param.color
    end
    if self.param.alignment then
        self.timerText.alignment = self.param.alignment
    end

    --用于实现倒计时多少秒文本变色
    if self.param.deadline then
        self.deadLine = self.param.deadline
    end
    if self.param.deadlineColor then
        self.deadLineColor = self.param.deadlineColor
    end

    --用于实现把时间当做参数的文本
    if self.param.textFormat then
        self.textFormat = self.param.textFormat
    else
        self.textFormat = nil
    end

    self:RefreshTimeText()
    if self.param.needTimer and not self.tickTimer then
        self.tickTimer = TimerUtility.IntervalRepeat(function() self:RefreshTimeText() end, param.intervalTime or 0.1, -1)
    end

    if self.infoText and self.param.infoString then
        self.infoText.text = self.param.infoString
    end
end

function CommonTimer:RefreshTimeText()
    if self.param.endTime then
        local remainTime = self.param.endTime - g_Game.ServerTime:GetServerTimestampInSeconds()
        if remainTime > 0 then

            if self.deadLine and self.deadLineColor then
                if remainTime <= self.deadLine then
                    self.timerText.color = self.deadLineColor
                    self.deadLineColor = nil
                end
            end

            if self.param.overrideTimeFormat then
                if self.textFormat then
                    self.timerText.text = I18N.GetWithParams(self.textFormat, self.param.overrideTimeFormat(remainTime))
                else
                    self.timerText.text = self.param.overrideTimeFormat(remainTime)
                end
            else
                if self.textFormat then
                    self.timerText.text = I18N.GetWithParams(self.textFormat, TimeFormatter.SimpleFormatTimeWithDayHour(remainTime))
                else
                    self.timerText.text = TimeFormatter.SimpleFormatTimeWithDayHour(remainTime)
                end
            end
        else
            self.timerText.text = "00:00:00"
            self:RecycleTimer()
            if self.param.callBack then
                self.param.callBack()
            end
        end
    elseif self.param.fixTime then
        if self.param.fixTime >= 0 then
            if self.param.overrideTimeFormat then
                self.timerText.text = self.param.overrideTimeFormat(self.param.fixTime)
            else
                self.timerText.text = TimeFormatter.SimpleFormatTime(self.param.fixTime)
            end
        else
            self.timerText.text = '--:--:--'
        end
    end
end

function CommonTimer:CustomText(customText)
    self.timerText.text = customText
end

return CommonTimer
