local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require("Delegate")

---@class BattleReportRewardCell : BaseTableViewProCell
---@field super BaseTableViewProCell
local BattleReportRewardCell = class('BattleReportRewardCell', BaseTableViewProCell)

---@class BattleReportRewardCellData
---@field reward wds.BattleReportReward

function BattleReportRewardCell:OnCreate(param)
	self.titleText = self:Text("p_text_rewards", "battlemessage_rewards")
	self.rewardTable = self:TableViewPro("p_table_rewards")
end

---@param data BattleReportRewardCellData
function BattleReportRewardCell:OnFeedData(data)
	self.rewardTable:Clear()
    if (not data or not data.reward) then return end
	for itemId, count in pairs(data.reward.RewardItems) do
		local itemData = {
			Items = function()
				return itemId
			end,
			Nums = function()
				return count
			end,
		}
		self.rewardTable:AppendData(itemData)
	end
end

return BattleReportRewardCell;
