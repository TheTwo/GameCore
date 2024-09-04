local State = require("State")
---@class LumbermillDramaState:State
local LumbermillDramaState = class("LumbermillDramaState", State)

---@param handle LumbermillDramaHandle
function LumbermillDramaState:ctor(handle)
    self.handle = handle
end

return LumbermillDramaState