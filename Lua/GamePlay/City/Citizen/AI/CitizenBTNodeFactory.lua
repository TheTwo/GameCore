local CitizenBTNode = require("CitizenBTNode") 
local CitizenBTNodeSelector = require("CitizenBTNodeSelector")
local CitizenBTNodeSequence = require("CitizenBTNodeSequence")
local CitizenBTActionClear = require("CitizenBTActionClear")
local CitizenBTCheckIsFainting = require("CitizenBTCheckIsFainting")
local CitizenBTWriteContext = require("CitizenBTWriteContext")
local CitizenBTCheckContext = require("CitizenBTCheckContext")
local CitizenBTDefine = require("CitizenBTDefine")
local CitizenBTActionFainting = require("CitizenBTActionFainting")
local CitizenBTCheckCurrent = require("CitizenBTCheckCurrent")
local CitizenBTWriteCurrent = require("CitizenBTWriteCurrent")
local CitizenBTActionIdle = require("CitizenBTActionIdle")
local CitizenBTCheckHasWork = require("CitizenBTCheckHasWork")
local CitizenBTActionWork = require("CitizenBTActionWork")
local CitizenBTCheckEscape = require("CitizenBTCheckEscape")
local CitizenBTActionEscape = require("CitizenBTActionEscape")
local CitizenBTActionGroup = require("CitizenBTActionGroup")
local CitizenBTActionSequence = require("CitizenBTActionSequence")
local CitizenBTCheckActionInteractTask = require("CitizenBTCheckActionInteractTask")
local CitizenBTActionInteractTask = require("CitizenBTActionInteractTask")
local KEY = CitizenBTDefine.ContextKey
local ConfigRefer = require("ConfigRefer")

---@class CitizenBTNodeFactory
---@field new fun():CitizenBTNodeFactory
local CitizenBTNodeFactory = class('CitizenBTNodeFactory')

---@type table<number, CitizenBTNode>
CitizenBTNodeFactory.CachedLogic = {}

function CitizenBTNodeFactory.CreateDefault()
    return CitizenBTNode.new()
end

---@param citizen CityCitizenData
function CitizenBTNodeFactory.CreateForCitizen(citizen)
    local rootNode = CitizenBTNodeSelector.new()
    local decisionNode = CitizenBTNodeSequence.new()
    local actionNode = CitizenBTNodeSelector.new()
    rootNode:AddChild(decisionNode)
    rootNode:AddChild(actionNode)
    -- decisionNode part
    local decisionStart = CitizenBTNodeSelector.new()
    decisionNode:AddChild(decisionStart)
    local decisionInPerCheck = CitizenBTNodeSequence.new()
    decisionStart:AddChild(decisionInPerCheck)
    decisionInPerCheck:AddChild(CitizenBTCheckContext.new(KEY.ForcePerformanceActionGroupId, nil, "=="))
    local decisionBuiltInPerSelector = CitizenBTNodeSelector.new()
    decisionInPerCheck:AddChild(decisionBuiltInPerSelector)
    -- fainting
    CitizenBTNodeFactory.BuildCheckNode(decisionBuiltInPerSelector, CitizenBTCheckIsFainting.new(), CitizenBTDefine.BuiltInAction.CitizenBTActionFainting, 100)
    -- task interact
    CitizenBTNodeFactory.BuildCheckNode(decisionBuiltInPerSelector, CitizenBTCheckActionInteractTask.new(), CitizenBTDefine.BuiltInAction.CitizenBTActionInteractTask, 99)
    -- work
    CitizenBTNodeFactory.BuildCheckNode(decisionBuiltInPerSelector, CitizenBTCheckHasWork.new(), CitizenBTDefine.BuiltInAction.CitizenBTActionWork, 90)
    -- escape
    CitizenBTNodeFactory.BuildCheckNode(decisionBuiltInPerSelector, CitizenBTCheckEscape.new(), CitizenBTDefine.BuiltInAction.CitizenBTActionEscape, 80)
    -- for config
    local configCheckerEntry = CitizenBTNodeSelector.new()
    decisionStart:AddChild(configCheckerEntry)
    -- idle
    CitizenBTNodeFactory.BuildCheckNode(decisionStart, nil, CitizenBTDefine.BuiltInAction.CitizenBTActionIdle, 0)
    decisionNode:AddChild(CitizenBTNode.new())
    
    -- actionNode part
    local actionStart = CitizenBTNodeSequence.new()
    actionNode:AddChild(actionStart)
    local checkEnterAction = CitizenBTCheckCurrent.new()
    actionStart:AddChild(checkEnterAction)
    local actionSelector = CitizenBTNodeSelector.new()
    actionSelector.name = "actionSelector"
    actionStart:AddChild(actionSelector)

    -- fainting
    CitizenBTNodeFactory.BuildActionNode(actionSelector, CitizenBTDefine.BuiltInAction.CitizenBTActionFainting, CitizenBTActionFainting.new())
    -- task interact
    CitizenBTNodeFactory.BuildActionNode(actionSelector, CitizenBTDefine.BuiltInAction.CitizenBTActionInteractTask, CitizenBTActionInteractTask.new())
    -- work
    CitizenBTNodeFactory.BuildActionNode(actionSelector, CitizenBTDefine.BuiltInAction.CitizenBTActionWork, CitizenBTActionWork.new())
    -- escape
    CitizenBTNodeFactory.BuildActionNode(actionSelector, CitizenBTDefine.BuiltInAction.CitizenBTActionEscape, CitizenBTActionEscape.new())
    -- idle
    CitizenBTNodeFactory.BuildActionNode(actionSelector, CitizenBTDefine.BuiltInAction.CitizenBTActionIdle, CitizenBTActionIdle.new())
    -- clear
    actionNode:AddChild(CitizenBTActionClear.new())
    
    -- for config
    local configPerformance = ConfigRefer.CitizenPerformance
    local configDecision = ConfigRefer.CitizenBTDecision
    for i = 1, citizen._config:PerformanceAILength() do 
        local aiId = citizen._config:PerformanceAI(i)
        ---@type CitizenPerformanceConfigCell
        local performance= configPerformance:Find(aiId)
        if not performance or performance:ActionGroupLength() <= 0 then
            goto continue
        end
        local decision = configDecision:Find(performance:Decision())
        local actionCheckName = ("decisionLogic_%s"):format(i)
        ---@type CitizenBTPerformanceDecision|CitizenBTNode
        local decisionLogic = CitizenBTNodeFactory.BuildBtNodeFromConfig(decision:Node())
        if decisionLogic.SetupDecisionName then
            decisionLogic:SetupDecisionName(actionCheckName)
        end
        CitizenBTNodeFactory.BuildCheckNode(configCheckerEntry, decisionLogic, actionCheckName, 1)
        local node = CitizenBTNodeFactory.BuildActionGroupFromConfig(actionSelector, actionCheckName, performance)
        if decisionLogic.SetupAllChildGroups then
            decisionLogic:SetupAllChildGroups(node._group)
        end
        ::continue::
    end
    return rootNode
