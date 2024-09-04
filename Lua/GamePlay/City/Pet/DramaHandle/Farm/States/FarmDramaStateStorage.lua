
local FarmDramaStateBase = require("FarmDramaStateBase")
---@class FarmDramaStateStorage:FarmDramaStateBase
---@field super FarmDramaStateBase
local FarmDramaStateStorage = class("FarmDramaStateStorage", FarmDramaStateBase)

function FarmDramaStateStorage:Enter()
    self.handle:CountClear()
    self.handle:MoveToNextActPoint()
end

return FarmDramaStateStorage