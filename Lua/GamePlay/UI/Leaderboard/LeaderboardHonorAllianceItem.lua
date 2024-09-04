local BaseUIComponent = require('BaseUIComponent')
local NumberFormatter = require('NumberFormatter')

---@class LeaderboardHonorAllianceItemData
---@field rankData wds.TopListMemData

---@class LeaderboardHonorAllianceItem:BaseUIComponent
---@field new fun():LeaderboardHonorAllianceItem
---@field super BaseUIComponent
local LeaderboardHonorAllianceItem = class('LeaderboardHonorAllianceItem', BaseUIComponent)

function LeaderboardHonorAllianceItem:OnCreate()
    ---@type CommonAllianceLogoComponent
    self.allianceLogo = self:LuaObject('child_league_logo')
    self.txtAllianceName = self:Text('p_text_alliance_name')
    self.txtAllianceLeader = self:Text('p_text_alliance_leader')
    self.txtAlliancePower = self:Text('p_text_alliance_power')
end

---@param data LeaderboardHonorAllianceItemData
function LeaderboardHonorAllianceItem:OnFeedData(data)
    self.allianceLogo:FeedData(data.rankData.Alliance.Flag)
    self.txtAllianceName.text = data.rankData.Alliance.AllianceName
    self.txtAllianceLeader.text = data.rankData.Alliance.AllianceLeaderName
    self.txtAlliancePower.text = NumberFormatter.Normal(data.rankData.Alliance.AlliancePower)
end

return LeaderboardHonorAllianceItem