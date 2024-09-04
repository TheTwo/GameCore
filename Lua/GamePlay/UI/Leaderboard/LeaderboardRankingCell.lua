local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class LeaderboardRankingCellData
---@field rankMemData wds.TopListMemData
---@field rank number
---@field color CS.UnityEngine.Color
---@field leaderboardId number
---@field leaderboardActivityID number @LeaderboardActivity

---@class LeaderboardRankingCell:BaseTableViewProCell
---@field new fun():LeaderboardRankingCell
---@field super BaseTableViewProCell
local LeaderboardRankingCell = class('LeaderboardRankingCell', BaseTableViewProCell)

function LeaderboardRankingCell:OnCreate()
    ---@type LeaderboardRankingItem
    self.rankItem = self:LuaObject('p_cell_group')
end

---@param data LeaderboardRankingCellData
function LeaderboardRankingCell:OnFeedData(data)
    ---@type LeaderboardRankingItemData
    local itemData = {}
    itemData.rank = data.rank
    itemData.leaderboardId = data.leaderboardId
    itemData.leaderboardActivityID = data.leaderboardActivityID
    itemData.rankMemData = data.rankMemData
    itemData.isBottom = false
    itemData.color = data.color
    self.rankItem:FeedData(itemData)
end

return LeaderboardRankingCell