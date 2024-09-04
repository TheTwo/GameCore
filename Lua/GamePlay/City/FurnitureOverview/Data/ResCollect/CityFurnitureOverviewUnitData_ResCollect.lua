local CityFurnitureOverviewUnitDataBase = require("CityFurnitureOverviewUnitDataBase")
---@class CityFurnitureOverviewUnitData_ResCollect:CityFurnitureOverviewUnitDataBase
---@field new fun(city, furnitureId):CityFurnitureOverviewUnitData_ResCollect
local CityFurnitureOverviewUnitData_ResCollect = class("CityFurnitureOverviewUnitData_ResCollect", CityFurnitureOverviewUnitDataBase)
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local CityWorkHelper = require("CityWorkHelper")
local NotificationType = require("NotificationType")
local TimeFormatter = require("TimeFormatter")
local Delegate = require("Delegate")
local CityWorkType = require("CityWorkType")
local CityWorkFormula = require("CityWorkFormula")
local I18N = require("I18N")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityWorkCollectWdsHelper = require("CityWorkCollectWdsHelper")
local CityElementResType = require("CityElementResType")

function CityFurnitureOverviewUnitData_ResCollect:ctor(city, furnitureId)
    CityFurnitureOverviewUnitDataBase.ctor(self, city)
    self.furnitureId = furnitureId
end

function CityFurnitureOverviewUnitData_ResCollect:GetPrefabIndex()
    return CityFurnitureOverviewUIUnitType.p_item_collect
end

function CityFurnitureOverviewUnitData_ResCollect:GetWorkType()
    return CityWorkType.FurnitureResCollect
end

---@param cell CityFurnitureOverviewUIUnitCollect
function CityFurnitureOverviewUnitData_ResCollect:FeedCell(cell)
    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if furniture == nil then return end
    local castleFurniture = furniture:GetCastleFurniture()
    if not castleFurniture then return end

    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityWorkHelper.GetCollectNotifyName(self.furnitureId), NotificationType.CITY_FURNITURE_OVERVIEW_UNIT, cell._child_reddot_default:GameObject(""))
    local workCfgId = furniture:GetWorkCfgId(CityWorkType.FurnitureResCollect)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)

    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    g_Game.SpriteManager:LoadSprite(typeCfg:Image(), cell._p_icon_furniture_collect)

    cell._base_sort:SetActive(false)
    cell:StopTimer(self.timer)
    self.timer = nil
    local isFree = castleFurniture.FurnitureCollectInfo:Count() == 0
    if isFree then
        cell._statusRecord:ApplyStatusRecord(0)
    else
        local info = castleFurniture.FurnitureCollectInfo[1]
        local isAuto = info.Auto
        local isCollecting = not info.Finished

        local icon = CityWorkCollectWdsHelper.GetOutputIcon(info)
        g_Game.SpriteManager:LoadSprite(icon, cell._p_icon_sort_collect)
        cell._base_sort:SetActive(true)

        if isAuto then
            local cur = info.FinishedCount
            local thisWorkCfg = ConfigRefer.CityWork:Find(info.WorkCfgId)
            local workId = castleFurniture.WorkType2Id[CityWorkType.FurnitureResCollect] or 0
            local citizenId = nil
            if workId > 0 then
                local workData = self.city.cityWorkManager:GetWorkData(workId)
                if workData ~= nil and workData.CitizenId > 0 then
                    citizenId = workData.CitizenId
                end
            end
            local max = CityWorkFormula.GetResAutoCollectMaxCount(thisWorkCfg, nil, self.furnitureId, citizenId)
            if castleFurniture.Polluted then
                cell._statusRecord:ApplyStatusRecord(2)
                cell._p_text_collect.text = I18N.Get("FAILURE_REASON_POLLUTED")
            elseif citizenId == nil then
                cell._statusRecord:ApplyStatusRecord(2)
                cell._p_text_collect.text = I18N.Get("lack_citizen")
            elseif cur == max then
                cell._statusRecord:ApplyStatusRecord(1)
            elseif info.CollectingResource == 0 then
                cell._statusRecord:ApplyStatusRecord(2)
                local resType = info.ResourceType
                if resType == CityElementResType.WoodTargets then
                    cell._p_text_collect.text = I18N.Get("lack_wood")
                elseif resType == CityElementResType.MetalTargets then
                    cell._p_text_collect.text = I18N.Get("lack_metal")
                elseif resType == CityElementResType.WheatTargets or resType == CityElementResType.ChillTargets or resType == CityElementResType.PumpkinTargets or resType == CityElementResType.CornTargets then
                    cell._p_text_collect.text = I18N.Get("lack_food")
                elseif resType == CityElementResType.RolinTargets then
                    cell._p_text_collect.text = I18N.Get("lack_rolin")
                end
            else
                cell._statusRecord:ApplyStatusRecord(0)
            end
            cell._p_progress_collect.value = math.clamp01(cur / max)
            cell._p_text_time_collect.text = I18N.GetWithParams(FurnitureOverview_I18N.UIHint_FurnitureOverview_ProcessAutoCollect, cur, max)
        else
            local progress, remainTime = 1, 0
            if isCollecting then
                local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
                progress = (nowTime - info.StartTime.ServerSecond) / (info.FinishTime.ServerSecond - info.StartTime.ServerSecond)
                remainTime = math.max(0, (info.FinishTime.ServerSecond - nowTime))
            end

            cell._statusRecord:ApplyStatusRecord(isCollecting and 1 or 3)
            cell._p_progress_collect.value = progress
            cell._p_text_time_collect.text = TimeFormatter.SimpleFormatTime(remainTime)

            if remainTime > 0 then
                self.timer = cell:StartFrameTicker(Delegate.GetOrCreate(self, self.OnTick), 1, -1)
            end
        end
    end
    self.cell = cell
