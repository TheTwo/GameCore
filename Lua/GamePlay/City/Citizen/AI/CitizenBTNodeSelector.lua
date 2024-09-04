local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTNodeSelector:CitizenBTNode
---@field new fun():CitizenBTNodeSelector
---@field super CitizenBTNode
local CitizenBTNodeSelector = class('CitizenBTNodeSelector', CitizenBTNode)

function CitizenBTNodeSelector:ctor()
    CitizenBTNodeSelector.super.ctor(self)
    ---@type CitizenBTNode[]
    self._children = {}
end

---@param node CitizenBTNode
function CitizenBTNodeSelector:AddChild(node)
    table.insert(self._children, node)
end

function CitizenBTNodeSelector:Run(context, gContext)
    for _, v in ipairs(self._children) do
        local accept, node = v:Run(context, gContext)
        if accept then
            return true, node
        end
    end
    return false, nil
end

return CitizenBTNodeSelector