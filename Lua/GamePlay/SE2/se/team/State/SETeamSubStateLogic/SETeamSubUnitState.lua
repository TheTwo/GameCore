local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local SETeamState = require("SETeamState")

---@class SETeamSubUnitState:SETeamState
---@field new fun(seTeam:SETeam, seUnit:SEUnit):SETeamSubUnitState
---@field super SETeamState
local SETeamSubUnitState = class('SETeamSubUnitState', SETeamState)

---@param logic SETeamSubStateLogicIdle
function SETeamSubUnitState:ctor(seTeam, seUnit, logic)
    SETeamSubUnitState.super.ctor(self, seTeam)
    ---@type SEUnit
    self.seUnit = seUnit
    ---@type SETeamSubStateLogicIdle
    self.logic = logic
end

---@param pointA CS.UnityEngine.Vector3
---@param pointB CS.UnityEngine.Vector3
---@param radius number
function SETeamSubUnitState:IsCloseEnough(pointA, pointB, radius)
    local radiusSqr = radius * radius
    return (pointA - pointB).sqrMagnitude < radiusSqr
end

function SETeamSubUnitState:Refresh()
    
end

return SETeamSubUnitState