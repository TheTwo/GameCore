local TMCellRewardBase = require("TMCellRewardBase")

---@class TMCellRewardPairDatum : TMCellRewardBase
---@field new fun(leftLabel, rightLabel, icon):TMCellRewardPairDatum
local TMCellRewardPairDatum = class("TMCellRewardPair", TMCellRewardBase)

---@param leftLabel string
---@param rightLabel string
---@param icon string
function TMCellRewardPairDatum:ctor(leftLabel, rightLabel, icon)
    self.leftLabel = leftLabel
    self.rightLabel = rightLabel
    self.icon = icon
end

function TMCellRewardPairDatum:GetPrefabIndex()
    return 1
end

return TMCellRewardPairDatum