end

function CityFurnitureOverviewUnitData_ResCollect:OnTick()
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if not castleFurniture then return end

    local isFree = castleFurniture.FurnitureCollectInfo:Count() == 0
    if isFree then
        self.cell._statusRecord:ApplyStatusRecord(0)
    else
        local info = castleFurniture.FurnitureCollectInfo[1]
        local isCollecting = not info.Finished
        self.cell._statusRecord:ApplyStatusRecord(isCollecting and 1 or 3)

        local progress, remainTime = 1, 0
        if isCollecting then
            local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
            progress = (nowTime - info.StartTime.ServerSecond) / (info.FinishTime.ServerSecond - info.StartTime.ServerSecond)
            remainTime = math.max(0, (info.FinishTime.ServerSecond - nowTime))
        end

        self.cell._p_progress_collect.value = progress
        self.cell._p_text_time_collect.text = TimeFormatter.SimpleFormatTime(remainTime)

        if remainTime <= 0 or not isCollecting then
            self:StopTimer()
        end
    end
end

---@param cell CityFurnitureOverviewUIUnitCollect
function CityFurnitureOverviewUnitData_ResCollect:OnClick(cell)
    if self.cell ~= nil and self.cell ~= cell then return end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if not furniture then return end

    local CityUtils = require("CityUtils")
    cell:GetParentBaseUIMediator():CloseSelf()
    CityUtils.TryLookAtToCityCoord(self.city, furniture.x, furniture.y, nil, Delegate.GetOrCreate(self, self.CitySelectFurniture), true)
end

function CityFurnitureOverviewUnitData_ResCollect:CitySelectFurniture()
    if not self.city then return end
    if not self.furnitureId then return end
    self.city:ForceSelectFurniture(self.furnitureId)

    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if furniture == nil then return end

    local workCfgId = furniture:GetWorkCfgId(CityWorkType.FurnitureResCollect)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    if workCfg ~= nil and workCfg:GuideForOverviewCard() > 0 then
        ModuleRefer.GuideModule:CallGuide(workCfg:GuideForOverviewCard())
    end
end

return CityFurnitureOverviewUnitData_ResCollect