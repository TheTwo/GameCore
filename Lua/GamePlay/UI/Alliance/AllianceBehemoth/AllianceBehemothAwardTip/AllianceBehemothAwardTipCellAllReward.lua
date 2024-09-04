
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothAwardTipCellAllReward:BaseTableViewProCell
---@field new fun():AllianceBehemothAwardTipCellAllReward
---@field super BaseTableViewProCell
local AllianceBehemothAwardTipCellAllReward = class('AllianceBehemothAwardTipCellAllReward', BaseTableViewProCell)

function AllianceBehemothAwardTipCellAllReward:OnCreate(param)
    self._p_table_award_1 = self:TableViewPro("p_table_award_1")
end

---@param data ItemIconData[]
function AllianceBehemothAwardTipCellAllReward:OnFeedData(data)
    self._p_table_award_1:Clear()
    for _, v in ipairs(data) do
        self._p_table_award_1:AppendData(v)
    end
end

return AllianceBehemothAwardTipCellAllReward