local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local SETeamSubUnitState = require("SETeamSubUnitState")

---@class SETeamSubStateMove:SETeamSubUnitState
---@field new fun():SETeamSubStateMove
---@field super SETeamSubUnitState
local SETeamSubStateMove = class('SETeamSubStateMove', SETeamSubUnitState)

function SETeamSubStateMove:Enter()
    ---@type CS.UnityEngine.Vector3
    self.targetPos = self.stateMachine:ReadBlackboard("TargetPos", true)
    self.radius = self.stateMachine:ReadBlackboard("TargetRadius", true)
    self.seUnit:GetController():SetTargetPath({self.seUnit:GetActor():GetPosition(), self.targetPos}, false)
end

function SETeamSubStateMove:Tick()
    local currentPos = self.seUnit:GetActor():GetPosition()
    if self:IsCloseEnough(currentPos, self.targetPos, self.radius) then
        self.stateMachine:ChangeState("SETeamSubStateRoute")
    end
end

function SETeamSubStateMove:Exit()
    self.seUnit:GetController():StopMove()
end

return SETeamSubStateMove