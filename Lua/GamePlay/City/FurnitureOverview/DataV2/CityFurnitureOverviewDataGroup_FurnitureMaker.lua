local CityFurnitureOverviewDataGroupBase = require("CityFurnitureOverviewDataGroupBase")
---@class CityFurnitureOverviewDataGroup_FurnitureMaker:CityFurnitureOverviewDataGroupBase
---@field new fun():CityFurnitureOverviewDataGroup_FurnitureMaker
local CityFurnitureOverviewDataGroup_FurnitureMaker = class("CityFurnitureOverviewDataGroup_FurnitureMaker", CityFurnitureOverviewDataGroupBase)
local I18N = require("I18N")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityWorkType = require("CityWorkType")
local CityFurnitureOverviewUnitData_Process = require("CityFurnitureOverviewUnitData_Process")

function CityFurnitureOverviewDataGroup_FurnitureMaker:GetOneLineTitle()
    return I18N.Get(FurnitureOverview_I18N.FurnitureMakingTitle)
end

function CityFurnitureOverviewDataGroup_FurnitureMaker:GetOneLineOverviewData()
    local ret = {}
    local hashMap = self.city.furnitureManager.hashMap
    if not hashMap then return ret end
 
    for _, furniture in pairs(hashMap) do
        if not furniture:IsLocked() and furniture:CanDoCityWork(CityWorkType.Process) and furniture:IsMakingFurnitureProcess() then
            table.insert(ret, CityFurnitureOverviewUnitData_Process.new(self.city, furniture.singleId))
        end
    end

    return ret
end

return CityFurnitureOverviewDataGroup_FurnitureMaker