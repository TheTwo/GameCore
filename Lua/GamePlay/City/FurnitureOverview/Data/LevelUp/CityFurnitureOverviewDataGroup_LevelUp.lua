local CityFurnitureOverviewDataGroupBase = require("CityFurnitureOverviewDataGroupBase")
---@class CityFurnitureOverviewDataGroup_LevelUp:CityFurnitureOverviewDataGroupBase
---@field new fun():CityFurnitureOverviewDataGroup_LevelUp
local CityFurnitureOverviewDataGroup_LevelUp = class("CityFurnitureOverviewDataGroup_LevelUp", CityFurnitureOverviewDataGroupBase)
local CityFurnitureOverviewUnitData_LevelUp = require("CityFurnitureOverviewUnitData_LevelUp")
local CityFurnitureOverviewUnitData_LevelUpEmpty = require("CityFurnitureOverviewUnitData_LevelUpEmpty")
local CityFurnitureOverviewUnitData_LevelUpExpandSlot = require("CityFurnitureOverviewUnitData_LevelUpExpandSlot")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local I18N = require("I18N")
local CityWorkFormula = require("CityWorkFormula")
local CityWorkType = require("CityWorkType")

function CityFurnitureOverviewDataGroup_LevelUp:GetOneLineTitle()
    return I18N.Get(FurnitureOverview_I18N.LevelUpTitle)
end

function CityFurnitureOverviewDataGroup_LevelUp:GetOneLineOverviewData()
    local ret = {}
    local castleFurnitureMap = self.city:GetCastle().CastleFurniture
    local currentCount = 0
    for id, castleFurniture in pairs(castleFurnitureMap) do
        if castleFurniture.LevelUpInfo.Working then
            if castleFurniture.LevelUpInfo.CurProgress < castleFurniture.LevelUpInfo.TargetProgress then
                table.insert(ret, CityFurnitureOverviewUnitData_LevelUp.new(self.city, id))
                currentCount = currentCount + 1
            end
        end
    end

    local queueCount = self:GetMaxQueueCount()
    for i = currentCount + 1, queueCount do
        table.insert(ret, CityFurnitureOverviewUnitData_LevelUpEmpty.new(self.city))
    end

    if self:NeedShowExpandSlot() then
        table.insert(ret, CityFurnitureOverviewUnitData_LevelUpExpandSlot.new(self.city))
    end

    return ret
end

function CityFurnitureOverviewDataGroup_LevelUp:GetMaxQueueCount()
    return CityWorkFormula.GetTypeMaxQueueCountByWorkType(CityWorkType.FurnitureLevelUp)
end

function CityFurnitureOverviewDataGroup_LevelUp:NeedShowExpandSlot()
    return self.city.furnitureManager:NeedShowLevelUpPackage()
end

function CityFurnitureOverviewDataGroup_LevelUp:ShowUpgradeBase()
    return true
end

return CityFurnitureOverviewDataGroup_LevelUp