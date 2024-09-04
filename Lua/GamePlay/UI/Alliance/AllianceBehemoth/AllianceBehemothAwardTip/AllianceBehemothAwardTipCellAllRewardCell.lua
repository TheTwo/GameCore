
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothAwardTipCellAllRewardCell:BaseTableViewProCell
---@field new fun():AllianceBehemothAwardTipCellAllRewardCell
---@field super BaseTableViewProCell
local AllianceBehemothAwardTipCellAllRewardCell = class('AllianceBehemothAwardTipCellAllRewardCell', BaseTableViewProCell)

function AllianceBehemothAwardTipCellAllRewardCell:OnCreate(param)
    ---@see BaseItemIcon
    self._child_item_standard_s = self:LuaBaseComponent("child_item_standard_s")
end

---@param data ItemIconData
function AllianceBehemothAwardTipCellAllRewardCell:OnFeedData(data)
    self._child_item_standard_s:FeedData(data)
end

return AllianceBehemothAwardTipCellAllRewardCell