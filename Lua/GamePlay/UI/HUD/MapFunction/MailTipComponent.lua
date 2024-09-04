local EventConst = require('EventConst')
local TimerUtility = require('TimerUtility')
local Delegate = require('Delegate')

---@class MailTipComponent
local MailTipComponent = class("MailTipComponent")

local MAIL_BATTLE_REPORT_TIP_SHOW_TIME = 3

---@param parent HUDMapFunctionComponent
function MailTipComponent:Initialize(parent)
    self.mailBattleReportTips = parent:GameObject("p_tips")
    self.mailBattleReportTipText = parent:Text("p_text_tips")
    
    ---@type Timer
    self._mailBattleReportTipsTimer = nil

    -- 战报提示
    self.mailBattleReportTips:SetActive(false)
    if (self._mailBattleReportTipsTimer) then
        self._mailBattleReportTipsTimer:Stop()
    end

    g_Game.EventManager:AddListener(EventConst.MAIL_REPORT_RECEIVED, Delegate.GetOrCreate(self, self.OnMailBattleReportReceived))
end

function MailTipComponent:Dispose()
    g_Game.EventManager:RemoveListener(EventConst.MAIL_REPORT_RECEIVED, Delegate.GetOrCreate(self, self.OnMailBattleReportReceived))
    
    if (self._mailBattleReportTipsTimer) then
        self._mailBattleReportTipsTimer:Stop()
    end
end

function MailTipComponent:OnMailBattleReportReceived(tip)
    self:SetNewMessage(tip)
end

function MailTipComponent:SetNewMessage(text)
    if (self._mailBattleReportTipsTimer) then
        self._mailBattleReportTipsTimer:Stop()
    end
    self.mailBattleReportTips:SetActive(true)
    self.mailBattleReportTipText.text = text
    self._mailBattleReportTipsTimer = TimerUtility.DelayExecute(function()
        self.mailBattleReportTips:SetActive(false)
    end, MAIL_BATTLE_REPORT_TIP_SHOW_TIME)
end

return MailTipComponent