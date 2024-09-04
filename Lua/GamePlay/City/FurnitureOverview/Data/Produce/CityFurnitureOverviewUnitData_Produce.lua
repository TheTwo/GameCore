local CityFurnitureOverviewUnitDataBase = require("CityFurnitureOverviewUnitDataBase")
---@class CityFurnitureOverviewUnitData_Produce:CityFurnitureOverviewUnitDataBase
---@field new fun(city, furnitureId):CityFurnitureOverviewUnitData_Produce
local CityFurnitureOverviewUnitData_Produce = class("CityFurnitureOverviewUnitData_Produce", CityFurnitureOverviewUnitDataBase)
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local CityWorkHelper = require("CityWorkHelper")
local NotificationType = require("NotificationType")
local I18N = require("I18N")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityWorkType = require("CityWorkType")
local CityWorkProduceWdsHelper = require("CityWorkProduceWdsHelper")

function CityFurnitureOverviewUnitData_Produce:ctor(city, furnitureId)
    CityFurnitureOverviewUnitDataBase.ctor(self, city)
    self.furnitureId = furnitureId
end

function CityFurnitureOverviewUnitData_Produce:GetPrefabIndex()
    return CityFurnitureOverviewUIUnitType.p_item_plant
end

function CityFurnitureOverviewUnitData_Produce:GetWorkType()
    return CityWorkType.ResourceGenerate
end

---@param cell CityFurnitureOverviewUIUnitProduce
function CityFurnitureOverviewUnitData_Produce:FeedCell(cell)
    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if furniture == nil then return end
    local castleFurniture = furniture:GetCastleFurniture()
    if not castleFurniture then return end

    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityWorkHelper.GetProduceNotifyName(self.furnitureId), NotificationType.CITY_FURNITURE_OVERVIEW_UNIT, cell._child_reddot_default:GameObject(""))

    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    g_Game.SpriteManager:LoadSprite(typeCfg:Image(), cell._p_icon_furniture_plant)

    cell._base_sort:SetActive(false)
    cell:StopTimer(self.timer)
    self.timer = nil
    local isFree = castleFurniture.ResourceGenerateInfo.GeneratePlan:Count() == 0
    if isFree then
        cell._statusRecord:ApplyStatusRecord(0)
    else
        local info = castleFurniture.ResourceGenerateInfo.GeneratePlan[1]
        local isAuto = info.Auto
        local icon = CityWorkProduceWdsHelper.GetproduceIcon(info)
        g_Game.SpriteManager:LoadSprite(icon, cell._p_icon_sort_plant)
        cell._base_sort:SetActive(true)
        local isWorking = castleFurniture.WorkType2Id[CityWorkType.ResourceGenerate] ~= nil
        if isWorking then
            cell._statusRecord:ApplyStatusRecord(0)
        else
            cell._statusRecord:ApplyStatusRecord(1)
            
        end
        if isAuto then
            local thisWorkCfg = ConfigRefer.CityWork:Find(info.WorkCfgId)
            local processCfg = ConfigRefer.CityProcess:Find(info.ProcessId)
            local eleResCfg = ConfigRefer.CityElementResource:Find(processCfg:GenerateResType())
            local cur, max = self.city.cityWorkManager:GetResGenAreaInfo(thisWorkCfg, self.furnitureId, nil, eleResCfg)
            cell._p_progress_plant.value = castleFurniture.ResourceGenerateInfo.GeneratedResourceIds:Count() / max
            cell._p_text_time_plant.text = I18N.GetWithParams(FurnitureOverview_I18N.UIHint_FurnitureOverview_ProduceAutoProgress, castleFurniture.ResourceGenerateInfo.GeneratedResourceIds:Count(), max)
        else
            local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
            local progress = (nowTime - info.StartTime.ServerSecond) / (info.FinishTime.ServerSecond - info.StartTime.ServerSecond)
            local remainTime = math.max(0, (info.FinishTime.ServerSecond - nowTime))
            cell._p_progress_plant.value = progress
            cell._p_text_time_plant.text = TimeFormatter.SimpleFormatTime(remainTime)
            if remainTime > 0 then
                self.timer = cell:StartFrameTicker(Delegate.GetOrCreate(self, self.OnTick), 1, -1)
            end
        end
    end
    self.cell = cell
end

function CityFurnitureOverviewUnitData_Produce:OnTick()
    if not self.cell then return end

    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if not castleFurniture then return end

    local isFree = castleFurniture.ResourceGenerateInfo.GeneratePlan:Count() == 0
    if isFree then
        self.cell._statusRecord:ApplyStatusRecord(0)
        self.cell:StopTimer(self.timer)
        self.timer = nil
    else
        local isAuto = false
        for i, v in ipairs(castleFurniture.ResourceGenerateInfo.GeneratePlan) do
            if v.Auto then
                isAuto = true
                break
            end
        end

        self.cell._statusRecord:ApplyStatusRecord(isAuto and 3 or 1)
        if isAuto then
            self.cell._p_progress_plant.value = 1
            self.cell._p_text_time_plant.text = I18N.Get(FurnitureOverview_I18N.UIHint_FurnitureOverview_ProduceTimeAuto)
            self.cell:StopTimer(self.timer)
            self.timer = nil
        else
            local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
            local info = castleFurniture.ResourceGenerateInfo.GeneratePlan[1]
            local progress = (nowTime - info.StartTime.ServerSecond) / (info.FinishTime.ServerSecond - info.StartTime.ServerSecond)
            local remainTime = math.max(0, (info.FinishTime.ServerSecond - nowTime))
            self.cell._p_progress_plant.value = progress
            self.cell._p_text_time_plant.text = TimeFormatter.SimpleFormatTime(remainTime)
            if remainTime <= 0 then
                self.cell:StopTimer(self.timer)
                self.timer = nil
            end
        end
    end
end

---@param cell CityFurnitureOverviewUIUnitProduce
function CityFurnitureOverviewUnitData_Produce:OnClick(cell)
    if self.cell ~= nil and self.cell ~= cell then return end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if not furniture then return end

    local CityUtils = require("CityUtils")
    cell:GetParentBaseUIMediator():CloseSelf()
    CityUtils.TryLookAtToCityCoord(self.city, furniture.x, furniture.y, nil, Delegate.GetOrCreate(self, self.CitySelectFurniture), true)
end

function CityFurnitureOverviewUnitData_Produce:CitySelectFurniture()
    if not self.city then return end
    if not self.furnitureId then return end
    self.city:ForceSelectFurniture(self.furnitureId)

    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if not furniture then return end

    local workCfgId = furniture:GetWorkCfgId(CityWorkType.ResourceGenerate)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    if workCfg ~= nil and workCfg:GuideForOverviewCard() > 0 then
        ModuleRefer.GuideModule:CallGuide(workCfg:GuideForOverviewCard())
    end
end

return CityFurnitureOverviewUnitData_Produce