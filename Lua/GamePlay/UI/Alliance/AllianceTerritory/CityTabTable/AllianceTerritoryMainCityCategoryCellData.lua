
local BaseTableViewProExpendData = require("BaseTableViewProExpendData")

---@class AllianceTerritoryMainCityCategoryCellData:BaseTableViewProExpendData
---@field new fun():AllianceTerritoryMainCityCategoryCellData
---@field super BaseTableViewProExpendData
local AllianceTerritoryMainCityCategoryCellData = class('AllianceTerritoryMainCityCategoryCellData', BaseTableViewProExpendData)

---@param allChildren AllianceTerritoryMainCityTabCellData[]
function AllianceTerritoryMainCityCategoryCellData:ctor(allChildren, isExpended)
    BaseTableViewProExpendData.ctor(self)
    self.__isExpanded = isExpended
    local allChildGroup = {}
    local counter = 5
    ---@type AllianceTerritoryMainCityTabCellData[]
    local lastGroup = nil
    for i = 1, #allChildren do
        if not lastGroup then
            lastGroup = {}
            table.insert(allChildGroup, lastGroup)
        end
        local cellData = allChildren[i]
        table.insert(lastGroup, cellData)
        counter = counter - 1
        if counter <= 0 then
            lastGroup = nil
            counter = 5
        end
    end
    self:RefreshChildCells(nil, allChildGroup)
    self.titleContent = string.Empty
end

return AllianceTerritoryMainCityCategoryCellData