local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EventConst = require('EventConst')
local TimerUtility = require('TimerUtility')
local ModuleRefer = require('ModuleRefer')
local NotificationType = require('NotificationType')
local Utils = require('Utils')
---@class ActivityCenterTabCell : BaseTableViewProCell
local ActivityCenterTabCell = class('ActivityCenterTabCell',BaseTableViewProCell)

---@class ActivityCenterTabCellData
---@field id number
---@field tabId number

function ActivityCenterTabCell:OnCreate(param)
    self.btnTab = self:Button('p_btn_tab', Delegate.GetOrCreate(self, self.OnBtnTabClicked))
    self.textTab = self:Text('p_text_tab')
    self.goImgSelect = self:GameObject('p_img_select')
    self.textTabSelect = self:Text('p_text_tab_select')
    self._animation = self:BindComponent("", typeof(CS.UnityEngine.Animation))
    self.notifyNode = self:LuaObject('child_reddot_default')
end

function ActivityCenterTabCell:OnFeedData(param)
    if not param then
        return
    end
    if Utils.IsNull(self.textTab) then
        self:OnCreate()
    end
    local title
    local tabCfg = ConfigRefer.ActivityCenterTabs:Find(param.id)
    local actCfg = ConfigRefer.ActivityRewardTable:Find(tabCfg:RefActivityReward())
    if actCfg then
        title = actCfg:Name()
    elseif tabCfg and not Utils.IsNullOrEmpty(tabCfg:TitleKey()) then
        title = I18N.Get(tabCfg:TitleKey())
    else
        title = '*页面名未配置'
    end
    self.textTab.text = I18N.Get(title)
    self.textTabSelect.text = I18N.Get(title)
    self.tabType = param.id
    local notifyLogicNode = ModuleRefer.NotificationModule:GetDynamicNode(
        'ActivityCenterTab_' .. self.tabType, NotificationType.ACTIVITY_CENTER_TAB)
    ModuleRefer.NotificationModule:AttachToGameObject(notifyLogicNode, self.notifyNode.go, self.notifyNode.redDot)

    self.delayedTimers = {}
end

function ActivityCenterTabCell:OnHide()
    for _, timer in ipairs(self.delayedTimers or {}) do
        TimerUtility.StopAndRecycle(timer)
    end
    self.delayedTimers = {}
end

function ActivityCenterTabCell:OnBtnTabClicked(args)
    self:SelectSelf()
end

function ActivityCenterTabCell:Select(param)
    if Utils.IsNull(self.goImgSelect) then
        return
    end
    self.goImgSelect:SetActive(true)
    self.textTab.gameObject:SetActive(false)
    self.goImgSelect:SetVisible(false)
    local timer = TimerUtility.DelayExecuteInFrame(function()
        self.goImgSelect:SetVisible(true)
        if self._animation then
            self._animation:Play('anim_vx_ui_shop_main_tab_open')
        end
    end, 1)
    table.insert(self.delayedTimers, timer)
    g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_ACTIVITY_CENTER_TAB, self.tabType)
end

function ActivityCenterTabCell:UnSelect(param)
    self:PlayUIAnimWithFinishCallBack('anim_vx_ui_shop_main_tab_close', function()
        if Utils.IsNotNull(self.goImgSelect) then
            self.goImgSelect:SetActive(false)
            self.textTab.gameObject:SetActive(true)
        end
    end)
end

function ActivityCenterTabCell:PlayUIAnimWithFinishCallBack(animName, callback)
    if not self._animation then
        return
    end
    local animationClip = self._animation:GetClip(animName)
    if not animationClip then
        if callback then
            callback()
        end
        return
    end
    local length = animationClip.length
    self._animation:Play(animName)
    if callback then
        if length then
            local timer = TimerUtility.DelayExecute(callback, length)
            table.insert(self.delayedTimers, timer)
        else
            --
        end
    end
end

return ActivityCenterTabCell
