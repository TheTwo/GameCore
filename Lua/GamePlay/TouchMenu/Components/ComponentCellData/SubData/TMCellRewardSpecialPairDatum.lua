local TMCellRewardBase = require("TMCellRewardBase")

---@class TMCellRewardSpecialPairDatum : TMCellRewardBase
---@field new fun(leftLabel, rightLabel, icon):TMCellRewardSpecialPairDatum
local TMCellRewardSpecialPairDatum = class("TMCellRewardSpecialPairDatum", TMCellRewardBase)

---@param leftLabel string
---@param rightLabel string
---@param icon string
function TMCellRewardSpecialPairDatum:ctor(leftLabel, rightLabel, icon)
    self.leftLabel = leftLabel
    self.rightLabel = rightLabel
    self.icon = icon
end

function TMCellRewardSpecialPairDatum:GetPrefabIndex()
    return 0
end

return TMCellRewardSpecialPairDatum