local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTActionNode = require("CitizenBTNode")

---@class CitizenBTActionClear:CitizenBTActionNode
---@field new fun():CitizenBTActionClear
---@field super CitizenBTActionNode
local CitizenBTActionClear = class('CitizenBTActionClear', CitizenBTActionNode)

function CitizenBTActionClear:Run(context, gContext)
    context:Write(CitizenBTDefine.ContextKey.ClearFlag, nil)
    context:Write(CitizenBTDefine.ContextKey.CurrentPriority, 0)
    context:Write(CitizenBTDefine.ContextKey.CurrentKey, nil)
    context:Write(CitizenBTDefine.ContextKey.DecisionPriority, nil)
    context:Write(CitizenBTDefine.ContextKey.DecisionKey, nil)
    context:Write(CitizenBTDefine.ContextKey.PlayClipInfo, nil)
    context:Write(CitizenBTDefine.ContextKey.PreferRun, nil)
    context:Write(CitizenBTDefine.ContextKey.OverrideTagsMask, nil)
    context:BindInteractPoint(nil)
    context:ClearOp()
    context:ClearDirty()
    return true, nil
end

return CitizenBTActionClear