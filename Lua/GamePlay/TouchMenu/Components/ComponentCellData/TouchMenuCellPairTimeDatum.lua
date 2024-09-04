local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")
---@class TouchMenuCellPairTimeDatum:TouchMenuCellDatumBase
---@field new fun(label, commonTimerData):TouchMenuCellPairTimeDatum
local TouchMenuCellPairTimeDatum = class("TouchMenuCellPairTimeDatum", TouchMenuCellDatumBase)

function TouchMenuCellPairTimeDatum:ctor(label, commonTimerData)
    self.label = label
    self.commonTimerData = commonTimerData
end

function TouchMenuCellPairTimeDatum:GetPrefabIndex()
    return 1
end

return TouchMenuCellPairTimeDatum