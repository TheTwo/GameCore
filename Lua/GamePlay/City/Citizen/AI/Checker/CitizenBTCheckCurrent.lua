local CitizenBTDefine = require("CitizenBTDefine")
local KEY = CitizenBTDefine.ContextKey

local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckCurrent:CitizenBTNode
---@field new fun():CitizenBTCheckCurrent
---@field super CitizenBTNode
local CitizenBTCheckCurrent = class('CitizenBTCheckCurrent', CitizenBTNode)

function CitizenBTCheckCurrent:Run(context, gContext)
    if context:Read(KEY.ClearFlag) then
        return false, nil
    end
    local DecisionKey = context:Read(KEY.DecisionKey)
    local CurrentKey = context:Read(KEY.CurrentKey)
    if string.IsNullOrEmpty(DecisionKey) then
        return false, nil
    end
    if CurrentKey == DecisionKey then
        return true, nil
    end
    if string.IsNullOrEmpty(CurrentKey) then
        return true, nil
    end
    local DecisionPriority = context:Read(KEY.DecisionPriority)
    local CurrentPriority = context:Read(KEY.CurrentPriority)
    if CurrentPriority and (not DecisionPriority or CurrentPriority >= DecisionPriority)  then
        return false, nil
    end
    return true, nil
end

return CitizenBTCheckCurrent