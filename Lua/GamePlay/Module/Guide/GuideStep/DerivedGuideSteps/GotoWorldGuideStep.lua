local BaseGuideStep = require("BaseGuideStep")
local KingdomMapUtils = require("KingdomMapUtils")
---@class GotoWorldGuideStep : BaseGuideStep
local GotoWorldGuideStep = class("GotoWorldGuideStep", BaseGuideStep)

function GotoWorldGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_GotoKingdom: %d)', self.id)
    KingdomMapUtils.GetKingdomScene():LeaveCity(function()
        self:End()
    end)
end

return GotoWorldGuideStep