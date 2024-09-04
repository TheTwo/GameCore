local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')
local AllianceTechRankRewardComp = class('AllianceTechRankRewardComp', BaseTableViewProCell)

function AllianceTechRankRewardComp:OnCreate()
    self.p_text_rank = self:Text('p_text_rank')
    self.p_text_reward_my = self:Text('p_text_reward_my')
    self.p_table_reward = self:TableViewPro('p_table_reward')
    self.go = self:GameObject('')
end

function AllianceTechRankRewardComp:OnFeedData(param)
    local from = param.from
    local to = param.to
    if not param.hasRank and param.isMyReward then
        self.p_text_rank.text = I18N.Get('worldstage_phb_wsb')
        self.p_text_reward_my.text = I18N.Get('worldstage_phb_zwjl')
        return
    end

    if not from then
        from = 1
    end

    if from == to then
        self.p_text_rank.text = to
    else
        self.p_text_rank.text = string.format('%d-%d', from, to)
    end

    self.p_table_reward:Clear()
    for k, v in pairs(param.rewards) do
        self.p_table_reward:AppendData(v)
    end

    if param.isMyReward then
        if self.p_text_reward_my then
            self.p_text_reward_my.text = I18N.Get('worldstage_phb_wdjl')
        end
    end
end

return AllianceTechRankRewardComp
