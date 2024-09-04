
local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionWriteSignUpgradeCoreMark:CitizenBTActionNode
---@field new fun():CitizenBTActionWriteSignUpgradeCoreMark
---@field super CitizenBTActionNode
local CitizenBTActionWriteSignUpgradeCoreMark = class("CitizenBTActionWriteSignUpgradeCoreMark", CitizenBTActionNode)

function CitizenBTActionWriteSignUpgradeCoreMark:InitFromConfig(config)
    self._isAdd = config:IntParamLength() > 0 and config:IntParam(1) > 0
end

function CitizenBTActionWriteSignUpgradeCoreMark:Run(context, gContext)
    if self._isAdd then
        context:GetMgr():AddSignForCoreUpgrade(context:GetCitizenId())
    else
        context:GetMgr():RemoveSignForCoreUpgrade(context:GetCitizenId())
    end
    return CitizenBTActionWriteSignUpgradeCoreMark.super.Run(self, context, gContext)
end

return CitizenBTActionWriteSignUpgradeCoreMark