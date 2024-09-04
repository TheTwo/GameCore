local CityFurnitureOverviewDataGroupBase = require("CityFurnitureOverviewDataGroupBase")
---@class CityFurnitureOverviewDataGroup_CityWork:CityFurnitureOverviewDataGroupBase
---@field new fun():CityFurnitureOverviewDataGroup_CityWork
local CityFurnitureOverviewDataGroup_CityWork = class("CityFurnitureOverviewDataGroup_CityWork", CityFurnitureOverviewDataGroupBase)
local I18N = require("I18N")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityWorkType = require("CityWorkType")
local CityFurnitureOverviewUnitData_Process = require("CityFurnitureOverviewUnitData_Process")
local CityFurnitureOverviewUnitData_Produce = require("CityFurnitureOverviewUnitData_Produce")
local CityFurnitureOverviewUnitData_ResCollect = require("CityFurnitureOverviewUnitData_ResCollect")
local CityFurnitureOverviewUnitData_MilitiaTrain = require("CityFurnitureOverviewUnitData_MilitiaTrain")

function CityFurnitureOverviewDataGroup_CityWork:GetOneLineTitle()
    return I18N.Get(FurnitureOverview_I18N.CityWorkTitle)
end

function CityFurnitureOverviewDataGroup_CityWork:GetOneLineOverviewData()
    local ret = {}
    local hashMap = self.city.furnitureManager.hashMap
    if not hashMap then return ret end
 
    for _, furniture in pairs(hashMap) do
        if furniture:IsLocked() then goto continue end

        if furniture:CanDoCityWork(CityWorkType.Process) and not furniture:IsMakingFurnitureProcess() then
            table.insert(ret, CityFurnitureOverviewUnitData_Process.new(self.city, furniture.singleId))
        end
        if furniture:CanDoCityWork(CityWorkType.ResourceGenerate) then
            table.insert(ret, CityFurnitureOverviewUnitData_Produce.new(self.city, furniture.singleId))
        end
        if furniture:CanDoCityWork(CityWorkType.FurnitureResCollect) then
            table.insert(ret, CityFurnitureOverviewUnitData_ResCollect.new(self.city, furniture.singleId))
        end
        if furniture:CanDoCityWork(CityWorkType.MilitiaTrain) then
            table.insert(ret, CityFurnitureOverviewUnitData_MilitiaTrain.new(self.city, furniture.singleId))
        end

        ::continue::
    end

    return ret
end

return CityFurnitureOverviewDataGroup_CityWork