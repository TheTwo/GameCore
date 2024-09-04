local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local NotificationType = require('NotificationType')
local BattlePassConst = require('BattlePassConst')
local ActivityRewardType = require('ActivityRewardType')
---@class HUDBattlePass : BaseUIComponent
local HUDBattlePass = class('HUDBattlePass', BaseUIComponent)

function HUDBattlePass:OnCreate()
    self.goRoot = self:GameObject('')
    self.btnBattlePass = self:Button('p_btn_battlepass', Delegate.GetOrCreate(self, self.OnBtnBattlePassClicked))
    self.textBattlePass = self:Text('p_text_battlepass', BattlePassConst.I18N_KEYS.HUD)
    self.notifyNode = self:LuaObject('child_reddot_default')
end

function HUDBattlePass:OnShow()
    local reddotNode = ModuleRefer.NotificationModule:GetDynamicNode(BattlePassConst.NOTIFY_NAMES.ENTRY, NotificationType.BATTLEPASS_HUD)
    ModuleRefer.NotificationModule:AttachToGameObject(reddotNode, self.notifyNode.go, self.notifyNode.redDot)
    self:UpdateShow()
end

function HUDBattlePass:UpdateShow()
    local isOpen = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.BattlePass) > 0
    self.goRoot:SetActive(isOpen)
end

function HUDBattlePass:OnBtnBattlePassClicked()
    g_Game.UIManager:Open(UIMediatorNames.BattlePassMainMediator)
end

return HUDBattlePass