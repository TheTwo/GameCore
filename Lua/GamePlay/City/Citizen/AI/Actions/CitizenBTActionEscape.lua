local CitizenBTActionSequence = require("CitizenBTActionSequence")
local CitizenBTActionFindSafeTarget = require("CitizenBTActionFindSafeTarget")
local CitizenBTActionGoTo = require("CitizenBTActionGoTo")
local CitizenBTActionRandomWait = require("CitizenBTActionRandomWait")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionEscape:CitizenBTActionNode
---@field new fun():CitizenBTActionEscape
---@field super CitizenBTActionNode
local CitizenBTActionEscape = class('CitizenBTActionEscape', CitizenBTActionNode)

function CitizenBTActionEscape:ctor()
    CitizenBTActionEscape.super.ctor(self)
    self._subActions = CitizenBTActionSequence.new(false)
    self._uid = nil
    self._workTargetChanged = false
    self._subRegisterTargetInfo = nil
end

function CitizenBTActionEscape:Enter(context, gContext)
    context:GetCitizen():RequestEscapeBubble()

    self._subActions:Clear()
    self._subActions:AddAction(CitizenBTActionFindSafeTarget.new())
    self._subActions:AddAction(CitizenBTActionGoTo.new())
    self._subActions:AddAction(CitizenBTActionRandomWait.new())
end

function CitizenBTActionEscape:Exit(context, gContext)
    context:GetCitizen():ReleaseEscapeBubble()
end

function CitizenBTActionEscape:Tick(dt, nowTime, context, gContext)
    return self._subActions:Tick(dt, nowTime, context, gContext)
end

return CitizenBTActionEscape