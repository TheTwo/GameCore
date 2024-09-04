local CityFurnitureOverviewDataGroupBase = require("CityFurnitureOverviewDataGroupBase")
---@class CityFurnitureOverviewDataGroup_Produce:CityFurnitureOverviewDataGroupBase
---@field new fun():CityFurnitureOverviewDataGroup_Produce
local CityFurnitureOverviewDataGroup_Produce = class("CityFurnitureOverviewDataGroup_Produce", CityFurnitureOverviewDataGroupBase)
local CityFurnitureOverviewUnitData_Produce = require("CityFurnitureOverviewUnitData_Produce")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityWorkType = require("CityWorkType")
local I18N = require("I18N")

function CityFurnitureOverviewDataGroup_Produce:GetOneLineTitle()
    return I18N.Get(FurnitureOverview_I18N.ProduceTitle)
end

function CityFurnitureOverviewDataGroup_Produce:GetOneLineOverviewData()
    local ret = {}
    local hashMap = self.city.furnitureManager.hashMap
    if not hashMap then return ret end

    for _, furniture in pairs(hashMap) do
        if furniture:CanDoCityWork(CityWorkType.ResourceGenerate) and not furniture:IsLocked() then
            table.insert(ret, CityFurnitureOverviewUnitData_Produce.new(self.city, furniture.singleId))
        end
    end

    return ret
end

return CityFurnitureOverviewDataGroup_Produce