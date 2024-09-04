local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckTrue:CitizenBTNode
---@field new fun():CitizenBTCheckTrue
---@field super CitizenBTNode
local CitizenBTCheckTrue = class('CitizenBTCheckTrue', CitizenBTNode)

function CitizenBTCheckTrue:Run(context, gContext)
    return true
end

return CitizenBTCheckTrue