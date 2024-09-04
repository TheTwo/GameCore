local CityFurnitureOverviewUnitDataBase = require("CityFurnitureOverviewUnitDataBase")
---@class CityFurnitureOverviewUnitData_MilitiaTrain:CityFurnitureOverviewUnitDataBase
---@field new fun():CityFurnitureOverviewUnitData_MilitiaTrain
local CityFurnitureOverviewUnitData_MilitiaTrain = class("CityFurnitureOverviewUnitData_MilitiaTrain", CityFurnitureOverviewUnitDataBase)
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local ConfigRefer = require("ConfigRefer")
local NotificationType = require("NotificationType")
local CityWorkHelper = require("CityWorkHelper")
local ModuleRefer = require("ModuleRefer")
local CityUtils = require("CityUtils")
local Delegate = require("Delegate")
local CityWorkType = require("CityWorkType")

function CityFurnitureOverviewUnitData_MilitiaTrain:ctor(city, furnitureId)
    CityFurnitureOverviewUnitDataBase.ctor(self, city)
    self.furnitureId = furnitureId
end

function CityFurnitureOverviewUnitData_MilitiaTrain:GetPrefabIndex()
    return CityFurnitureOverviewUIUnitType.p_item_soldier
end

function CityFurnitureOverviewUnitData_MilitiaTrain:GetWorkType()
    return CityWorkType.MilitiaTrain
end

---@param cell CityFurnitureOverviewUIUnitMilitaryTrain
function CityFurnitureOverviewUnitData_MilitiaTrain:OnClick(cell)
    if self.cell ~= nil and self.cell ~= cell then return end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if not furniture then return end

    cell:GetParentBaseUIMediator():CloseSelf()
    CityUtils.TryLookAtToCityCoord(self.city, furniture.x, furniture.y, nil, Delegate.GetOrCreate(self, self.CitySelectFurniture), true)
end

function CityFurnitureOverviewUnitData_MilitiaTrain:CitySelectFurniture()
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

---@param cell CityFurnitureOverviewUIUnitMilitaryTrain
function CityFurnitureOverviewUnitData_MilitiaTrain:FeedCell(cell)
    self.cell = cell
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if not castleFurniture then return end
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    local workId = ModuleRefer.TrainingSoldierModule:GetWorkId(castleFurniture.ConfigId)
    local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    g_Game.SpriteManager:LoadSprite(typeCfg:Image(), cell._p_icon_furniture_soldier)
    local castleMilitia = ModuleRefer.TrainingSoldierModule:GetCastleMilitia()
    local isCustomTraining = castleMilitia.TrainPlan and castleMilitia.TrainPlan > 0
    local isAutoTraining = not castleMilitia.SwitchOff
    local isMax = castleMilitia.Capacity <= castleMilitia.Count
    local needWork = not (isAutoTraining or isMax or isCustomTraining)
    local isNotWork = not (isAutoTraining or isCustomTraining)
    local lackResource = false
    local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(workId, nil, self.furnitureId, nil)
    for i = 1, #costItems do
        local hasNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItems[i].id)
        local costNum = costItems[i].count
        if hasNum < costNum  then
            lackResource = true
        end
    end
    lackResource = lackResource and not isMax
    local showRed = needWork or lackResource
    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("FURNITURE_SOLDIER_TRAIN_RED", NotificationType.CITY_FURNITURE_TRAIN, cell._child_reddot_default:GameObject(""))
    local rootNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityWorkHelper.GetNotifyRootName(), NotificationType.CITY_FURNITURE_OVERVIEW)
    ModuleRefer.NotificationModule:AddToParent(node, rootNode)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, showRed and 1 or 0)
    cell._p_text_quantity_soldier.text = string.format("%d/%d", castleMilitia.Count, castleMilitia.Capacity)
    cell._p_progress_soldier.value = math.clamp01(castleMilitia.Count / castleMilitia.Capacity)
    if isMax then
        --cell._statusRecord:ApplyStatusRecord(6)
        cell._statusRecord:ApplyStatusRecord(1)
    elseif isNotWork then
        cell._statusRecord:ApplyStatusRecord(0)
    elseif isAutoTraining then
        if lackResource then
            cell._statusRecord:ApplyStatusRecord(2)
        else
            cell._statusRecord:ApplyStatusRecord(1)
        end
    elseif isCustomTraining then
        if lackResource then
            cell._statusRecord:ApplyStatusRecord(4)
        else
            cell._statusRecord:ApplyStatusRecord(3)
        end
    end
end

return CityFurnitureOverviewUnitData_MilitiaTrain