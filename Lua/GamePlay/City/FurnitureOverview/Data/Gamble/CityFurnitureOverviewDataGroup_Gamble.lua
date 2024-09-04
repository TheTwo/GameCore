local CityFurnitureOverviewDataGroupBase = require("CityFurnitureOverviewDataGroupBase")
---@class CityFurnitureOverviewDataGroup_Gamble:CityFurnitureOverviewDataGroupBase
---@field new fun(city):CityFurnitureOverviewDataGroup_Gamble
local CityFurnitureOverviewDataGroup_Gamble = class("CityFurnitureOverviewDataGroup_Gamble", CityFurnitureOverviewDataGroupBase)
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityFurnitureOverviewUnitData_Gamble = require("CityFurnitureOverviewUnitData_Gamble")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")

function CityFurnitureOverviewDataGroup_Gamble:GetOneLineTitle()
    return I18N.Get(FurnitureOverview_I18N.GambleTitle)
end

function CityFurnitureOverviewDataGroup_Gamble:GetOneLineOverviewData()
    if ModuleRefer.HeroCardModule:CheckIsOpenGacha() then
        return {CityFurnitureOverviewUnitData_Gamble.new(self.city)}
    end
    return {}
end

return CityFurnitureOverviewDataGroup_Gamble