local BaseUIComponent = require("BaseUIComponent")
local ModuleRefer = require('ModuleRefer')
local TimeFormatter = require('TimeFormatter')
local Delegate = require('Delegate')
---@class CommonActivityTimer : BaseUIComponent
local CommonActivityTimer = class('CommonActivityTimer', BaseUIComponent)

---@class CommonActivityTimerParam
---@field activityTemplateId number @和endTime二选一
---@field useActivityStartTime boolean @是否使用活动开始时间, false则使用活动结束时间, 默认false
---@field endTime number @sec, 和activityTemplateId二选一
---@field callback fun() @倒计时结束回调

function CommonActivityTimer:ctor()
    self.tick = true
    self.endTimeSec = 0
    self.callback = nil
end

function CommonActivityTimer:OnCreate()
    self.textDay = self:Text('p_text_count_down_day', '0d')
    self.textHour = self:Text('p_text_count_down_hour', '00')
    self.textMinute = self:Text('p_text_count_down_min', '00')
    self.textSecond = self:Text('p_text_count_down_s', '00')
    self.goDay = self:GameObject('p_base') or self.textDay.gameObject
end

function CommonActivityTimer:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    self:SetTick(true)
end

function CommonActivityTimer:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    self:SetTick(false)
end

---@param param CommonActivityTimerParam
function CommonActivityTimer:OnFeedData(param)
    self.param = param
    self.callback = param.callback
    if self.param.activityTemplateId then
        local activityTemplateId = self.param.activityTemplateId
        local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityTemplateId)
        if self.param.useActivityStartTime then
            self.endTimeSec = startTime.Seconds
        else
            self.endTimeSec = endTime.Seconds
        end
    elseif self.param.endTime then
        self.endTimeSec = self.param.endTime
    end
    local endTimeSec = self.endTimeSec
    local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    local sec = math.max(endTimeSec - curTimeSec, 0)
    if sec > 0 then
        self:SetTick(true)
        self:Tick()
    else
        self:SetTick(false)
        self.goDay:SetActive(false)
    end
end

---@param tick boolean
function CommonActivityTimer:SetTick(tick)
    self.tick = tick
end

function CommonActivityTimer:Tick()
    local endTimeSec = self.endTimeSec
    local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    local sec = math.max(endTimeSec - curTimeSec, 0)
    self:TickImpl(sec)
    if sec <= 0 then
        self:OnTimerEnd()
    end
end

function CommonActivityTimer:TickImpl(sec)
    local timeTable = TimeFormatter.GetTimeTableInDHMS(sec)
    self.goDay:SetActive(timeTable.day > 0)
    self.textDay.text = string.format("%dd", timeTable.day)
    self.textHour.text = string.format("%02d", timeTable.hour)
    self.textMinute.text = string.format("%02d", timeTable.minute)
    self.textSecond.text = string.format("%02d", timeTable.second)
end

function CommonActivityTimer:OnSecondTick()
    if not self.tick then
        return
    end
    self:Tick()
end

function CommonActivityTimer:OnTimerEnd()
    self:SetTick(false)
    if self.callback then
        self.callback()
    end
    self.callback = nil
end

return CommonActivityTimer