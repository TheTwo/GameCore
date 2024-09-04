
local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckIsAssigned:CitizenBTNode
---@field new fun():CitizenBTCheckIsAssigned
---@field super CitizenBTNode
local CitizenBTCheckIsAssigned = class('CitizenBTCheckIsAssigned', CitizenBTNode)

function CitizenBTCheckIsAssigned:Run(context, gContext)
    return context:GetCitizenData():IsAssignedHouse(), nil
end

return CitizenBTCheckIsAssigned