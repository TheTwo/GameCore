local BaseTableViewProCell = require ('BaseTableViewProCell')
local CityWorkProduceUIUnitStatus = require('CityWorkProduceUIUnitStatus')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local TimerUtility = require("TimerUtility")
local CityWorkType = require("CityWorkType")
local CityWorkProduceWdsHelper = require("CityWorkProduceWdsHelper")

---@class CityWorkProduceUIUnit:BaseTableViewProCell
---@field uiMediator CityWorkProduceUIMediator
local CityWorkProduceUIUnit = class('CityWorkProduceUIUnit', BaseTableViewProCell)

function CityWorkProduceUIUnit:OnCreate()
    self._statusRecord = self:StatusRecordParent("")
    self._p_btn_queue = self:Button("p_btn_queue", Delegate.GetOrCreate(self, self.OnClickInQueue))
    self._p_icon_item = self:Image("p_icon_item")
    self._p_text_quantity = self:Text("p_text_quantity")

    self._p_progress_item = self:Slider("p_progress_item")
    self._p_button_working_menu = self:Button("p_button_working_menu", Delegate.GetOrCreate(self, self.OnClickWorking))
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")

    self._p_text_reduce = self:Text("p_text_reduce", "sys_city_41")
    self._p_btn_reduce = self:Button("p_btn_reduce", Delegate.GetOrCreate(self, self.OnClickCancel))
end

---@param data CityWorkProduceUIUnitData
function CityWorkProduceUIUnit:OnFeedData(data)
    self.data = data
    self.uiMediator = data.uiMediator
    self.paused = self.data.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.ResourceGenerate] == nil
    self._statusRecord:ApplyStatusRecord(data.status)
    if data.status == CityWorkProduceUIUnitStatus.InQueue or data.status == CityWorkProduceUIUnitStatus.Working then
        g_Game.SpriteManager:LoadSprite(data:GetInQueueImage(), self._p_icon_item)
        if data.plan.Auto then
            self._p_text_quantity.text = "∞"
        else
            self._p_text_quantity.text = ("x%d"):format(data.plan.TargetCount)
        end
    else
        self._p_btn_reduce:SetVisible(false)
    end

    self:TryBindTouchEvent()
    self:TryStopWorkingTimer()
    if data.status == CityWorkProduceUIUnitStatus.Working then
        self._child_time:SetVisible(not data.plan.Auto and not self.paused)
        if not data.plan.Auto then
            if not self.paused then
                self:TryStartWorkingTimer()
            end
            self:OnWorkingTick()
            self:SetCommonTimer()
        else
            self._p_progress_item.value = 1
        end
    end
end

function CityWorkProduceUIUnit:OnRecycle()
    self:TryUnbindTouchEvent()
    self:TryStopWorkingTimer()
end

function CityWorkProduceUIUnit:OnClose()
    self:TryUnbindTouchEvent()
    self:TryStopWorkingTimer()
end

function CityWorkProduceUIUnit:TryBindTouchEvent()
    if self.binded then return end

    self.binded = true
    g_Game.EventManager:AddListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
end

function CityWorkProduceUIUnit:TryUnbindTouchEvent()
    if not self.binded then return end
    
    self.binded = false
    g_Game.EventManager:RemoveListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
end

function CityWorkProduceUIUnit:OnClickInQueue()
    self._p_btn_reduce:SetVisible(true)
end

function CityWorkProduceUIUnit:OnUITouchUp(gameObj)
    if self._p_btn_queue.gameObject == gameObj then
        return
    end

    if self._p_button_working_menu.gameObject == gameObj then
        return
    end

    self._p_btn_reduce:SetVisible(false)
end

function CityWorkProduceUIUnit:OnClickWorking()
    self._p_btn_reduce:SetVisible(true)
end

function CityWorkProduceUIUnit:OnClickCancel()
    if self.data.status ~= CityWorkProduceUIUnitStatus.InQueue and self.data.status ~= CityWorkProduceUIUnitStatus.Working then
        return
    end
    self.uiMediator:RequestRemoveInQueue(self.data.plan, self._p_btn_reduce.transform)
end

function CityWorkProduceUIUnit:TryStartWorkingTimer()
    if self.workingTimer then return end

    self.workingTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnWorkingTick), 1, -1)
end

function CityWorkProduceUIUnit:TryStopWorkingTimer()
    if not self.workingTimer then return end
    
    TimerUtility.StopAndRecycle(self.workingTimer)
    self.workingTimer = nil
end

function CityWorkProduceUIUnit:OnWorkingTick()
    local castleFurniture = self.data.furniture:GetCastleFurniture()
    self._p_progress_item.value = CityWorkProduceWdsHelper.GetProduceProgress(castleFurniture, self.data.plan)
end

function CityWorkProduceUIUnit:SetCommonTimer()
    self._child_time:SetVisible(not self.paused)
    if not self.paused then
        ---@type CommonTimerData
        self._commonTimerData = self._commonTimerData or {}
        self._commonTimerData.endTime = self.data.plan.FinishTime.ServerSecond
        self._commonTimerData.needTimer = true
        self._child_time:FeedData(self._commonTimerData)
    end
end

return CityWorkProduceUIUnit