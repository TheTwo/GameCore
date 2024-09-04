local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require("Delegate")

---@class BattleReportHeaderCell : BaseTableViewProCell
---@field super BaseTableViewProCell
local BattleReportHeaderCell = class('BattleReportHeaderCell', BaseTableViewProCell)

---@class BattleReportHeaderCellData
---@field record wds.BattleReportRecord

function BattleReportHeaderCell:OnCreate(param)
	self.leftDamageDealtText = self:Text("p_text_harm_l", "battlemessage_output")
	self.leftDamageTakenText = self:Text("p_text_injured_l", "battlemessage_injury")
	self.leftHealingText = self:Text("p_text_treat_l", "battlemessage_cure")
	self.rightDetailNode = self:GameObject("p_tab_r")
	self.rightDamageDealtText = self:Text("p_text_harm_r", "battlemessage_output")
	self.rightDamageTakenText = self:Text("p_text_injured_r", "battlemessage_injury")
	self.rightHealingText = self:Text("p_text_treat_r", "battlemessage_cure")
	self.rightSimpleNode = self:GameObject("p_tab_boss")
	self.rightSimpleText = self:Text("p_text_harm_boss", "battlemessage_damagetaken")
	self.rightSimpleNumText = self:Text("p_text_harm_num")
end

---@param data BattleReportHeaderCellData
function BattleReportHeaderCell:OnFeedData(data)
	assert(data and data.record, "BattleReportHeaderCell:OnFeedData data or data.record is nil!")
	if (data.record.Target.Heroes) then
		local heroInfo = data.record.Target.Heroes[1]
		if (not heroInfo or not heroInfo.TId or heroInfo.TId <= 0) then
			self.rightDetailNode:SetActive(false)
			self.rightSimpleNode:SetActive(true)
			local totalDamageTaken = 0
			for i = 1, #data.record.Target.Heroes do
				totalDamageTaken = totalDamageTaken + data.record.Target.Heroes[i].TakeDamage
			end
			self.rightSimpleNumText.text = totalDamageTaken
		else
			self.rightDetailNode:SetActive(true)
			self.rightSimpleNode:SetActive(false)
		end
	end
end

return BattleReportHeaderCell;
