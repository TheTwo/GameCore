local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local TimerUtility = require("TimerUtility")
local TimeFormatter = require("TimeFormatter")

local I18N = require("I18N")

---@class CityWorkProduceUIUnitBubble:BaseUIComponent
local CityWorkProduceUIUnitBubble = class('CityWorkProduceUIUnitBubble', BaseUIComponent)

function CityWorkProduceUIUnitBubble:OnCreate()
    self._statusRecord = self:StatusRecordParent("")
    self._p_progress = self:Image("p_progress")
    self._p_text_time_bubble = self:Text("p_text_time_bubble")
    self._p_icon_item = self:Image("p_icon_item")
    self._p_text_quantity = self:Text("p_text_quantity")
end

---@param data {isWorking:boolean, plan:wds.CastleResourceGeneratePlan}
function CityWorkProduceUIUnitBubble:OnFeedData(data)
    self.data = data
    if not data.isWorking then
        self._statusRecord:ApplyStatusRecord(0)
        return
    end

    self._statusRecord:ApplyStatusRecord(1)
    self._p_progress:SetVisible(not data.plan.Auto)
    self._p_text_time_bubble:SetVisible(not data.plan.Auto)
    if not data.plan.Auto then
        self:TryStopTimer()
        self:UpdateTime()
        self:UpdateProcess()
        self:StartNewTimer()
        self._p_text_quantity.text = "∞"
    else
        self._p_text_quantity.text = ("x%d"):format(data.plan.TargetCount)
    end
end

function CityWorkProduceUIUnitBubble:OnClose()
    self:TryStopTimer()
end

function CityWorkProduceUIUnitBubble:StartNewTimer()
    if not self._secondTimer then 
        self._secondTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.UpdateTime), 1, -1, true)
    end
    if not self._frameTimer then
        self._frameTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.UpdateProcess), 0, -1)
    end
end

function CityWorkProduceUIUnitBubble:UpdateTime()
    if not self.data.plan then return end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local remainTime = math.max(0, self.data.plan.FinishTime.ServerSecond - nowTime)
    self._p_text_time_bubble.text = TimeFormatter.SimpleFormatTime(remainTime)
end

function CityWorkProduceUIUnitBubble:UpdateProcess()
    if not self.data.plan then return end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local passTime = nowTime - self.data.plan.StartTime.ServerSecond
    local fullTime = self.data.plan.FinishTime.ServerSecond - self.data.plan.StartTime.ServerSecond
    local process = math.max(0, math.min(1, passTime / fullTime))
    self._p_progress.fillAmount = process
end

function CityWorkProduceUIUnitBubble:TryStopTimer()
    if self._secondTimer then
        TimerUtility.StopAndRecycle(self._secondTimer)
        self._secondTimer = nil
    end
    if self._frameTimer then
        TimerUtility.StopAndRecycle(self._frameTimer)
        self._frameTimer = nil
    end
end

return CityWorkProduceUIUnitBubble