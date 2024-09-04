local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ReceiveIncidentRewardParameter = require("ReceiveIncidentRewardParameter")
local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')

---@class RadarRewardItem : BaseTableViewProCell
local RadarRewardItem = class('RadarRewardItem',BaseTableViewProCell)

function RadarRewardItem:OnCreate(param)
    self.btnReward = self:Button('', Delegate.GetOrCreate(self, self.OnBtnRewardClicked))
    self.textReward = self:Text('p_text_reward')
end

function RadarRewardItem:OnFeedData(data)
    self.data = data
    local name = ConfigRefer.Incident:Find(self.data.incidentId):Name()
    self.textReward.text = I18N.Get(name)
end

function RadarRewardItem:OnBtnRewardClicked()
    local param = ReceiveIncidentRewardParameter.new()
    param.args.IncidentId = self.data.incidentId
    param:Send(self.btnReward.transform)
end

return RadarRewardItem
