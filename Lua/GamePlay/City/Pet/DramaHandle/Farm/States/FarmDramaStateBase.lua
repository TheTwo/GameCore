local State = require("State")
---@class FarmDramaStateBase:State
local FarmDramaStateBase = class("FarmDramaStateBase", State)

---@param handle FarmDramaHandle
function FarmDramaStateBase:ctor(handle)
    self.handle = handle
end

return FarmDramaStateBase