local State = require("State")
---@class PastureDramaStateBase:State
---@field new fun(handle:PastureDramaHandle):PastureDramaStateBase
---@field super State
local PastureDramaStateBase = class("PastureDramaStateBase", State)

---@param handle PastureDramaHandle
function PastureDramaStateBase:ctor(handle)
    self.handle = handle
end

return PastureDramaStateBase