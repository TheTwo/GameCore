---@class CityWallOrDoorNavmeshDatum
---@field new fun(x, y, length, isVertical, walkable, note, side):CityWallOrDoorNavmeshDatum
local CityWallOrDoorNavmeshDatum = sealedClass("CityWallOrDoorNavmeshDatum")

function CityWallOrDoorNavmeshDatum:ctor(x, y, length, isVertical, walkable ,note, side)
    self.x = x
    self.y = y
    self.length = length
    self.isVertical = isVertical
    self.walkable = walkable
    self.note = note
    ---@see WallSide
    self.side = side
end

return CityWallOrDoorNavmeshDatum