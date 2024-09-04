
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothCageFirstOccupationTitleCell:BaseTableViewProCell
---@field new fun():AllianceBehemothCageFirstOccupationTitleCell
---@field super BaseTableViewProCell
local AllianceBehemothCageFirstOccupationTitleCell = class('AllianceBehemothCageFirstOccupationTitleCell', BaseTableViewProCell)

function AllianceBehemothCageFirstOccupationTitleCell:OnCreate(param)
    self._p_text_reward = self:Text("p_text_reward")
end

function AllianceBehemothCageFirstOccupationTitleCell:OnFeedData(data)
    self._p_text_reward.text = data
end

return AllianceBehemothCageFirstOccupationTitleCell