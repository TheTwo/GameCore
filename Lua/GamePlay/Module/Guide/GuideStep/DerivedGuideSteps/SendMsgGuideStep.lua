local BaseGuideStep = require("BaseGuideStep")
local GuideUtils = require("GuideUtils")
---@class SendMsgGuideStep : BaseGuideStep
local SendMsgGuideStep = class("SendMsgGuideStep", BaseGuideStep)

function SendMsgGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_SendMsg: %d)', self.id)
    if self.target == nil then
        self:Stop()
    end
    local uiPos, _, uiTrans = GuideUtils.GetTargetUIPos(self.target)
    if uiPos and uiTrans then
        local paramLength = self.cfg:StringParamsLength()
        local strParam = ''
        if paramLength > 0 then
            strParam = self.cfg:StringParams(1)
        end
        uiTrans.gameObject:SendMessage('OnUnityMessage',strParam)
    end
end

return SendMsgGuideStep