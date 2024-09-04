local CityFurnitureOverviewUnitDataBase = require("CityFurnitureOverviewUnitDataBase")
---@class CityFurnitureOverviewUnitData_LevelUp:CityFurnitureOverviewUnitDataBase
---@field new fun():CityFurnitureOverviewUnitData_LevelUp
local CityFurnitureOverviewUnitData_LevelUp = class("CityFurnitureOverviewUnitData_LevelUp", CityFurnitureOverviewUnitDataBase)
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local ConfigRefer = require("ConfigRefer")
local CityWorkType = require("CityWorkType")
local TimeFormatter = require("TimeFormatter")
local Utils = require("Utils")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local CityWorkHelper = require("CityWorkHelper")
local NotificationType = require("NotificationType")

function CityFurnitureOverviewUnitData_LevelUp:ctor(city, furnitureId)
    CityFurnitureOverviewUnitDataBase.ctor(self, city)
    self.furnitureId = furnitureId
end

---@param cell CityFurnitureOverviewUIUnitUpgrade
function CityFurnitureOverviewUnitData_LevelUp:FeedCell(cell)
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if not castleFurniture then return end

    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityWorkHelper.GetLevelUpNotifyName(self.furnitureId), NotificationType.CITY_FURNITURE_OVERVIEW_UNIT, cell._child_reddot_default:GameObject(""))

    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    g_Game.SpriteManager:LoadSprite(typeCfg:Image(), cell._p_icon_furniture_upgrade)

    local workData = self.city.cityWorkManager:GetWorkData(castleFurniture.WorkType2Id[CityWorkType.FurnitureLevelUp] or 0)
    if workData or castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress then
        local progress, remainTime = 1, 0
        if workData ~= nil and workData.RealWorkTime > 0 then
            local nowTimeInMilli = g_Game.ServerTime:GetServerTimestampInMilliseconds()
            progress = math.clamp01((nowTimeInMilli - workData.BeginTime - (workData.TimeSegments[1] or 0)) / workData.RealWorkTime)
            remainTime = math.max(0, (workData.BeginTime + (workData.TimeSegments[1] or 0) + workData.RealWorkTime - nowTimeInMilli) / 1000)
        end

        cell._statusRecord:ApplyStatusRecord(remainTime <= 0 and 3 or 1)
        cell._p_progress_upgrade.value = progress
        cell._p_text_time_upgrade.text = TimeFormatter.SimpleFormatTime(remainTime)
        cell:StopTimer(self.timer)
        self.timer = nil
        if remainTime > 0 then
            self.timer = cell:StartFrameTicker(Delegate.GetOrCreate(self, self.OnTick), 1, -1)
        end
    else
        local progress = castleFurniture.LevelUpInfo.CurProgress / castleFurniture.LevelUpInfo.TargetProgress
        cell._p_progress_upgrade.value = progress
        cell._p_text_time_upgrade.text = ("%02d"):format(math.ceil(progress * 100))
        cell:StopTimer(self.timer)
        cell._statusRecord:ApplyStatusRecord(2)
        self.timer = nil
    end
    self.cell = cell
end

function CityFurnitureOverviewUnitData_LevelUp:GetPrefabIndex()
    return CityFurnitureOverviewUIUnitType.p_item_upgrade
end

function CityFurnitureOverviewUnitData_LevelUp:GetWorkType()
    return CityWorkType.FurnitureLevelUp
end

function CityFurnitureOverviewUnitData_LevelUp:OnTick()
    if not self.cell then return end

    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if not castleFurniture then return end

    local workData = self.city.cityWorkManager:GetWorkData(castleFurniture.WorkType2Id[CityWorkType.FurnitureLevelUp])
    local progress, remainTime = 1, 0
    if workData ~= nil and workData.RealWorkTime > 0 then
        local nowTimeInMilli = g_Game.ServerTime:GetServerTimestampInMilliseconds()
        progress = math.clamp01((nowTimeInMilli - workData.BeginTime - (workData.TimeSegments[1] or 0)) / workData.RealWorkTime)
        remainTime = math.max(0, (workData.BeginTime + (workData.TimeSegments[1] or 0) + workData.RealWorkTime - nowTimeInMilli) / 1000)
    end

    if Utils.IsNotNull(self.cell._p_progress_upgrade) then
        self.cell._p_progress_upgrade.value = progress
    end
    if Utils.IsNotNull(self.cell._p_text_time_upgrade) then
        self.cell._p_text_time_upgrade.text = TimeFormatter.SimpleFormatTime(remainTime)
    end
    if remainTime <= 0 then
        self.cell:StopTimer(self.timer)
        self.timer = nil
    end
end

---@param cell CityFurnitureOverviewUIUnitUpgrade
function CityFurnitureOverviewUnitData_LevelUp:OnClick(cell)
    if self.cell ~= nil and self.cell ~= cell then return end

    if self.cell ~= nil and self.cell ~= cell then return end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if not furniture then return end

    local CityUtils = require("CityUtils")
    cell:GetParentBaseUIMediator():CloseSelf()
    CityUtils.TryLookAtToCityCoord(self.city, furniture.x, furniture.y, nil, Delegate.GetOrCreate(self, self.CitySelectFurniture), true)
end

function CityFurnitureOverviewUnitData_LevelUp:CitySelectFurniture()
    if not self.city then return end
    if not self.furnitureId then return end
    self.city:ForceSelectFurniture(self.furnitureId)
end

function CityFurnitureOverviewUnitData_LevelUp:IsFinished()
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then
        return false
    end

    if not castleFurniture.LevelUpInfo.Working then return false end
    return castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress
end

return CityFurnitureOverviewUnitData_LevelUp