local State = require("State")

---@class CookDramaState:State
---@field new fun(handle:CookDramaHandle):CookDramaState
---@field super State
local CookDramaState = class("CookDramaState", State)

---@param handle CookDramaHandle
function CookDramaState:ctor(handle)
    self.handle = handle
end

return CookDramaState