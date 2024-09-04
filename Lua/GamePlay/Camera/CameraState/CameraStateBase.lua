local State = require("State")
---@class CameraStateBase:State
local CameraStateBase = class("CameraStateBase", State)

---@param basicCamera BasicCamera
function CameraStateBase:ctor(basicCamera)
    self.basicCamera = basicCamera
end

return CameraStateBase