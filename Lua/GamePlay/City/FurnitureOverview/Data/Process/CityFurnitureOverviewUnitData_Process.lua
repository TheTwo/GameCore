local CityFurnitureOverviewUnitDataBase = require("CityFurnitureOverviewUnitDataBase")
---@class CityFurnitureOverviewUnitData_Process:CityFurnitureOverviewUnitDataBase
---@field new fun():CityFurnitureOverviewUnitData_Process
local CityFurnitureOverviewUnitData_Process = class("CityFurnitureOverviewUnitData_Process", CityFurnitureOverviewUnitDataBase)
local ConfigRefer = require("ConfigRefer")
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local CityWorkHelper = require("CityWorkHelper")
local NotificationType = require("NotificationType")
local CityUtils = require("CityUtils")
local CityWorkType = require("CityWorkType")
local CityWorkFormula = require("CityWorkFormula")
local StateMachine = require("StateMachine")
local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")

local FurOverviewProcessStateNone = require("FurOverviewProcessStateNone")
local FurOverviewProcessStateAutoDoing = require("FurOverviewProcessStateAutoDoing")
local FurOverviewProcessStateAutoPaused = require("FurOverviewProcessStateAutoPaused")
local FurOverviewProcessStateDoing = require("FurOverviewProcessStateDoing")
local FurOverviewProcessStateFinished = require("FurOverviewProcessStateFinished")
local FurOverviewProcessStateFree = require("FurOverviewProcessStateFree")

function CityFurnitureOverviewUnitData_Process:ctor(city, furnitureId)
    CityFurnitureOverviewUnitDataBase.ctor(self, city)
    self.furnitureId = furnitureId
    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState(FurOverviewProcessStateNone:GetName(), FurOverviewProcessStateNone.new(self))
    self.stateMachine:AddState(FurOverviewProcessStateAutoDoing:GetName(), FurOverviewProcessStateAutoDoing.new(self))
    self.stateMachine:AddState(FurOverviewProcessStateAutoPaused:GetName(), FurOverviewProcessStateAutoPaused.new(self))
    self.stateMachine:AddState(FurOverviewProcessStateDoing:GetName(), FurOverviewProcessStateDoing.new(self))
    self.stateMachine:AddState(FurOverviewProcessStateFinished:GetName(), FurOverviewProcessStateFinished.new(self))
    self.stateMachine:AddState(FurOverviewProcessStateFree:GetName(), FurOverviewProcessStateFree.new(self))
    self.stateMachine:ChangeState(FurOverviewProcessStateNone:GetName())
end

function CityFurnitureOverviewUnitData_Process:GetPrefabIndex()
    return CityFurnitureOverviewUIUnitType.p_item_process
end

function CityFurnitureOverviewUnitData_Process:GetWorkType()
    return CityWorkType.Process
end

---@param cell CityFurnitureOverviewUIUnitProcess
function CityFurnitureOverviewUnitData_Process:FeedCell(cell)
    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if furniture == nil then return end
    local castleFurniture = furniture:GetCastleFurniture()
    if not castleFurniture then return end

    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityWorkHelper.GetProcessNotifyName(self.furnitureId), NotificationType.CITY_FURNITURE_OVERVIEW_UNIT, cell._child_reddot_default:GameObject(""))

    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    g_Game.SpriteManager:LoadSprite(typeCfg:Image(), cell._p_icon_furniture_process)

    self.cell = cell
    cell._base_sort:SetActive(false)
    local isFree = castleFurniture.ProcessInfo:Count() == 0
    if isFree then
        self.stateMachine:ChangeState(FurOverviewProcessStateFree:GetName())
    else
        local info = castleFurniture.ProcessInfo[1]
        local isAuto = info.Auto
        local icon = CityWorkProcessWdsHelper.GetOutputIcon(info)
        g_Game.SpriteManager:LoadSprite(icon, cell._p_icon_sort_process)
        cell._base_sort:SetActive(true)

        local status = nil
        if isAuto then
            if info.Working then
                status = 5
            else
                local thisWorkCfg = ConfigRefer.CityWork:Find(info.WorkCfgId)
                local workId = castleFurniture.WorkType2Id[CityWorkType.Process] or 0
                local citizenId = nil
                if workId > 0 then
                    local workData = self.city.cityWorkManager:GetWorkData(workId)
                    if workData ~= nil and workData.CitizenId > 0 then
                        citizenId = workData.CitizenId
                    end
                end
                local max = CityWorkFormula.GetAutoProcessMaxCount(thisWorkCfg, nil, self.furnitureId, citizenId)
                if info.FinishNum == max then
                    status = 3
                else
                    status = 6
                end
            end
        else
            status = info.LeftNum > 0 and 1 or 3
        end

        if status == 1 then
            self.stateMachine:ChangeState(FurOverviewProcessStateDoing:GetName())
        elseif status == 3 then
            self.stateMachine:ChangeState(FurOverviewProcessStateFinished:GetName())
        elseif status == 5 then
            self.stateMachine:ChangeState(FurOverviewProcessStateAutoDoing:GetName())
        elseif status == 6 then
            self.stateMachine:ChangeState(FurOverviewProcessStateAutoPaused:GetName())
        else
            self.stateMachine:ChangeState(FurOverviewProcessStateNone:GetName())
        end
    end
end

function CityFurnitureOverviewUnitData_Process:OnClose()
    self.stateMachine:ChangeState(FurOverviewProcessStateNone:GetName())
end

function CityFurnitureOverviewUnitData_Process:OnHide()
    self.stateMachine:ChangeState(FurOverviewProcessStateNone:GetName())
end

---@param cell CityFurnitureOverviewUIUnitProcess
function CityFurnitureOverviewUnitData_Process:OnClick(cell)
    if self.cell ~= nil and self.cell ~= cell then return end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if not furniture then return end

    cell:GetParentBaseUIMediator():CloseSelf()
    CityUtils.TryLookAtToCityCoord(self.city, furniture.x, furniture.y, nil, Delegate.GetOrCreate(self, self.CitySelectFurniture), true)
end

function CityFurnitureOverviewUnitData_Process:CitySelectFurniture()
    if not self.city then return end
    if not self.furnitureId then return end
    self.city:ForceSelectFurniture(self.furnitureId)

    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if furniture == nil then return end

    local workCfgId = furniture:GetWorkCfgId(CityWorkType.Process)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    if workCfg ~= nil and workCfg:GuideForOverviewCard() > 0 then
        ModuleRefer.GuideModule:CallGuide(workCfg:GuideForOverviewCard())
    end
end

return CityFurnitureOverviewUnitData_Process