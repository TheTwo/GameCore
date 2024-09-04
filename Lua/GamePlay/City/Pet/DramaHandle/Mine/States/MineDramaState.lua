local State = require("State")
---@class MineDramaState:State
local MineDramaState = class("MineDramaState", State)

---@param handle MineDramaHandle
function MineDramaState:ctor(handle)
    self.handle = handle
end

return MineDramaState