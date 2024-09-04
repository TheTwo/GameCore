local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class ReplicaPVPSettlementRewardsCellData
---@field pvpTitleStageConfigCell PVPTitleStageConfigCell
---@field itemGroupId number
---@field isCurrentRank boolean

---@class ReplicaPVPSettlementRewardsCell:BaseTableViewProCell
---@field new fun():ReplicaPVPSettlementRewardsCell
---@field super BaseTableViewProCell
local ReplicaPVPSettlementRewardsCell = class('ReplicaPVPSettlementRewardsCell', BaseTableViewProCell)

function ReplicaPVPSettlementRewardsCell:OnCreate()
    self.currentRankGo = self:GameObject('p_now')
    self.txtCurrentRank = self:Text('p_text_now', 'se_pvp_reward_current')
    self.imageRankIcon = self:Image('p_icon_level')
    self.imageRankIconNum = self:Image('p_icon_lv_num')
    self.txtRankName = self:Text('p_text_level_name')
    self.txtRankDesc = self:Text('p_text_ranking')
    self.tableRewards = self:TableViewPro('p_item_table_rewards')
end

---@param data ReplicaPVPSettlementRewardsCellData
function ReplicaPVPSettlementRewardsCell:OnFeedData(data)
    self.currentRankGo:SetVisible(data.isCurrentRank)

    self:LoadSprite(data.pvpTitleStageConfigCell:Icon(), self.imageRankIcon)
    if data.pvpTitleStageConfigCell:LevelIcon() > 0 then
        self.imageRankIconNum:SetVisible(true)
        self:LoadSprite(data.pvpTitleStageConfigCell:LevelIcon(), self.imageRankIconNum)
    else
        self.imageRankIconNum:SetVisible(false)
    end
    self.txtRankName.text = I18N.Get(data.pvpTitleStageConfigCell:Name())
    
    local rankMin = data.pvpTitleStageConfigCell:RankMin()
    local rankMax = data.pvpTitleStageConfigCell:RankMax()
    if rankMin and rankMin > 0 and rankMax and rankMax > 0 then
        self.txtRankDesc:SetVisible(true)
        self.txtRankDesc.text = string.format('%s~%s', rankMin, rankMax)
    else
        self.txtRankDesc:SetVisible(false)
    end

    self.tableRewards:Clear()
    local itemGroupConfigCell = ConfigRefer.ItemGroup:Find(data.itemGroupId)
    if itemGroupConfigCell then
        for i = 1, itemGroupConfigCell:ItemGroupInfoListLength() do
            local itemGroupInfo = itemGroupConfigCell:ItemGroupInfoList(i)
            self.tableRewards:AppendData(itemGroupInfo)
        end
    end
end

return ReplicaPVPSettlementRewardsCell