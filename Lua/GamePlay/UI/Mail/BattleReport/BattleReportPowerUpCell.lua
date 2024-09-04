local Delegate = require('Delegate')

local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class BattleReportPowerUpCell : BaseTableViewProCell
---@field super BaseTableViewProCell
local BattleReportPowerUpCell = class('BattleReportPowerUpCell', BaseTableViewProCell)

---@class BattleReportPowerUpCellData
---@field onClick fun()

function BattleReportPowerUpCell:ctor()
	BattleReportPowerUpCell.super.ctor(self)
    self._onClick = nil
end

function BattleReportPowerUpCell:OnCreate(param)
	self.button = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
	self.buttonText = self:Text("p_text", "battlemessage_bestrongerbutton")
end

---@param data BattleReportPowerUpCellData
function BattleReportPowerUpCell:OnFeedData(data)
	self._onClick = data and data.onClick
end

function BattleReportPowerUpCell:OnBtnGotoClicked()
	if (self._onClick) then
		self._onClick()
	end
end

return BattleReportPowerUpCell;
