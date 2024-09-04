
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothCageFirstOccupationRewardSingleCell:BaseTableViewProCell
---@field new fun():AllianceBehemothCageFirstOccupationRewardSingleCell
---@field super BaseTableViewProCell
local AllianceBehemothCageFirstOccupationRewardSingleCell = class('AllianceBehemothCageFirstOccupationRewardSingleCell', BaseTableViewProCell)

function AllianceBehemothCageFirstOccupationRewardSingleCell:OnCreate(param)
    ---@see BaseItemIcon
    self._child_item_standard_s = self:LuaBaseComponent("child_item_standard_s")
end

---@param data ItemIconData
function AllianceBehemothCageFirstOccupationRewardSingleCell:OnFeedData(data)
    self._child_item_standard_s:FeedData(data)
end

return AllianceBehemothCageFirstOccupationRewardSingleCell