local Delegate = require('Delegate')
local BaseTableViewProCell = require('BaseTableViewProCell')

---@class RadarRewardItem : BaseTableViewProCell
local RadarRewardItem = class('RadarRewardItem',BaseTableViewProCell)

function RadarRewardItem:OnCreate(param)
    self.btnReward = self:Button('', Delegate.GetOrCreate(self, self.OnBtnRewardClicked))
    self.textReward = self:Text('p_text_reward')
end

function RadarRewardItem:OnFeedData(data)

end

function RadarRewardItem:OnBtnRewardClicked()

end

return RadarRewardItem
