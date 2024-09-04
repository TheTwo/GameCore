
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothCageFirstOccupationRewardCell:BaseTableViewProCell
---@field new fun():AllianceBehemothCageFirstOccupationRewardCell
---@field super BaseTableViewProCell
local AllianceBehemothCageFirstOccupationRewardCell = class('AllianceBehemothCageFirstOccupationRewardCell', BaseTableViewProCell)

function AllianceBehemothCageFirstOccupationRewardCell:OnCreate(param)
    self._p_table_award_1 = self:TableViewPro("p_table_award_1")
end

---@param data ItemIconData[]
function AllianceBehemothCageFirstOccupationRewardCell:OnFeedData(data)
    self._p_table_award_1:Clear()
    for _, v in ipairs(data) do
        self._p_table_award_1:AppendData(v)
    end
end

return AllianceBehemothCageFirstOccupationRewardCell