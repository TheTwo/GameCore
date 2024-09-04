local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local NotificationType = require("NotificationType")
---@class ShopTabCell:BaseTableViewProCell
local ShopTabCell = class('ShopTabCell',BaseTableViewProCell)

function ShopTabCell:OnCreate()
    ---@type CommonChildTabLeftBtn
    self.child_tab_left_btn = self:LuaObject("child_tab_left_btn")
end

function ShopTabCell:OnFeedData(tabId)
    ---@type CommonChildTabLeftBtnParameter
    local tabCfg = ConfigRefer.Shop:Find(tabId)
    local leftBtnData = {}
    leftBtnData.index = tabId
    leftBtnData.onClick = Delegate.GetOrCreate(self, self.OnBtnClicked)
    leftBtnData.btnName = I18N.Get(tabCfg:Name())
    leftBtnData.onClickLocked = Delegate.GetOrCreate(self, self.OnBtnLockClicked)
    self.isUnlock = true
    if tabCfg:SystemSwitch() and tabCfg:SystemSwitch() > 0 then
        self.isUnlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(tabCfg:SystemSwitch())
        leftBtnData.isLocked = not self.isUnlock
    end
    self.child_tab_left_btn:FeedData(leftBtnData)
    self.child_tab_left_btn:ShowNotificationNode()
    local node = self.child_tab_left_btn:GetNotificationNode()
    self.tabId = tabId
    local redNode = ModuleRefer.NotificationModule:GetDynamicNode("ShopTab" .. tabId, NotificationType.SHOP_FREE_DOT)
    ModuleRefer.NotificationModule:AttachToGameObject(redNode, node.go, node.redDot)
end

function ShopTabCell:OnBtnClicked()
    g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_SHOP_TAB, self.tabId)
end

function ShopTabCell:OnBtnLockClicked()
    if not self.isUnlock then
        local tabCfg = ConfigRefer.Shop:Find(self.tabId)
        local sysEntryCfg = ConfigRefer.SystemEntry:Find(tabCfg:SystemSwitch())
        if sysEntryCfg:LockedTipsPrm() then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams(sysEntryCfg:LockedTips(), sysEntryCfg:LockedTipsPrm()))
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(sysEntryCfg:LockedTips()))
        end
    end
end

function ShopTabCell:Select()
    if self.isUnlock then
        self.child_tab_left_btn:SetStatus(0)
    end
end
function ShopTabCell:UnSelect()
    if self.isUnlock then
        self.child_tab_left_btn:SetStatus(1)
    end
end

return ShopTabCell
