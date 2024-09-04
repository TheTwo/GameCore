local CityFurnitureOverviewDataGroupBase = require("CityFurnitureOverviewDataGroupBase")
---@class CityFurnitureOverviewDataGroup_ResCollect:CityFurnitureOverviewDataGroupBase
---@field new fun():CityFurnitureOverviewDataGroup_ResCollect
local CityFurnitureOverviewDataGroup_ResCollect = class("CityFurnitureOverviewDataGroup_ResCollect", CityFurnitureOverviewDataGroupBase)
local CityFurnitureOverviewUnitData_ResCollect = require("CityFurnitureOverviewUnitData_ResCollect")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityWorkType = require("CityWorkType")
local I18N = require("I18N")

function CityFurnitureOverviewDataGroup_ResCollect:GetOneLineTitle()
    return I18N.Get(FurnitureOverview_I18N.FurnitureResCollectTitle)
end

function CityFurnitureOverviewDataGroup_ResCollect:GetOneLineOverviewData()
    local ret = {}
    local hashMap = self.city.furnitureManager.hashMap
    if not hashMap then return ret end

    for _, furniture in pairs(hashMap) do
        if furniture:CanDoCityWork(CityWorkType.FurnitureResCollect) and not furniture:IsLocked() then
            table.insert(ret, CityFurnitureOverviewUnitData_ResCollect.new(self.city, furniture.singleId))
        end
    end

    return ret
end

return CityFurnitureOverviewDataGroup_ResCollect