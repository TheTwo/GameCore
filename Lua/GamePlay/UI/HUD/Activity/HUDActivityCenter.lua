local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local NotificationType = require('NotificationType')
local ModuleRefer = require('ModuleRefer')
---@class HUDActivityCenter : BaseUIComponent
local HUDActivityCenter = class('HUDActivityCenter', BaseUIComponent)

function HUDActivityCenter:OnCreate()
    self.goRoot = self:GameObject('')
    self.btnActivityCenter = self:Button('p_btn_activity_center', Delegate.GetOrCreate(self, self.OnBtnActivityCenterClicked))
    self.textActivityCenter = self:Text('p_text_activity_center', 'activity_center_hun_name')
    self.notifyNode = self:LuaObject('child_reddot_default')
end

function HUDActivityCenter:OnShow()
    local notifyLogicNode = ModuleRefer.NotificationModule:GetDynamicNode(
        'ActivityCenterEntry', NotificationType.ACTIVITY_CENTER_HUD)
    ModuleRefer.NotificationModule:AttachToGameObject(notifyLogicNode, self.notifyNode.go, self.notifyNode.redDot)
    ModuleRefer.ActivityCenterModule:InitRedDot()
end

function HUDActivityCenter:OnBtnActivityCenterClicked()
    g_Game.UIManager:Open(UIMediatorNames.ActivityCenterMediator)
end

return HUDActivityCenter