local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local SETeamSubUnitState = require("SETeamSubUnitState")

---@class SETeamSubStateIdle:SETeamSubUnitState
---@field new fun():SETeamSubStateIdle
---@field super SETeamSubUnitState
local SETeamSubStateIdle = class('SETeamSubStateIdle', SETeamSubUnitState)

return SETeamSubStateIdle