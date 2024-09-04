local BaseUIComponent = require("BaseUIComponent")
---@class ActivityAllianceBossRegisterRewardPreviewRankRewardItem : BaseUIComponent
local ActivityAllianceBossRegisterRewardPreviewRankRewardItem = class("ActivityAllianceBossRegisterRewardPreviewRankRewardItem", BaseUIComponent)

---@class ActivityAllianceBossRegisterRewardPreviewRankRewardItemParam
---@field rank number
---@field reward ItemIconData[]

local RANK_ICONS = {
    'sp_activity_ranking_icon_top_1',
    'sp_activity_ranking_icon_top_2',
    'sp_activity_ranking_icon_top_3',
}

function ActivityAllianceBossRegisterRewardPreviewRankRewardItem:OnCreate()
    self.goRankIcon = self:GameObject("p_base_lv")
    self.imgRankIcon = self:Image("p_base_lv")
    self.goRankNormal = self:GameObject("p_base_lv_n")
    self.textRank = self:Text("p_text_lv")
    self.tableReward = self:TableViewPro("p_item_table_rewards")
end

---@param param ActivityAllianceBossRegisterRewardPreviewRankRewardItemParam
function ActivityAllianceBossRegisterRewardPreviewRankRewardItem:OnFeedData(param)
    self.rank = param.rank
    self.reward = param.reward
    self.goRankIcon:SetActive(self.rank <= 3)
    self.goRankNormal:SetActive(self.rank > 3)
    if self.rank <= 3 then
        g_Game.SpriteManager:LoadSprite(RANK_ICONS[self.rank], self.imgRankIcon)
    else
        self.textRank.text = '4-10'
    end
    self.tableReward:Clear()
    ---@type number, ItemIconData
    for _, v in pairs(self.reward) do
        v.showCount = true
        self.tableReward:AppendData(v)
    end
end

return ActivityAllianceBossRegisterRewardPreviewRankRewardItem