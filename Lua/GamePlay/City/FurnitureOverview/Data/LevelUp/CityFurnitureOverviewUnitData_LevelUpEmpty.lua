local CityFurnitureOverviewUnitDataBase = require("CityFurnitureOverviewUnitDataBase")
---@class CityFurnitureOverviewUnitData_LevelUpEmpty:CityFurnitureOverviewUnitDataBase
---@field new fun():CityFurnitureOverviewUnitData_LevelUpEmpty
local CityFurnitureOverviewUnitData_LevelUpEmpty = class("CityFurnitureOverviewUnitData_LevelUpEmpty", CityFurnitureOverviewUnitDataBase)
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local ModuleRefer = require("ModuleRefer")
local CityWorkHelper = require("CityWorkHelper")
local NotificationType = require("NotificationType")
local Delegate = require("Delegate")
local CityWorkType = require("CityWorkType")
local ConfigRefer = require("ConfigRefer")

---@param cell CityFurnitureOverviewUIUnitUpgrade
function CityFurnitureOverviewUnitData_LevelUpEmpty:FeedCell(cell)
    cell._statusRecord:ApplyStatusRecord(0)
    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityWorkHelper.GetLevelUpFreeNotifyName(), NotificationType.CITY_FURNITURE_OVERVIEW_UNIT, cell._child_reddot_default:GameObject(""))
end

function CityFurnitureOverviewUnitData_LevelUpEmpty:GetPrefabIndex()
    return CityFurnitureOverviewUIUnitType.p_item_upgrade
end

function CityFurnitureOverviewUnitData_LevelUpEmpty:GetWorkType()
    return CityWorkType.FurnitureLevelUp
end

function CityFurnitureOverviewUnitData_LevelUpEmpty:OnClick(cell)
    local furniture = self.city.furnitureManager:GetAnyCanLevelUpFurniture()
    if furniture == nil then
        furniture = self.city.furnitureManager:GetMainFurniture()
    end

    if furniture ~= nil then
        local workCfgId = furniture:GetWorkCfgId(CityWorkType.FurnitureLevelUp)
        local workCfg = ConfigRefer.CityWork:Find(workCfgId)
        local CityUtils = require("CityUtils")
        cell:GetParentBaseUIMediator():CloseSelf()
        CityUtils.TryLookAtToCityCoord(self.city, furniture.x, furniture.y, nil, function()
            self:CitySelectFurniture(furniture)

            if workCfg ~= nil and workCfg:GuideForOverviewCard() > 0 then
                ModuleRefer.GuideModule:CallGuide(workCfg:GuideForOverviewCard())
            end
        end, true)
    end
end

function CityFurnitureOverviewUnitData_LevelUpEmpty:CitySelectFurniture(furniture)
    if not self.city then return end
    self.city:ForceSelectFurniture(furniture.singleId)
end

return CityFurnitureOverviewUnitData_LevelUpEmpty