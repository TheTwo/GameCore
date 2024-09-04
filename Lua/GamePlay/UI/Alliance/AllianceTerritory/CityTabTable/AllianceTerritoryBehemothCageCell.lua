local UIHelper = require("UIHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryBehemothCageCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryBehemothCageCell
---@field super BaseTableViewProCell
local AllianceTerritoryBehemothCageCell = class('AllianceTerritoryBehemothCageCell', BaseTableViewProCell)

function AllianceTerritoryBehemothCageCell:ctor()
	AllianceTerritoryBehemothCageCell.super.ctor(self)
	---@type CS.DragonReborn.UI.LuaBaseComponent[]
	self._cells = {}
end

function AllianceTerritoryBehemothCageCell:OnCreate(param)
	---@see AllianceTerritoryBehemothCageSubCell
	self._p_behemothCage_template = self:LuaBaseComponent("p_behemothCage_template")
	self._p_behemothCage_template:SetVisible(false)
end

---@param data AllianceBehemoth[]
function AllianceTerritoryBehemothCageCell:OnFeedData(data)
	for i = #self._cells, #data + 1, -1 do
		self._cells[i]:SetVisible(false)
	end
	self._p_behemothCage_template:SetVisible(true)
	for i = #self._cells + 1, #data do
		local cell = UIHelper.DuplicateUIComponent(self._p_behemothCage_template, self._p_behemothCage_template.transform.parent)
		self._cells[i] = cell
	end
	self._p_behemothCage_template:SetVisible(false)
	for i = 1, #data do
		self._cells[i]:SetVisible(true)
		self._cells[i]:FeedData(data[i])
	end
end

function AllianceTerritoryBehemothCageCell:OnRecycle()
    for i = 1, #self._cells do
        UIHelper.DeleteUIComponent(self._cells[i])
    end
    table.clear(self._cells)
end

return AllianceTerritoryBehemothCageCell
