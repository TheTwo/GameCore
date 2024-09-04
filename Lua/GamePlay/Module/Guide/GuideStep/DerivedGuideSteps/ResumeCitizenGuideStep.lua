local BaseGuideStep = require("BaseGuideStep")
local CitizenBTDefine = require("CitizenBTDefine")
---@class ResumeCitizenGuideStep : BaseGuideStep
local ResumeCitizenGuideStep = class("ResumeCitizenGuideStep", BaseGuideStep)

function ResumeCitizenGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_ResumeCitizen: %d)', self.cfg:Id())
    local city = self:FindMyCity()
    city.cityCitizenManager:WriteGlobalContext(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId, nil)
    self:End()
end

return ResumeCitizenGuideStep