local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")
---@class TouchMenuCellTextDatum:TouchMenuCellDatumBase
---@field new fun(content, flexible:boolean):TouchMenuCellTextDatum
local TouchMenuCellTextDatum = sealedClass("TouchMenuCellTextDatum", TouchMenuCellDatumBase)

function TouchMenuCellTextDatum:ctor(content, flexible)
    self.content = content
    self.flexible = flexible or false
end

function TouchMenuCellTextDatum:GetPrefabIndex()
    return 3
end

function TouchMenuCellTextDatum:IsFlexibleHeight()
    return self.flexible == true
end

return TouchMenuCellTextDatum