end

---@param decisionNode CitizenBTNodeSelector
---@param checker CitizenBTNode
function CitizenBTNodeFactory.BuildCheckNode(decisionNode, checker, key, priority)
    local node = CitizenBTNodeSequence.new()
    decisionNode:AddChild(node)
    if checker then
        node:AddChild(checker)
    end
    node:AddChild(CitizenBTWriteContext.new(KEY.DecisionKey, key))
    node:AddChild(CitizenBTWriteContext.new(KEY.DecisionPriority, priority))
end

---@param actionSelector CitizenBTNodeSelector
---@param actionNode CitizenBTActionNode
function CitizenBTNodeFactory.BuildActionNode(actionSelector, key, actionNode)
    if not actionNode then return end
    local actionSeq = CitizenBTNodeSequence.new()
    actionSeq.name = 'do_seq_' .. GetClassName(actionNode)
    actionNode.name = 'do_' .. GetClassName(actionNode)
    actionSelector:AddChild(actionSeq)
    actionSeq:AddChild(CitizenBTCheckContext.new(KEY.DecisionKey, key, "=="))
    actionSeq:AddChild(CitizenBTWriteCurrent.new())
    actionSeq:AddChild(actionNode)
end

function CitizenBTNodeFactory.BuildBtNodeFromConfig(nodeConfigId)
    local nodeConfig = ConfigRefer.CitizenBTNode:Find(nodeConfigId)
    local nodeLogicName = nodeConfig:Name() 
    local nodeClass = CitizenBTNodeFactory.CachedLogic[nodeLogicName]
    if not nodeClass then
        try_catch(function()
            nodeClass = require(nodeLogicName)
            if nodeClass then
                CitizenBTNodeFactory.CachedLogic[nodeLogicName] = nodeClass
            end
        end, function()
            nodeClass = require("CitizenBTErrorNode")
        end)
    end
    local node = nodeClass.new()
    node:InitFromConfig(nodeConfig)
    return node
end

---@param actionId number @CitizenBTAction
function CitizenBTNodeFactory.BuildBtActionNodeFromConfig(actionId)
    local actionConfig = ConfigRefer.CitizenBTAction:Find(actionId)
    if not actionConfig then
        local errorNode = require("CitizenBTErrorNode").new()
        errorNode:InitFromConfig(("FromAction:%s"):format(actionId))
        return errorNode
    end
    local actionNode = CitizenBTActionSequence.new(actionConfig:Loop())
    for i = 1, actionConfig:NodesLength() do
        actionNode:AddAction(CitizenBTNodeFactory.BuildBtNodeFromConfig(actionConfig:Nodes(i)))
    end
    return actionNode
end

---@param actionSelector CitizenBTNodeSelector
---@param actionCheckName string
---@param performanceConfig CitizenPerformanceConfigCell
---@return CitizenBTActionGroup
function CitizenBTNodeFactory.BuildActionGroupFromConfig(actionSelector, actionCheckName, performanceConfig)
    local node = CitizenBTActionGroup.new()
    CitizenBTNodeFactory.BuildActionNode(actionSelector, actionCheckName, node)
    for i = 1, performanceConfig:ActionGroupLength() do
        local config = ConfigRefer.CitizenBTActionGroup:Find(performanceConfig:ActionGroup(i))
        node:AddGroupItem(config, CitizenBTNodeFactory.BuildBtActionNodeFromConfig(config:Action()))
    end
    node:GroupItemEnd()
    return node
end

return CitizenBTNodeFactory