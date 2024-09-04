local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local ModuleRefer = require('ModuleRefer')
local NotificationType = require('NotificationType')
local NoviceConst = require('NoviceConst')
local DBEntityPath = require('DBEntityPath')
---@class HUDNoviceButton : BaseUIComponent
local HUDNoviceButton = class('HUDNoviceButton', BaseUIComponent)

function HUDNoviceButton:OnCreate()
    self.goRoot = self:GameObject('')
    self.btnNoviceTask = self:Button('p_btn_novice_task', Delegate.GetOrCreate(self, self.OnBtnNoviceTaskClicked))
    self.textNoviceTask = self:Text('p_text_novice_task', I18N.Get(NoviceConst.I18NKeys.HUD_TITLE))
    self.notifyNode = self:LuaObject('child_reddot_default')
end

function HUDNoviceButton:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerActivityReward.Data.MsgPath,
                                        Delegate.GetOrCreate(self, self.UpdateShow))
    local notifyNode = ModuleRefer.NotificationModule:GetDynamicNode(
        NoviceConst.NoviceNotificationNodeNames.NoviceEntry, NotificationType.NOVICE_HUD)
    ModuleRefer.NotificationModule:AttachToGameObject(notifyNode, self.notifyNode.go, self.notifyNode.redDot)
    self:UpdateShow()
end

function HUDNoviceButton:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerActivityReward.Data.MsgPath,
                                        Delegate.GetOrCreate(self, self.UpdateShow))
end

function HUDNoviceButton:UpdateShow()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local isUnlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NoviceConst.SYS_SWITCH_ID)
                        and player.PlayerWrapper2.PlayerActivityReward.Data[NoviceConst.ActivityId].OpenState == 1
    self.goRoot:SetActive(isUnlock)
end

function HUDNoviceButton:OnBtnNoviceTaskClicked()
    g_Game.UIManager:Open(UIMediatorNames.NoviceTaskMediator)
end


return HUDNoviceButton