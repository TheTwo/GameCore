
local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckIsCurrentWorkValid:CitizenBTNode
---@field new fun():CitizenBTCheckIsCurrentWorkValid
---@field super CitizenBTNode
local CitizenBTCheckIsCurrentWorkValid = class('CitizenBTCheckIsCurrentWorkValid', CitizenBTNode)

function CitizenBTCheckIsCurrentWorkValid:Run(context, gContext)
    return context:GetCitizenData():IsWorkingWithInfection(), nil
end

return CitizenBTCheckIsCurrentWorkValid