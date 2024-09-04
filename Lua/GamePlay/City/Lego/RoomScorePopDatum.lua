---@class RoomScorePopDatum
---@field new fun():RoomScorePopDatum
local RoomScorePopDatum = class("RoomScorePopDatum")

function RoomScorePopDatum:ctor(x, y, score)
    self.x = x
    self.y = y
    self.score = score
end

return RoomScorePopDatum