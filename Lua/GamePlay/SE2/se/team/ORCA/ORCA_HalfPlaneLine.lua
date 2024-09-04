---@class ORCA_HalfPlaneLine
---@field new fun():ORCA_HalfPlaneLine
local ORCA_HalfPlaneLine = class("ORCA_HalfPlaneLine")

function ORCA_HalfPlaneLine:ctor(point, direction)
    self.point = point
    self.direction = direction
end

return ORCA_HalfPlaneLine