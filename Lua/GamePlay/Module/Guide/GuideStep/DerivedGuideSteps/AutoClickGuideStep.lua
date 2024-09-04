local BaseGuideStep = require("BaseGuideStep")
local GuideUtils = require("GuideUtils")
---@class AutoClickGuideStep : BaseGuideStep
local AutoClickGuideStep = class("AutoClickGuideStep", BaseGuideStep)

function AutoClickGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_AutoClick: %d)', self.id)
    if self.target == nil then
        self:Stop()
    end
    local uiPos, _, uiTrans = GuideUtils.GetTargetUIPos(self.target)
    if uiPos then
        GuideUtils.SimulatClickTarget(self.target.type, uiTrans, uiPos, self.target.offset)
    end
end

return AutoClickGuideStep