local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")

---@class TouchMenuCellRewardPairListDatum : TouchMenuCellDatumBase
---@field new fun(title, dataList, onClick) : TouchMenuCellRewardPairListDatum
local TouchMenuCellRewardPairListDatum = class("TouchMenuCellRewardPairListDatum", TouchMenuCellDatumBase)

---@param title string
---@param dataList TMCellRewardPairDatum[]
---@param onClick fun()
function TouchMenuCellRewardPairListDatum:ctor(title, dataList, onClick)
    self.title = title
    self.dataList = dataList
    self.onClick = onClick
end

function TouchMenuCellRewardPairListDatum:GetPrefabIndex()
    return 10
end

return TouchMenuCellRewardPairListDatum