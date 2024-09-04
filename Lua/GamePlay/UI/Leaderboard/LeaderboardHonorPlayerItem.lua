local BaseUIComponent = require('BaseUIComponent')
local NumberFormatter = require('NumberFormatter')

---@class LeaderboardHonorPlayerItemData
---@field rankData wds.TopListMemData

---@class LeaderboardHonorPlayerItem:BaseUIComponent
---@field new fun():LeaderboardHonorPlayerItem
---@field super BaseUIComponent
local LeaderboardHonorPlayerItem = class('LeaderboardHonorPlayerItem', BaseUIComponent)

function LeaderboardHonorPlayerItem:OnCreate()
    ---@type PlayerInfoComponent
    self.playerHead = self:LuaObject('child_ui_head_player')

    self.txtPlayerName = self:Text('p_text_famous_playername')
    self.txtPlayerPower = self:Text('p_text_famous_power')
end

---@param data LeaderboardHonorPlayerItemData
function LeaderboardHonorPlayerItem:OnFeedData(data)
    self.txtPlayerName.text = data.rankData.Player.PlayerName
    self.txtPlayerPower.text = NumberFormatter.Normal(data.rankData.Player.PlayerPower)
    local param = data.rankData.Player.PortraitInfo
    param.PlayerId = data.rankData.PlayerId
    self.playerHead:FeedData(param)
end

return LeaderboardHonorPlayerItem