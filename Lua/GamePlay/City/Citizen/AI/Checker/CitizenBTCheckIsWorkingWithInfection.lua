
local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckIsWorkingWithInfection:CitizenBTNode
---@field new fun():CitizenBTCheckIsWorkingWithInfection
---@field super CitizenBTNode
local CitizenBTCheckIsWorkingWithInfection = class('CitizenBTCheckIsWorkingWithInfection', CitizenBTNode)

function CitizenBTCheckIsWorkingWithInfection:Run(context, gContext)
    return context:GetCitizenData():IsWorkingWithInfection()
end

return CitizenBTCheckIsWorkingWithInfection