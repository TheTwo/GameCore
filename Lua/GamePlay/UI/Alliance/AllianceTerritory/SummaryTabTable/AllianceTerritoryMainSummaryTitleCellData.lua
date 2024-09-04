
local BaseTableViewProExpendData = require("BaseTableViewProExpendData")

---@class AllianceTerritoryMainSummaryTitleCellData:BaseTableViewProExpendData
---@field new fun(childCellsData:AllianceTerritoryMainSummaryLvCellData, isExpanded:boolean, childTemplate:number):AllianceTerritoryMainSummaryTitleCellData
---@field super BaseTableViewProExpendData
local AllianceTerritoryMainSummaryTitleCellData = class('AllianceTerritoryMainSummaryTitleCellData', BaseTableViewProExpendData)

---@param childCellsData AllianceTerritoryMainSummaryLvCellData[]
function AllianceTerritoryMainSummaryTitleCellData:ctor(childCellsData, isExpanded, childTemplate, checkStorage)
    BaseTableViewProExpendData.ctor(self)
    self.__isExpanded = isExpanded or not self:ShowExpandBtn()
    self:RefreshChildCells(nil, childCellsData or {})
    ---@type string
    self.titleContent = string.Empty
    self._childTemplate = childTemplate
    ---@type fun(trans:CS.UnityEngine.Transform)
    self.detailBtn = nil
    self.allowShowExpandBtn = childCellsData.allowShowExpandBtn or false
    self.checkStorage = checkStorage
end

function AllianceTerritoryMainSummaryTitleCellData:GetPrefabIndex(index)
    local child = self:GetChildAt(index)
    return child and child.__prefabIndex or self._childTemplate
end

function AllianceTerritoryMainSummaryTitleCellData:ShowExpandBtn()
    return self.allowShowExpandBtn
end

return AllianceTerritoryMainSummaryTitleCellData