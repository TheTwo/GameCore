
---@class CitizenBTNode
---@field new fun():CitizenBTNode
local CitizenBTNode = class('CitizenBTNode')

function CitizenBTNode:ctor()
    self.IsActionNode = false
end

---@param config CitizenBTNodeConfigCell
function CitizenBTNode:InitFromConfig(config)
    
end

---@param context CitizenBTContext
---@param gContext CitizenBTContext
---@return boolean, CitizenBTNode
function CitizenBTNode:Run(context, gContext)
    return false, nil
end

return CitizenBTNode