local BaseGuideStep = require("BaseGuideStep")
local GuideUtils = require("GuideUtils")
local CitizenBTDefine = require("CitizenBTDefine")
---@class PauseCitizenGuideStep : BaseGuideStep
local PauseCitizenGuideStep = class("PauseCitizenGuideStep", BaseGuideStep)

function PauseCitizenGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_FocusTableViewProCell: %d)', self.id)
    local strParam = self.cfg:StringParams(1)
    local citizenId = (not string.IsNullOrEmpty(strParam)) and tonumber(strParam) or 0
    if citizenId == 0 then
        g_Logger.Error('GuideModule','ExeGuideStep_PauseCitizen 参数 StringParams1:%s 不是一个id', strParam)
        self:Stop()
        return
    end
    local city = GuideUtils.FindMyCity()
    local citizenData = city.cityCitizenManager:GetCitizenDataById(citizenId)
    if not citizenData then
        self:Stop()
        g_Logger.Error('GuideModule','ExeGuideStep_PauseCitizen citizenId:%s 没有对应的居民', citizenId)
        return
    end
    city.cityCitizenManager:WriteGlobalContext(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId, citizenId)
    self:End()
end

return PauseCitizenGuideStep