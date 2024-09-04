local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProExpendData = require("BaseTableViewProExpendData")

---@class AllianceTerritoryMainFacilityCategoryCellData:BaseTableViewProExpendData
---@field new fun(allChildren:AllianceTerritoryMainFacilityCellData[],isExpended:boolean,counter:number):AllianceTerritoryMainFacilityCategoryCellData
---@field super BaseTableViewProExpendData
local AllianceTerritoryMainFacilityCategoryCellData = class('AllianceTerritoryMainFacilityCategoryCellData', BaseTableViewProExpendData)

---@param allChildren AllianceTerritoryMainFacilityCellData[]
function AllianceTerritoryMainFacilityCategoryCellData:ctor(allChildren, isExpended, counter)
    BaseTableViewProExpendData.ctor(self)
    self.__isExpanded = isExpended
    local allChildGroup = {}
    counter = counter or 5
    ---@type AllianceTerritoryMainFacilityCellData[]
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
    self.childPrefabIndex = nil
end

function AllianceTerritoryMainFacilityCategoryCellData:GetPrefabIndex(index)
    if not self.childPrefabIndex then
        return AllianceTerritoryMainFacilityCategoryCellData.super.GetPrefabIndex(self, index)
    end
    return self.childPrefabIndex
end

return AllianceTerritoryMainFacilityCategoryCellData