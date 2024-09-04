local State = require("State")

---@class CommonMaterialProduceState:State
---@field new fun(handle:CommonMaterialProduceDramaHandle):CommonMaterialProduceState
---@field super State
local CommonMaterialProduceState = class("CommonMaterialProduceState", State)

---@param handle CommonMaterialProduceDramaHandle
function CommonMaterialProduceState:ctor(handle)
    self.handle = handle
end

return CommonMaterialProduceState