local BaseTableViewProCell = require("BaseTableViewProCell")
---@class ActivityAllianceBossRegisterRewardPreviewRankRewardCell : BaseTableViewProCell
local ActivityAllianceBossRegisterRewardPreviewRankRewardCell = class("ActivityAllianceBossRegisterRewardPreviewRankRewardCell", BaseTableViewProCell)

---@class ActivityAllianceBossRegisterRewardPreviewRankRewardCellParam
---@field rank number
---@field rewards ItemIconData[]

function ActivityAllianceBossRegisterRewardPreviewRankRewardCell:OnCreate()
    self.luaRankItems = {
        self:LuaObject('p_group_reward_l'),
        self:LuaObject('p_group_reward_l_1'),
        self:LuaObject('p_group_reward_l_2'),
        self:LuaObject('p_group_reward_l_3'),
    }
end

---@param param ActivityAllianceBossRegisterRewardPreviewRankRewardCellParam
function ActivityAllianceBossRegisterRewardPreviewRankRewardCell:OnFeedData(param)
    self.rank = param.rank
    self.rewards = param.rewards
    for i = 1, 4 do
        local luaRankItem = self.luaRankItems[i]
        if i == self.rank then
            luaRankItem:FeedData({
                rank = self.rank,
                reward = self.rewards,
            })
            luaRankItem:SetVisible(true)
        else
            luaRankItem:SetVisible(false)
        end
    end
end

return ActivityAllianceBossRegisterRewardPreviewRankRewardCell