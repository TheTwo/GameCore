local BaseTableViewProCell = require ('BaseTableViewProCell')
local CityWorkProcessUIUnitStatus = require('CityWorkProcessUIUnitStatus')
local TimerUtility = require('TimerUtility')
local Delegate = require('Delegate')
local EventConst = require("EventConst")
local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
local CityWorkType = require("CityWorkType")

---@class CityWorkProcessUIUnit:BaseTableViewProCell
---@field uiMediator CityWorkProcessUIMediator
local CityWorkProcessUIUnit = class('CityWorkProcessUIUnit', BaseTableViewProCell)

function CityWorkProcessUIUnit:OnCreate()
    self._statusRecordParent = self:StatusRecordParent("")
    --- Free
    --- InQueue
    self._p_btn_queue = self:Button("p_btn_queue", Delegate.GetOrCreate(self, self.OnClickInQueue))
    self._p_icon_item = self:Image("p_icon_item")
    --- Working
    self._p_progress_item = self:Slider("p_progress_item")
    self._p_btn_working_menu = self:Button("p_btn_working_menu", Delegate.GetOrCreate(self, self.OnClickWorking))
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")
    self._p_text_quantity = self:Text("p_text_quantity")
    --- Collect
    self._p_btn_collect = self:Button("p_btn_collect", Delegate.GetOrCreate(self, self.OnClickCollect))
    --- VX
    self._vx_trigger = self:AnimTrigger("vx_trigger")
    --- Cancel
    self._p_btn_reduce = self:Button("p_btn_reduce", Delegate.GetOrCreate(self, self.OnClickCancel))
    self._p_text_reduce = self:Text("p_text_reduce", "sys_city_39")
end
 
---@param data CityWorkProcessUIUnitData
function CityWorkProcessUIUnit:OnFeedData(data)
    self.data = data
    self.uiMediator = data.uiMediator
    self.paused = self.data.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Process] == nil
    self:Refresh()

    self.uid = data.process ~= nil and data.process.Uid or -1
    if self.uid ~= self.lastUid then
        self._p_btn_reduce:SetVisible(false)
    end
    self.lastUid = self.uid

    self:TryAddEventListener()
    self:TryStopWorkingTimer()
    if self:IsWorking() then
        if not self.paused then
            self:TryAddWorkingTimer()
        end
        self:SetCommonTimer()
    end
end

function CityWorkProcessUIUnit:OnRecycle()
    self:TryRemoveEventListener()
    self:TryStopWorkingTimer()
end

function CityWorkProcessUIUnit:OnClose()
    self:TryRemoveEventListener()
    self:TryStopWorkingTimer()
end

function CityWorkProcessUIUnit:TryAddWorkingTimer()
    if self.workingTimer then return end

    self.workingTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnWorkingTick), 1, -1)
end

function CityWorkProcessUIUnit:TryStopWorkingTimer()
    if not self.workingTimer then return end

    TimerUtility.StopAndRecycle(self.workingTimer)
    self.workingTimer = nil
end

function CityWorkProcessUIUnit:TryAddEventListener()
    if self.added then return end
    self.added = true
    g_Game.EventManager:AddListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
end

function CityWorkProcessUIUnit:TryRemoveEventListener()
    if not self.added then return end
    self.added = false
    g_Game.EventManager:RemoveListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
end

function CityWorkProcessUIUnit:OnUITouchUp(gameObj)
    if self._p_btn_queue.gameObject == gameObj then return end
    if self._p_btn_working_menu.gameObject == gameObj then return end
    self._p_btn_reduce:SetVisible(false)
end

function CityWorkProcessUIUnit:OnClickInQueue()
    self._p_btn_reduce:SetVisible(true)
end

function CityWorkProcessUIUnit:OnClickWorking()
    if self.data.process.FinishNum > 0 then
        self:OnClickCollect()
    else
        self._p_btn_reduce:SetVisible(true)
    end
end

function CityWorkProcessUIUnit:OnClickCollect()
    self.uiMediator:CollectSingleProcess(self.data.process, self._p_btn_collect.transform)
end

function CityWorkProcessUIUnit:IsFree()
    return self.data.status == CityWorkProcessUIUnitStatus.Free
end

function CityWorkProcessUIUnit:IsInQueue()
    return self.data.status == CityWorkProcessUIUnitStatus.InQueue
end

function CityWorkProcessUIUnit:IsFinished()
    return self.data.status == CityWorkProcessUIUnitStatus.Collect
end

function CityWorkProcessUIUnit:IsWorking()
    return self.data.status == CityWorkProcessUIUnitStatus.Working
end

function CityWorkProcessUIUnit:IsForbid()
    return self.data.status == CityWorkProcessUIUnitStatus.Forbid
end

function CityWorkProcessUIUnit:Refresh()
    local statusCode = self:GetStatus()
    self._statusRecordParent:ApplyStatusRecord(statusCode)
    if self:IsFinished() or self:IsWorking() or self:IsInQueue() then
        g_Game.SpriteManager:LoadSprite(self.data:GetIcon(), self._p_icon_item)
    end

    if self:IsFinished() and self.data.needVx then
        self._vx_trigger:PlayAll("PlayFinish")
    end

    if self.data.process then
        if self:IsWorking() then
            if self.data.process.FinishNum == 0 then
                self._p_text_quantity.text = string.Empty
            else
                self._p_text_quantity.text = ("x%d"):format(self.data.process.FinishNum)
            end
        else
            if self.data.process.Auto then
                self._p_text_quantity.text = "∞"
            else
                self._p_text_quantity.text = ("x%d"):format(self.data.process.FinishNum + self.data.process.LeftNum)
            end
        end
    else
        self._p_btn_reduce:SetVisible(false)
    end

    if self:IsWorking() then
        self:OnWorkingTick()
    end
end

function CityWorkProcessUIUnit:GetStatus()
    if self.data.process ~= nil and self.data.process.Auto then
        if self:IsWorking() then
            return 6
        elseif self:IsInQueue() then
            return 7
        end
    end
    return self.data.status
end

function CityWorkProcessUIUnit:IsAutoPaused()
    return self.data.process ~= nil and self.data.process.Auto and not self.data.process.Working
end

function CityWorkProcessUIUnit:OnClickCancel()
    self.uiMediator:RequestRemoveInQueue(self.data.process, self._p_btn_reduce.transform)
end

function CityWorkProcessUIUnit:OnWorkingTick()
    self._p_progress_item.value = CityWorkProcessWdsHelper.GetCityWorkProcessProgress(self.data.furniture:GetCastleFurniture(), self.data.process)
end

function CityWorkProcessUIUnit:SetCommonTimer()
    if self:IsWorking() then
        self._child_time:SetVisible(not self.paused)
        if not self.paused and (not self.data.process.Auto or self.data.process.Working) then
            ---@type CommonTimerData
            self._commomTimerData = self._commomTimerData or {}
            self._commomTimerData.endTime = self.data.process.FinishTime.ServerSecond
            self._commomTimerData.needTimer = true
            self._child_time:FeedData(self._commomTimerData)
        else
            self._commomTimerData = self._commomTimerData or {}
            self._commomTimerData.endTime = 0
            self._commomTimerData.needTimer = false
            self._child_time:FeedData(self._commomTimerData)
        end
    else
        self._child_time:SetVisible(false)
        ---@type CommonTimerData
        self._commomTimerData = self._commomTimerData or {}
        self._commomTimerData.endTime = 0
        self._commomTimerData.needTimer = false
        self._child_time:FeedData(self._commomTimerData)
    end
end

return CityWorkProcessUIUnit