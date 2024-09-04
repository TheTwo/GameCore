local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")


---@class TouchMenuCellLandformDatum:TouchMenuCellDatumBase
---@field new fun(title, compsData, tips):TouchMenuCellLandformDatum
---@field super TouchMenuCellDatumBase
local TouchMenuCellLandformDatum = class("TouchMenuCellLandformDatum", TouchMenuCellDatumBase)

function TouchMenuCellLandformDatum:ctor()
    self.title = nil
end

function TouchMenuCellLandformDatum:GetPrefabIndex()
    return 17
end

function TouchMenuCellLandformDatum:SetTitle(title)
    self.title = title
end

---@param landCfgIds number[]
function TouchMenuCellLandformDatum:SetLandformIds(landCfgIds)
    self.landCfgIds = landCfgIds
end

return TouchMenuCellLandformDatum