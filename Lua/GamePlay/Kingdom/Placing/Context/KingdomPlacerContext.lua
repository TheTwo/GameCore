---@class KingdomPlacerContext
---@field coord CS.DragonReborn.Vector2Short
---@field sizeX number
---@field sizeY number
---@field allowDragTarget boolean
local KingdomPlacerContext = class("KingdomPlacerContext")

function KingdomPlacerContext:ctor()
    self.coord = nil
    self.sizeX = nil
    self.sizeY = nil
    self.allowDragTarget = false
end

-- override this
function KingdomPlacerContext:SetParameter(parameter)
end

return KingdomPlacerContext