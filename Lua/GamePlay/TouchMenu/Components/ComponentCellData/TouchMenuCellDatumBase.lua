---@class TouchMenuCellDatumBase
---@field new fun():TouchMenuCellDatumBase
local TouchMenuCellDatumBase = class("TouchMenuCellDatumBase")

function TouchMenuCellDatumBase:GetPrefabIndex()
    return 0
end

function TouchMenuCellDatumBase:IsFlexibleHeight()
    return false
end

return TouchMenuCellDatumBase