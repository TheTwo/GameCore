local CitizenBTDefine = require("CitizenBTDefine")

---@class CitizenBehaviourTree
---@field new fun():CitizenBehaviourTree
local CitizenBehaviourTree = sealedClass('CitizenBehaviourTree')

---@param rootNode CitizenBTNode
---@param context CitizenBTContext
---@param gContext CitizenBTContext
function CitizenBehaviourTree.Run(rootNode, context, gContext)
    local accept, node = rootNode:Run(context, gContext)
    if not accept then return end
    CitizenBehaviourTree.SetCurrentActionNode(context, gContext, node)
end

---@param context CitizenBTContext
---@param gContext CitizenBTContext
---@param actionNode CitizenBTActionNode
function CitizenBehaviourTree.SetCurrentActionNode(context, gContext, actionNode)
    local currentNode = context:GetCurrentNode()
    if currentNode == actionNode then return end
    if currentNode then 
        currentNode:Exit(context, gContext)
    end
    context:SetCurrentNode(actionNode)
    if not actionNode or not actionNode.Enter then return end
    actionNode:Enter(context, gContext)
end

---@param context CitizenBTContext
---@param gContext CitizenBTContext
function CitizenBehaviourTree.Tick(context, gContext, dt, nowTime)
    local currentNode = context:GetCurrentNode()
    if not currentNode then return end
    if currentNode:Tick(dt, nowTime, context, gContext) then
        CitizenBehaviourTree.SetCurrentActionNode(context, gContext, nil)
        context:Write(CitizenBTDefine.ContextKey.ClearFlag, true)
    end
end

return CitizenBehaviourTree