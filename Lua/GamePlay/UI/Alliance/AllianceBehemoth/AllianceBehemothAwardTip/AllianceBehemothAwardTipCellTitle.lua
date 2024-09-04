
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothAwardTipCellTitle:BaseTableViewProCell
---@field new fun():AllianceBehemothAwardTipCellTitle
---@field super BaseTableViewProCell
local AllianceBehemothAwardTipCellTitle = class('AllianceBehemothAwardTipCellTitle', BaseTableViewProCell)

function AllianceBehemothAwardTipCellTitle:OnCreate(param)
    self._p_text_reward = self:Text("p_text_reward")
end

---@param data string
function AllianceBehemothAwardTipCellTitle:OnFeedData(data)
    self._p_text_reward.text = data
end

return AllianceBehemothAwardTipCellTitle