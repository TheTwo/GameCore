---@class TMCellResourceDatumUnit
---@field new fun():TMCellResourceDatumUnit
local TMCellResourceDatumUnit = sealedClass("TMCellResourceDatumUnit")

function TMCellResourceDatumUnit:ctor(itemId, curValue, maxValue)
    self.itemId = itemId
    self.curValue = curValue
    self.maxValue = maxValue
end

return TMCellResourceDatumUnit