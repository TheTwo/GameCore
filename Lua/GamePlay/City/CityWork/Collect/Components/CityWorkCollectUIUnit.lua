local BaseTableViewProCell = require ('BaseTableViewProCell')
local CityWorkProcessUIUnitStatus = require('CityWorkProcessUIUnitStatus')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local ItemGroupHelper = require("ItemGroupHelper")
local EventConst = require("EventConst")
local TimerUtility = require("TimerUtility")
local CityWorkCollectWdsHelper = require("CityWorkCollectWdsHelper")
local CityWorkType = require("CityWorkType")

---@class CityWorkCollectUIUnit:BaseTableViewProCell
---@field uiMediator CityWorkCollectUIMediator
local CityWorkCollectUIUnit = class('CityWorkCollectUIUnit', BaseTableViewProCell)

function CityWorkCollectUIUnit:OnCreate()
    self._statusRecordParent = self:StatusRecordParent("")
    self._p_btn_queue = self:Button("p_btn_queue", Delegate.GetOrCreate(self, self.OnClickInQueue))
    self._p_icon_item = self:Image("p_icon_item")
    self._p_btn_collect = self:Button("p_btn_collect", Delegate.GetOrCreate(self, self.OnClickCollect))
    self._p_text_quantity = self:Text("p_text_quantity")

    self._p_progress_item = self:Slider("p_progress_item")
    self._p_btn_working_menu = self:Button("p_btn_working_menu", Delegate.GetOrCreate(self, self.OnClickWorking))
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")

    self._p_btn_reduce = self:Button("p_btn_reduce", Delegate.GetOrCreate(self, self.OnClickCancel))
end

---@param data CityWorkCollectUIUnitData
function CityWorkCollectUIUnit:OnFeedData(data)
    self.data = data
    self.uiMediator = data.uiMediator
    self.paused = self.data.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.FurnitureResCollect] == nil
    local statusCode = self:GetStatus()
    self._statusRecordParent:ApplyStatusRecord(statusCode)
    if data.status ~= CityWorkProcessUIUnitStatus.Free and data.status ~= CityWorkProcessUIUnitStatus.Forbid then
        local workCfg = ConfigRefer.CityWork:Find(self.data.info.WorkCfgId)
        for i = 1, workCfg:CollectResListLength() do
            local processCfg = ConfigRefer.CityProcess:Find(workCfg:CollectResList(i))
            if processCfg:CollectResType() == self.data.info.ResourceType then
                g_Game.SpriteManager:LoadSprite(processCfg:OutputIcon(), self._p_icon_item)        
                break
            end
        end
    else
        self._p_btn_reduce:SetVisible(false)
    end
    self:TryAddEventListener()
    self:TryStopWorkingTimer()

    if data.status == CityWorkProcessUIUnitStatus.InQueue then
        self._p_text_quantity.text = self.data.info.Auto and "∞" or ("x%d"):format(self.data.info.TargetCount)
    end

    if data.status == CityWorkProcessUIUnitStatus.Working then
        if not self.paused then
            self:TryStartWorkingTimer()
        end
        self:OnWorkingTick()
        self:SetCommonTimer()
    end
end

function CityWorkCollectUIUnit:GetStatus()
    if self.data.info ~= nil and self.data.info.Auto then
        if self.data.status == CityWorkProcessUIUnitStatus.Working then
            return 6
        elseif self.data.status == CityWorkProcessUIUnitStatus.InQueue then
            return 7
        end
    end
    return self.data.status
end

function CityWorkCollectUIUnit:OnRecycle()
    self:TryRemoveEventListener()
    self:TryStopWorkingTimer()
end

function CityWorkCollectUIUnit:OnClose()
    self:TryRemoveEventListener()
    self:TryStopWorkingTimer()
end

function CityWorkCollectUIUnit:TryStartWorkingTimer()
    if self.workingTimer then return end

    self.workingTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnWorkingTick), 1, -1)
end

function CityWorkCollectUIUnit:TryStopWorkingTimer()
    if not self.workingTimer then return end

    TimerUtility.StopAndRecycle(self.workingTimer)
    self.workingTimer = nil
end

function CityWorkCollectUIUnit:OnWorkingTick()
    if not self.data.info then return end
    local castleFurniture = self.data.furniture:GetCastleFurniture()
    self._p_progress_item.value = CityWorkCollectWdsHelper.GetResCollectProgress(castleFurniture, self.data.info)
    self._p_text_quantity.text = ("x%d"):format(self.data.info.FinishedCount)
end

function CityWorkCollectUIUnit:TryAddEventListener()
    if self.added then return end
    self.added = true
    g_Game.EventManager:AddListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
end

function CityWorkCollectUIUnit:TryRemoveEventListener()
    if not self.added then return end
    self.added = false
    g_Game.EventManager:RemoveListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
end

function CityWorkCollectUIUnit:OnClickCollect()
    self.uiMediator:RequestCollect(self.data.info, self._p_btn_collect.transform)
end

function CityWorkCollectUIUnit:OnUITouchUp(gameObj)
    if self._p_btn_queue.gameObject == gameObj then return end
    if self._p_btn_working_menu.gameObject == gameObj then return end
    self._p_btn_reduce:SetVisible(false)
end

function CityWorkCollectUIUnit:OnClickInQueue()
    self._p_btn_reduce:SetVisible(true)
end

function CityWorkCollectUIUnit:OnClickWorking()
    self._p_btn_reduce:SetVisible(true)
end

function CityWorkCollectUIUnit:OnClickCancel()
    self.uiMediator:RequestCancel(self.data.info, self._p_btn_reduce.transform)
end

function CityWorkCollectUIUnit:SetCommonTimer()
    self._child_time:SetVisible(not self.paused)
    if not self.paused then
        ---@type CommonTimerData
        self._commonTimerData = self._commonTimerData or {}
        self._commonTimerData.endTime = self.data.info.FinishTime.ServerSecond
        self._commonTimerData.needTimer = true
        self._child_time:FeedData(self._commonTimerData)
    end
end

return CityWorkCollectUIUnit