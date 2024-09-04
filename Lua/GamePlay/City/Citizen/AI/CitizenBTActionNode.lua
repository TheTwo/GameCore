
local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTActionNode:CitizenBTNode
---@field new fun():CitizenBTActionNode
---@field super CitizenBTNode
local CitizenBTActionNode = class('CitizenBTActionNode', CitizenBTNode)

function CitizenBTActionNode:ctor()
    CitizenBTActionNode.super.ctor(self)
    self.IsActionNode = true
end

---@param context CitizenBTContext
---@param gContext CitizenBTContext
function CitizenBTActionNode:Run(context, gContext)
    return true, self
end

---@param context CitizenBTContext
---@param gContext CitizenBTContext
function CitizenBTActionNode:Enter(context, gContext)
    
end

---@param dt number
---@param nowTime number
---@param context CitizenBTContext
---@param gContext CitizenBTContext
---@return boolean @isExit
function CitizenBTActionNode:Tick(dt, nowTime, context, gContext)
    return true
end

---@param context CitizenBTContext
---@param gContext CitizenBTContext
function CitizenBTActionNode:Exit(context, gContext)
    
end

return CitizenBTActionNode