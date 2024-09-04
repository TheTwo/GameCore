
local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckIsFainting:CitizenBTNode
---@field new fun():CitizenBTCheckIsFainting
---@field super CitizenBTNode
local CitizenBTCheckIsFainting = class('CitizenBTCheckIsFainting', CitizenBTNode)

function CitizenBTCheckIsFainting:Run(context, gContext)
    return context:GetCitizenData():IsFainting(), nil
end

return CitizenBTCheckIsFainting