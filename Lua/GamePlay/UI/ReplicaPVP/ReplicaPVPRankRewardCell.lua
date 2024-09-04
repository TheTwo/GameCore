local BaseTableViewProCell = require ('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class ReplicaPVPRankRewardCellData
---@field pvpTitleStageConfigCell PvpTitleStageConfigCell
---@field isReached boolean

---@class ReplicaPVPRankRewardCell:BaseTableViewProCell
---@field new fun():ReplicaPVPRankRewardCell
---@field super BaseTableViewProCell
local ReplicaPVPRankRewardCell = class('ReplicaPVPRankRewardCell', BaseTableViewProCell)

function ReplicaPVPRankRewardCell:OnCreate()
    self.imageRankIcon = self:Image('p_icon_level')
    self.txtRankName = self:Text('p_text_name')
    self.imgCliamed = self:Image('p_check')
    self.txtNotCliamed = self:Text('p_text_lock', 'se_pvp_levelmessage_notreached')
    self.tableRewards = self:TableViewPro('p_item_table_rewards')
end

---@param data ReplicaPVPRankRewardCellData
function ReplicaPVPRankRewardCell:OnFeedData(data)
    self:LoadSprite(data.pvpTitleStageConfigCell:Icon(), self.imageRankIcon)
    self.txtRankName.text = I18N.Get(data.pvpTitleStageConfigCell:Name())

    self.imgCliamed:SetVisible(data.isReached)
    self.txtNotCliamed:SetVisible(not data.isReached)

    self.tableRewards:Clear()
    local itemGroupId = data.pvpTitleStageConfigCell:IMMDReward()
    local itemGroupConfigCell = ConfigRefer.ItemGroup:Find(itemGroupId)
    for i = 1 ,itemGroupConfigCell:ItemGroupInfoListLength() do
        local itemGroupInfo = itemGroupConfigCell:ItemGroupInfoList(i)
        self.tableRewards:AppendData(itemGroupInfo)
    end
end

return ReplicaPVPRankRewardCell