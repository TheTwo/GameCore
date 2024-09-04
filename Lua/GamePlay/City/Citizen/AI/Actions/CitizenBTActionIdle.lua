local CityCitizenDefine = require("CityCitizenDefine")
local CitizenBTActionSequence = require("CitizenBTActionSequence")
local CitizenBTActionRandomWait = require("CitizenBTActionRandomWait")
local CitizenBTActionRandomTarget = require("CitizenBTActionRandomTarget")
local CitizenBTActionGoTo = require("CitizenBTActionGoTo")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionIdle:CitizenBTActionNode
---@field new fun():CitizenBTActionIdle
---@field super CitizenBTActionNode
local CitizenBTActionIdle = class('CitizenBTActionIdle', CitizenBTActionNode)

function CitizenBTActionIdle:ctor()
    CitizenBTActionIdle.super.ctor(self)
    self._subActions = CitizenBTActionSequence.new(true)
end

function CitizenBTActionIdle:Enter(context, gContext)
    local citizen = context:GetCitizen()
    ---@type CityUnitCitizen
    self._citizen = citizen
    citizen:ChangeAnimatorState(CityCitizenDefine.AniClip.Idle)
    self._subActions:Clear()
    self._subActions:AddAction(CitizenBTActionRandomWait.new())
    self._subActions:AddAction(CitizenBTActionRandomTarget.new())
    self._subActions:AddAction(CitizenBTActionGoTo.new())
    self._subActions:Enter(context, gContext)
end

function CitizenBTActionIdle:Tick(dt, nowTime, context, gContext)
    return self._subActions:Tick(dt, nowTime, context, gContext)
end

function CitizenBTActionIdle:Exit(context, gContext)
    self._subActions:Exit(context, gContext)
end

return CitizenBTActionIdle