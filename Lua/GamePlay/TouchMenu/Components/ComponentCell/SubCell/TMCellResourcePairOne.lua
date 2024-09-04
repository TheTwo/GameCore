local BaseUIComponent = require("BaseUIComponent")

---@class TMCellResourcePairOne:BaseUIComponent
---@field new fun():TMCellResourcePairOne
---@field super BaseUIComponent
---@field FeedData fun(self:TMCellResourcePairOne, data:CommonPairsQuantityParameter)
local TMCellResourcePairOne = class('TMCellResourcePairOne', BaseUIComponent)

function TMCellResourcePairOne:OnCreate(param)
    self.selfTrans = self:Transform("")
    ---@type CommonPairsQuantity
    self._child_common_quantity = self:LuaObject("child_common_quantity")
end

---@param data CommonPairsQuantityParameter
function TMCellResourcePairOne:OnFeedData(data)
    self._child_common_quantity:FeedData(data)
end

return TMCellResourcePairOne