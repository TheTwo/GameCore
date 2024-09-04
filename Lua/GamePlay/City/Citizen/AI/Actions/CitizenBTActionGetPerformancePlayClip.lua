local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionGetPerformancePlayClip:CitizenBTActionNode
---@field new fun():CitizenBTActionGetPerformancePlayClip
---@field super CitizenBTActionNode
local CitizenBTActionGetPerformancePlayClip = class('CitizenBTActionGetPerformancePlayClip', CitizenBTActionNode)

function CitizenBTActionGetPerformancePlayClip:Run(context, gContext)
    return false
end

return CitizenBTActionGetPerformancePlayClip