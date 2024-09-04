local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')

---@class ActivityRankCellData
---@field itemGroupId number
---@field targetRankMin number
---@field targetRankMax number

---@class LeaderboardRankingCell:BaseTableViewProCell
---@field new fun():LeaderboardRankingCell
---@field super BaseTableViewProCell
local ActivityRankCell = class('ActivityRankCell', BaseTableViewProCell)

function ActivityRankCell:OnCreate()
    self.txtTargetRank = self:Text('p_text_rank')
    self.imgTargetRank = self:Image('p_icon_rank')

    self.tableRewards = self:TableViewPro('p_table_rewards')

    ---@type BistateButton
    self.btnReward = self:LuaObject('child_comp_btn_b')
    self.goCliamed = self:GameObject('p_icon_claimed')
end

---@param data ActivityRankCellData
function ActivityRankCell:OnFeedData(data)
    self.data = data

    self:SetupRankInfo(data.targetRankMin, data.targetRankMax)

    local itemIconDataList = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(self.data.itemGroupId)
    self.tableRewards:Clear()
    for i, iconData in ipairs(itemIconDataList) do
        self.tableRewards:AppendData(iconData)
    end
end

function ActivityRankCell:SetupRankInfo(min, max)
    if min == max then
        local rank = min
        self.imgTargetRank:SetVisible(rank >= 1 and rank <= 3)
        self.txtTargetRank:SetVisible(rank >= 4)
        if rank >= 4 then
            self.txtTargetRank.text = tostring(rank)
        else
            local iconPath = ModuleRefer.LeaderboardModule:GetRankIcon(rank)
            g_Game.SpriteManager:LoadSprite(iconPath, self.imgTargetRank)
        end
    else
        self.imgTargetRank:SetVisible(false)
        self.txtTargetRank:SetVisible(true)
        if min > 0 and max > 0 then
            self.txtTargetRank.text = string.format('%d-%d', min, max)
        else
            self.txtTargetRank.text = '99+'
        end
    end
end

return ActivityRankCell