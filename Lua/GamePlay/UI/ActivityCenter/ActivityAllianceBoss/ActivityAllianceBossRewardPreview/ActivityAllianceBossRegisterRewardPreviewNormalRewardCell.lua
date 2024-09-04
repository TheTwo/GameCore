local BaseTableViewProCell = require("BaseTableViewProCell")
---@class ActivityAllianceBossRegisterRewardPreviewNormalRewardCell : BaseTableViewProCell
local ActivityAllianceBossRegisterRewardPreviewNormalRewardCell = class("ActivityAllianceBossRegisterRewardPreviewNormalRewardCell", BaseTableViewProCell)

---@class ActivityAllianceBossRegisterRewardPreviewNormalRewardCellParam
---@field rewards ItemIconData[]

function ActivityAllianceBossRegisterRewardPreviewNormalRewardCell:OnCreate()
    self.tableReward = self:TableViewPro("p_item_table_rewards")
end

---@param param ActivityAllianceBossRegisterRewardPreviewNormalRewardCellParam
function ActivityAllianceBossRegisterRewardPreviewNormalRewardCell:OnFeedData(param)
    self.tableReward:Clear()
    ---@type number, ItemIconData
    for _, v in pairs(param.rewards) do
        v.showCount = true
        self.tableReward:AppendData(v)
    end
end

return ActivityAllianceBossRegisterRewardPreviewNormalRewardCell