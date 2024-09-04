local CitizenBTDefine = require("CitizenBTDefine")
local KEY = CitizenBTDefine.ContextKey

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTWriteCurrent:CitizenBTActionNode
---@field new fun():CitizenBTWriteCurrent
---@field super CitizenBTActionNode
local CitizenBTWriteCurrent = class('CitizenBTWriteCurrent', CitizenBTActionNode)

function CitizenBTWriteCurrent:Run(context, gContext)
    context:Write(KEY.CurrentKey, context:Read(KEY.DecisionKey))
    context:Write(KEY.CurrentPriority, context:Read(KEY.DecisionPriority))
    context:Write(KEY.DecisionKey)
    context:Write(KEY.DecisionPriority)
    return CitizenBTWriteCurrent.super.Run(self, context, gContext)
end

return CitizenBTWriteCurrent