local BaseGuideStep = require('BaseGuideStep')
local TimerUtility = require('TimerUtility')
---@class WaitGuideStep : BaseGuideStep
local WaitGuideStep = class('WaitGuideStep', BaseGuideStep)

function WaitGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_Wait: %d)', self.id)
    local waitDraution = 0
    if self.cfg:StringParamsLength() > 0 then
        waitDraution = tonumber(self.cfg:StringParams(1))
    else
        g_Logger.ErrorChannel('GuideModule','[<color=red>%s</color>]GuideStep(%d) Wait参数为空', g_Logger.SpChar_Wrong, self.id)
    end
    if waitDraution and waitDraution > 0 then
        self:ShowGuideFinger(true)
        TimerUtility.DelayExecute(function()
            self:End()
        end
        , waitDraution)
    else
        self:Stop()
    end
end

return WaitGuideStep