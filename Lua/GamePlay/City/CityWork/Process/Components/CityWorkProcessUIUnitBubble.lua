local BaseUIComponent = require ('BaseUIComponent')
local TimeFormatter = require('TimeFormatter')
local TimerUtility = require('TimerUtility')
local Delegate = require('Delegate')
local EventConst = require("EventConst")

local I18N = require("I18N")

---@class CityWorkProcessUIUnitBubble:BaseUIComponent
---@field uiMediator CityWorkProcessUIMediator
local CityWorkProcessUIUnitBubble = class('CityWorkProcessUIUnitBubble', BaseUIComponent)

function CityWorkProcessUIUnitBubble:OnCreate()
    self._statusRecordParent = self:StatusRecordParent("")
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClickBubble))
    self._p_progress = self:Image("p_progress")
    self._vx_trigger = self:AnimTrigger("vx_trigger")
    self._p_progress_stop = self:Image("p_progress_stop")
    self._p_text_time_bubble = self:Text("p_text_time_bubble")
    self._p_icon_item = self:Image("p_icon_item")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_btn_reduce = self:Button("p_btn_reduce", Delegate.GetOrCreate(self, self.OnClickCancel))
    self._p_text_reduce = self:Text("p_text_reduce", "sys_city_39")
end

function CityWorkProcessUIUnitBubble:OnOpened()
    g_Game.EventManager:AddListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
end

---@param data CityWorkProcessUIUnitBubbleData
function CityWorkProcessUIUnitBubble:OnFeedData(data)
    self.data = data
    self.uiMediator = self:GetParentBaseUIMediator()
    
    self._statusRecordParent:ApplyStatusRecord(self.data.status)
    if not self.data:IsFree() then
        g_Game.SpriteManager:LoadSprite(self.data:GetIcon(), self._p_icon_item)
    end

    local isWorking = self.data:IsWorking()
    if isWorking then
        self._p_text_quantity.text = ("x%d"):format(data.process.FinishNum + data.process.LeftNum)
        self:UpdateProgress()
        self:UpdateRemainTimeText()
        self:ActiveFrameTick()
        self:ActiveSecondTick()
    else
        self._p_text_quantity.text = string.Empty
        self:InactiveFrameTick()
        self:InactiveSecondTick()
    end

    if self.isWorking == false then
        self:PlayBubbleVX()
    end

    self.isWorking = self.data:IsWorking()
end

function CityWorkProcessUIUnitBubble:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
    self:InactiveFrameTick()
    self:InactiveSecondTick()
end

function CityWorkProcessUIUnitBubble:ActiveFrameTick()
    if self._frameTicker then return end

    self._frameTicker = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.UpdateProgress), 1, -1)
end

function CityWorkProcessUIUnitBubble:InactiveFrameTick()
    if not self._frameTicker then return end
    TimerUtility.StopAndRecycle(self._frameTicker)
    self._frameTicker = nil
end

function CityWorkProcessUIUnitBubble:ActiveSecondTick()
    if self._secondTicker then return end

    self._secondTicker = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.UpdateRemainTimeText), 1, -1, true)
end

function CityWorkProcessUIUnitBubble:InactiveSecondTick()
    if not self._secondTicker then return end
    TimerUtility.StopAndRecycle(self._secondTicker)
    self._secondTicker = nil
end

function CityWorkProcessUIUnitBubble:UpdateProgress()
    self._p_progress.fillAmount = self.uiMediator:GetCurrentRecipeProgress()
end

function CityWorkProcessUIUnitBubble:UpdateRemainTimeText()
    self._p_text_time_bubble.text = TimeFormatter.SimpleFormatTime(self.uiMediator:GetCurrentRecipeRemainTime())
end

function CityWorkProcessUIUnitBubble:OnUITouchUp(gameObj)
    if gameObj == self._button.gameObject then return end

    self._p_btn_reduce:SetVisible(false)
end

function CityWorkProcessUIUnitBubble:OnClickBubble()
    if self.data:IsFinished() then
        self.uiMediator:CollectSingleProcess(self.data.process, self._button.transform)
        return
    end

    if self.data:IsWorking() then
        self._p_btn_reduce:SetVisible(true)
    end
end

function CityWorkProcessUIUnitBubble:OnClickCancel()
    if self.data:IsWorking() then
        self.uiMediator:RequestRemoveInQueue(self.data.process)
    end
end

function CityWorkProcessUIUnitBubble:PlayBubbleVX()
    self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

return CityWorkProcessUIUnitBubble