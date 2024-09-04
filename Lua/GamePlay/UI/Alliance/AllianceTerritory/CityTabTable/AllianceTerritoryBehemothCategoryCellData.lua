
local BaseTableViewProExpendData = require("BaseTableViewProExpendData")

---@class AllianceTerritoryBehemothCategoryCellData:BaseTableViewProExpendData
---@field new fun():AllianceTerritoryBehemothCategoryCellData
---@field super BaseTableViewProExpendData
local AllianceTerritoryBehemothCategoryCellData = class('AllianceTerritoryBehemothCategoryCellData', BaseTableViewProExpendData)

---@param allChildren AllianceBehemoth[][]
function AllianceTerritoryBehemothCategoryCellData:ctor(allChildren, isExpended)
	AllianceTerritoryBehemothCategoryCellData.super.ctor(self)
	self.__isExpanded = isExpended
	self:RefreshChildCells(nil, allChildren)
	self.titleContent = string.Empty
	self.tipTitle = string.Empty
	self.tipContent = string.Empty
end

function AllianceTerritoryBehemothCategoryCellData:GetPrefabIndex(index)
	return 2
end

return AllianceTerritoryBehemothCategoryCellData
