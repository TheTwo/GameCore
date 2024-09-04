local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local ModuleRefer = require("ModuleRefer")
local TaskItemDataProvider = require("TaskItemDataProvider")
local TaskListSortHelper = require("TaskListSortHelper")
local TaskLinkDataProvider = require("TaskLinkDataProvider")
local EventConst = require("EventConst")
---@class ActivityFirePlan : BaseUIComponent
local ActivityFirePlan = class("ActivityFirePlan", BaseUIComponent)

---@class ActivityFirePlanData
---@field tabId number

function ActivityFirePlan:ctor()
end

function ActivityFirePlan:OnCreate()
    self.textTitle = self:Text("p_text_title", "worldstage_operation_tinder")
    self.textDesc = self:Text("p_text_describe", "worldstage_operation_tinder_des")
    self.textTimer = self:Text("p_text_time")

    self.btnShop = self:Button("p_btn_shop", Delegate.GetOrCreate(self, self.OnBtnShopClick))
    self.textBtnShop = self:Text("p_text_shop", "worldstage_tinder_store")
    self.tableTask = self:TableViewPro("p_table_item")

    self.goBtnDetail = self:GameObject("child_comp_btn_detail")
    self.goBtnDetail:SetActive(false)
end

---@param param ActivityFirePlanData
function ActivityFirePlan:OnFeedData(param)
    self.tabId = param.tabId
    self.tabCfg = ConfigRefer.ActivityCenterTabs:Find(self.tabId)
    self.actCfg = ConfigRefer.ActivityRewardTable:Find(self.tabCfg:RefActivityReward())
    if not self.actCfg then
        g_Logger.ErrorChannel("ActivityVillageCompetition", "未关联到ActivityRewardTable, 活动tabId: %d", self.tabId)
        return
    end
    self.cfg = ConfigRefer.FirePlan:Find(self.actCfg:RefConfig())
    if not self.cfg then
        g_Logger.ErrorChannel("ActivityVillageCompetition", "未关联到FirePlan, 活动tabId: %d", self.tabId)
        return
    end
    self.tick = true
    self:OnTimerTick()
    self:UpdateTasks()
end

function ActivityFirePlan:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTimerTick))
    g_Game.EventManager:AddListener(EventConst.ON_FIRE_PLAN_TASK_LINK_FINISH, Delegate.GetOrCreate(self, self.UpdateTasks))
end

function ActivityFirePlan:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTimerTick))
    g_Game.EventManager:RemoveListener(EventConst.ON_FIRE_PLAN_TASK_LINK_FINISH, Delegate.GetOrCreate(self, self.UpdateTasks))
end

function ActivityFirePlan:UpdateTasks()
    local taskLinks = {}
    self.tableTask:Clear()
    for i = 1, self.cfg:RelatedTaskLength() do
        local taskLink = self.cfg:RelatedTask(i)
        local taskLinkDataProvider = TaskLinkDataProvider.new(taskLink)
        table.insert(taskLinks, taskLinkDataProvider)
    end
    table.sort(taskLinks, function(a, b)
        if a:LinkFinished() and not b:LinkFinished() then
            return false
        elseif not a:LinkFinished() and b:LinkFinished() then
            return true
        elseif a:Claimable() and not b:Claimable() then
            return true
        elseif not a:Claimable() and b:Claimable() then
            return false
        else
            return a:GetTaskLinkId() < b:GetTaskLinkId()
        end
    end)
    for _, taskLinkDataProvider in ipairs(taskLinks) do
        self.tableTask:AppendData(taskLinkDataProvider)
    end

    ModuleRefer.ActivityCenterModule:UpdateRedDotByTabId(self.tabId)
end

function ActivityFirePlan:OnTimerTick()
    if self.tick then
        local _, endTimeStamp = ModuleRefer.ActivityCenterModule:GetActivityTabStartEndTime(self.tabId)
        local now = g_Game.ServerTime:GetServerTimestampInSeconds()
        local time = math.clamp(endTimeStamp.Seconds - now, 0, math.huge)
        self.textTimer.text = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(time)

        if time <= 0 then
            self.tick = false
        end
    end
end

function ActivityFirePlan:OnBtnShopClick()
    g_Game.EventManager:TriggerEvent(EventConst.ON_FIRE_PLAN_BTN_SHOP_CLICK)
end

return ActivityFirePlan