local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EventConst = require('EventConst')
local TimerUtility = require('TimerUtility')
local ModuleRefer = require('ModuleRefer')
local ActivityShopConst = require('ActivityShopConst')
local NotificationType = require('NotificationType')
local Utils = require('Utils')
local ActivityShopTabCell = class('ActivityShopTabCell',BaseTableViewProCell)

---@class ActivityShopTabCellParam
---@field id number

function ActivityShopTabCell:OnCreate(param)
    self.btnTab = self:Button('p_btn_tab', Delegate.GetOrCreate(self, self.OnBtnTabClicked))
    self.textTab = self:Text('p_text_tab')
    self.goImgSelect = self:GameObject('p_img_select')
    self.textTabSelect = self:Text('p_text_tab_select')
    self._animation = self:BindComponent("", typeof(CS.UnityEngine.Animation))

    self.notifyNode = self:LuaObject('child_reddot_default')
end

---@param param ActivityShopTabCellParam
function ActivityShopTabCell:OnFeedData(param)
    if not param then
        return
    end

    if Utils.IsNull(self.textTab) then
        self:OnCreate()
    end

    local tabCfg = ConfigRefer.PayTabs:Find(param.id)
    self.textTab.text = I18N.Get(tabCfg:Name())
    self.textTabSelect.text = I18N.Get(tabCfg:Name())
    self.tabType = param.id
    local notifyLogicNode = ModuleRefer.NotificationModule:GetDynamicNode(
        ActivityShopConst.NotificationNodeNames.ActivityShopTab .. self.tabType, NotificationType.ACTIVITY_SHOP_TAB)
    ModuleRefer.NotificationModule:AttachToGameObject(notifyLogicNode, self.notifyNode.go, self.notifyNode.redDot)
end

function ActivityShopTabCell:OnBtnTabClicked(args)
    self:SelectSelf()
end

function ActivityShopTabCell:Select(param)
    if Utils.IsNotNull(self.goImgSelect) then
        self.goImgSelect:SetActive(true)
        self.textTab.gameObject:SetActive(false)
        self.goImgSelect:SetVisible(false)
        TimerUtility.DelayExecuteInFrame(function()
            if Utils.IsNotNull(self.goImgSelect) then
                self.goImgSelect:SetVisible(true)
                if self._animation then
                    self._animation:Play('anim_vx_ui_tab_yellow_in')
                end
            end
        end, 1)
        g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_ACTIVITY_TAB, self.tabType)
    end
end

function ActivityShopTabCell:UnSelect(param)
    if Utils.IsNotNull(self.goImgSelect) then
        self.goImgSelect:SetActive(false)
        self.textTab.gameObject:SetActive(true)
    end
end

function ActivityShopTabCell:PlayUIAnimWithFinishCallBack(animName, callback)
    if not self._animation then
        return
    end
    local animationClip = self._animation:GetClip(animName)
    local length = animationClip.length
    self._animation:Play(animName)
    if callback then
        if length then
            TimerUtility.DelayExecute(callback, length)
        else
            --
        end
    end
end

return ActivityShopTabCell
