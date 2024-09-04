local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CommonInfoReward : BaseTableViewProCell
local CommonInfoReward = class("CommonInfoReward", BaseTableViewProCell)

function CommonInfoReward:OnCreate()
    self.p_table_reward = self:TableViewPro('p_table_reward')
    self.p_base_mine = self:GameObject('p_base_mine')
end

---@param param CommonPlainTextContentCell
function CommonInfoReward:OnFeedData(param)
    self.p_table_reward:Clear()
    for k, v in pairs(param.reward) do
        ---@type ItemIconData
        local iconData = {}
        iconData.configCell = v.configCell
        if not v.count or v.count == 0 then
            iconData.showCount = false
        else
            iconData.count = v.count
        end
        self.p_table_reward:AppendData(iconData)
    end
    self.p_base_mine:SetVisible(param.isSelected)
end

return CommonInfoReward
