local CityFurnitureOverviewDataGroupBase = require("CityFurnitureOverviewDataGroupBase")
---@class CityFurnitureOverviewDataGroup_MilitiaTrain:CityFurnitureOverviewDataGroupBase
---@field new fun():CityFurnitureOverviewDataGroup_MilitiaTrain
local CityFurnitureOverviewDataGroup_MilitiaTrain = class("CityFurnitureOverviewDataGroup_MilitiaTrain", CityFurnitureOverviewDataGroupBase)
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityWorkType = require("CityWorkType")
local CityFurnitureOverviewUnitData_MilitiaTrain = require("CityFurnitureOverviewUnitData_MilitiaTrain")
local I18N = require("I18N")

function CityFurnitureOverviewDataGroup_MilitiaTrain:GetOneLineTitle()
    return I18N.Get(FurnitureOverview_I18N.MilitiaTrainTitle)
end

function CityFurnitureOverviewDataGroup_MilitiaTrain:GetOneLineOverviewData()
    local ret = {}
    local hashMap = self.city.furnitureManager.hashMap
    if not hashMap then return ret end

    for _, furniture in pairs(hashMap) do
        if furniture:CanDoCityWork(CityWorkType.MilitiaTrain) and not furniture:IsLocked() then
            table.insert(ret, CityFurnitureOverviewUnitData_MilitiaTrain.new(self.city, furniture.singleId))
        end
    end

    return ret
end

return CityFurnitureOverviewDataGroup_MilitiaTrain