local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTNodeSequence:CitizenBTNode
---@field new fun():CitizenBTNodeSequence
---@field super CitizenBTNode
local CitizenBTNodeSequence = class('CitizenBTNodeSequence', CitizenBTNode)

function CitizenBTNodeSequence:ctor()
    CitizenBTNodeSequence.super.ctor(self)
    ---@type CitizenBTNode[]
    self._children = {}
end

function CitizenBTNodeSequence:AddChild(node)
    table.insert(self._children, node)
end

function CitizenBTNodeSequence:Run(context, gContext)
    local accept, node = false, nil
    for _, v in ipairs(self._children) do
        accept, node = v:Run(context, gContext)
        if not accept then
            return false, nil
        end
    end
    return accept, node
end

return CitizenBTNodeSequence