local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")
---@class TouchMenuCellResourceDatum:TouchMenuCellDatumBase
---@field new fun():TouchMenuCellResourceDatum
local TouchMenuCellResourceDatum = class("TouchMenuCellResourceDatum", TouchMenuCellDatumBase)

---@vararg TMCellResourceDatumUnit
function TouchMenuCellResourceDatum:ctor(...)
    self.data = {...}
    self.count = #self.data
end

function TouchMenuCellResourceDatum:GetUnit(index)
    return self.data[index]
end

function TouchMenuCellResourceDatum:GetPrefabIndex()
    return 2
end

return TouchMenuCellResourceDatum