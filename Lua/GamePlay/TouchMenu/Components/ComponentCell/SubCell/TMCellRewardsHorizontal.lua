local BaseTableViewProCell = require("BaseTableViewProCell")

---@class TMCellRewardsHorizontal:BaseTableViewProCell
---@field new fun():TMCellRewardsHorizontal
---@field super BaseTableViewProCell
local TMCellRewardsHorizontal = class('TMCellRewardsHorizontal', BaseTableViewProCell)

function TMCellRewardsHorizontal:OnCreate(param)
    self.p_table_reward = self:TableViewPro("p_table_reward")
    self.p_base = self:GameObject('p_base')
    self.p_text_reward = self:Text('p_text_reward')
    self.p_mask = self:GameObject('p_mask')
end

---@param data TMCellRewardsHorizontalDatum
function TMCellRewardsHorizontal:OnFeedData(data)
    self.p_table_reward:Clear()
    for i, v in ipairs(data.cells) do
        if v.itemPayload then
            self.p_table_reward:AppendData(v.itemPayload, 0)
        elseif v.petPayload then
            self.p_table_reward:AppendData(v.petPayload, 1)
        elseif v.imagePayload then
            self.p_table_reward:AppendData(v.imagePayload, 2)
        end
    end

    if data.content then
        self.p_text_reward.text = data.content
    end

    self.p_text_reward:SetVisible(data.content)
    self.p_base:SetVisible(data.content)
    self.p_mask:SetVisible(table.nums(data.cells) > 0)
end

return TMCellRewardsHorizontal
