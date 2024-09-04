local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckActionInteractTask:CitizenBTNode
---@field new fun():CitizenBTCheckActionInteractTask
---@field super CitizenBTNode
local CitizenBTCheckActionInteractTask = class('CitizenBTCheckActionInteractTask', CitizenBTNode)

function CitizenBTCheckActionInteractTask:Run(context, gContext)
    return gContext:Read(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId) == context:GetCitizenData()._id
end

return CitizenBTCheckActionInteractTask