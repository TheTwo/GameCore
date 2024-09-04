local UIHelper = require("UIHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryBehemothCageCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryBehemothCageCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryBehemothCageCell = class('AllianceTerritoryMainSummaryBehemothCageCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryBehemothCageCell:ctor()
	AllianceTerritoryMainSummaryBehemothCageCell.super.ctor(self)
	---@type CS.DragonReborn.UI.LuaBaseComponent[]
	self._cells = {}
end

function AllianceTerritoryMainSummaryBehemothCageCell:OnCreate(param)
	---@see AllianceTerritoryMainSummaryBehemothCageSubCell
	self._p_cell_group = self:LuaBaseComponent("p_cell_group")
	self._p_cell_group:SetVisible(false)
end

---@param data AllianceBehemoth[]
function AllianceTerritoryMainSummaryBehemothCageCell:OnFeedData(data)
	for i = #self._cells, #data+1, -1 do
		self._cells[i]:SetVisible(false)
	end
	self._p_cell_group:SetVisible(true)
	for i = #self._cells + 1, #data do
		local cell = UIHelper.DuplicateUIComponent(self._p_cell_group, self._p_cell_group.transform.parent)
		self._cells[i] = cell
	end
	self._p_cell_group:SetVisible(false)
	for i = 1, #data do
		self._cells[i]:SetVisible(true)
		self._cells[i]:FeedData(data[i])
	end
end

function AllianceTerritoryMainSummaryBehemothCageCell:OnRecycle()
    for i = 1, #self._cells do
        UIHelper.DeleteUIComponent(self._cells[i])
    end
    table.clear(self._cells)
end

return AllianceTerritoryMainSummaryBehemothCageCell
