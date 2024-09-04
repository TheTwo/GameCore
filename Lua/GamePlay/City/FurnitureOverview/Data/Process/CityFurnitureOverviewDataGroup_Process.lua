local CityFurnitureOverviewDataGroupBase = require("CityFurnitureOverviewDataGroupBase")
---@class CityFurnitureOverviewDataGroup_Process:CityFurnitureOverviewDataGroupBase
---@field new fun():CityFurnitureOverviewDataGroup_Process
local CityFurnitureOverviewDataGroup_Process = class("CityFurnitureOverviewDataGroup_Process", CityFurnitureOverviewDataGroupBase)
local CityFurnitureOverviewUnitData_Process = require("CityFurnitureOverviewUnitData_Process")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityWorkType = require("CityWorkType")
local I18N = require("I18N")

function CityFurnitureOverviewDataGroup_Process:GetOneLineTitle()
    return I18N.Get(FurnitureOverview_I18N.ProcessTitle)
end

function CityFurnitureOverviewDataGroup_Process:GetOneLineOverviewData()
    local ret = {}
    local hashMap = self.city.furnitureManager.hashMap
    if not hashMap then return ret end

    for _, furniture in pairs(hashMap) do
        if furniture:CanDoCityWork(CityWorkType.Process) and not furniture:IsLocked() then
            table.insert(ret, CityFurnitureOverviewUnitData_Process.new(self.city, furniture.singleId))
        end
    end

    return ret
end

return CityFurnitureOverviewDataGroup_Process