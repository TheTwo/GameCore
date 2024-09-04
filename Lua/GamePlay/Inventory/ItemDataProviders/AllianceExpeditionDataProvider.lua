local FunctionalItemDataProvider = require("FunctionalItemDataProvider")
local ModuleRefer = require("ModuleRefer")
---@class AllianceExpeditionDataProvider : FunctionalItemDataProvider
local AllianceExpeditionDataProvider = class("AllianceExpeditionDataProvider", FunctionalItemDataProvider)

function AllianceExpeditionDataProvider:CanUse()
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    return self:DefaultUseChecker() and allianceInfo
end

function AllianceExpeditionDataProvider:Use(usageNum, callback)
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceInfo then
        return
    else
        ModuleRefer.WorldEventModule:ValidateItemUse(nil, usageNum, self.uid)
    end
end

return AllianceExpeditionDataProvider