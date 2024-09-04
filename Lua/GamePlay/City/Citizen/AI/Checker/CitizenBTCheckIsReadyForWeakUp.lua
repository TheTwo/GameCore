
local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckIsReadyForWeakUp:CitizenBTNode
---@field new fun():CitizenBTCheckIsReadyForWeakUp
---@field super CitizenBTNode
local CitizenBTCheckIsReadyForWeakUp = class('CitizenBTCheckIsReadyForWeakUp', CitizenBTNode)

function CitizenBTCheckIsReadyForWeakUp:Run(context, gContext)
    return context:GetCitizenData():IsReadyForWeakUp()
end

return CitizenBTCheckIsReadyForWeakUp