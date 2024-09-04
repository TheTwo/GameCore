local BaseGuideStep = require('BaseGuideStep')
---@class UIClickGuideStep : BaseGuideStep
local UIClickGuideStep = class('UIClickGuideStep', BaseGuideStep)

function UIClickGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_UIClick: %d)', self.id)
    self:ShowGuideFinger()
end

return UIClickGuideStep