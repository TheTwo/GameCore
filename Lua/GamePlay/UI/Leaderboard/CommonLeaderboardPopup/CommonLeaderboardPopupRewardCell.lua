local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')
---@class CommonLeaderboardPopupRewardCell : BaseTableViewProCell
local CommonLeaderboardPopupRewardCell = class('CommonLeaderboardPopupRewardCell', BaseTableViewProCell)

---@class CommonLeaderboardPopupRewardCellParam
---@field fromRank number
---@field toRank number
---@field isMyReward boolean
---@field hasRank boolean
---@field rewards ItemIconData[]

function CommonLeaderboardPopupRewardCell:OnCreate()
    self.textRank = self:Text('p_text_rank')
    self.tableReward = self:TableViewPro('p_table_reward')
    self.textMyReward = self:Text('p_text_reward_my')
end

---@param param CommonLeaderboardPopupRewardCellParam
function CommonLeaderboardPopupRewardCell:OnFeedData(param)
    self.tableReward:Clear()
    local fromRank = param.fromRank
    local toRank = param.toRank
    if not param.hasRank and param.isMyReward then
        self.textRank.text = I18N.Get('worldstage_phb_wsb')
        self.textMyReward.text = I18N.Get('worldstage_phb_zwjl')
        return
    end
    if not fromRank then
        fromRank = 1
    end
    if fromRank == toRank then
        self.textRank.text = toRank
    else
        self.textRank.text = string.format('%d-%d', fromRank, toRank)
    end
    for _, reward in ipairs(param.rewards) do
        self.tableReward:AppendData(reward)
    end
    if param.isMyReward then
        self.textMyReward.text = I18N.Get('worldstage_phb_wdjl')
    end
end

return CommonLeaderboardPopupRewardCell