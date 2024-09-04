local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local EventConst = require("EventConst")
local CameraUtils = require("CameraUtils")
local I18N = require("I18N")
local LayerMask = CS.UnityEngine.LayerMask.GetMask("Selected")

---@class CityBuildingRepairBlockMatCell:BaseTableViewProCell
---@field _p_item_cost_cell BaseItemIcon
local CityBuildingRepairBlockMatCell = class('CityBuildingRepairBlockMatCell', BaseTableViewProCell)

function CityBuildingRepairBlockMatCell:OnCreate()
    self.transform = self:Transform("")
    self.cam = g_Game.UIManager:GetUICamera()
    self._p_item_cost_cell = self:LuaObject("p_item_cost_cell")
    self._canvasGroup = self:BindComponent("", typeof(CS.UnityEngine.CanvasGroup))
    self:DragEvent("",  Delegate.GetOrCreate(self, self.OnBeginDrag), Delegate.GetOrCreate(self, self.OnDrag), Delegate.GetOrCreate(self, self.OnEndDrag))
end

---@param data {itemIconData:ItemIconData, block:CityBuildingRepairBlockDatum, host:CityBuildingRepairBlockBaseUIMediator}
function CityBuildingRepairBlockMatCell:OnFeedData(data)
    self.data = data
    self._p_item_cost_cell:FeedData(data.itemIconData)
    self:SetNumberTextActive(true)
    self:TweenScaleTo(1, true)
    ModuleRefer.InventoryModule:AddCountChangeListener(self.data.itemIconData.configCell:Id(), Delegate.GetOrCreate(self, self.OnRefresh))
end

function CityBuildingRepairBlockMatCell:OnRecycle()
    ModuleRefer.InventoryModule:RemoveCountChangeListener(self.data.itemIconData.configCell:Id(), Delegate.GetOrCreate(self, self.OnRefresh))
    self.cam = nil
end

function CityBuildingRepairBlockMatCell:OnRefresh()
    self.data.itemIconData.count = ModuleRefer.InventoryModule:GetAmountByConfigId(self.data.itemIconData.configCell:Id())
    self:OnFeedData(self.data)
end

function CityBuildingRepairBlockMatCell:CanDrag()
    local id = self.data.itemIconData.configCell:Id()
    return ModuleRefer.InventoryModule:IsEnoughByConfigId(id, self.data.itemIconData.costCount)
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityBuildingRepairBlockMatCell:OnBeginDrag(go, eventData)
    self.canDrag = self:CanDrag()
    self.isLastCell = self:GetTableViewPro().DataCount == 1
    if not self.canDrag then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("city_upgrade_resource_not_enough"))
        ModuleRefer.InventoryModule:OpenExchangePanel({{id = self.data.itemIconData.configCell:Id(), num = self.data.itemIconData.costCount}})
        return
    end

    self.startPos = self.transform.anchoredPosition
    self.halfWidth = self.transform.rect.width / 2
    self.halfHeight = self.transform.rect.height / 2
    local screenPos = eventData.position
    self.transform.position = self.cam:ScreenToWorldPoint(CS.UnityEngine.Vector3(screenPos.x - self.halfWidth, screenPos.y + self.halfHeight, 0))
    self:SetNumberTextActive(false)
    self:TweenScaleTo(1.5)
    if self.data and self.data.host and self.data.host.OnCellBeginDrag then
        self._canvasGroup.ignoreParentGroups = true
        self.data.host:OnCellBeginDrag()
    end
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityBuildingRepairBlockMatCell:OnDrag(go, eventData)
    if not self.canDrag then return end

    local screenPos = eventData.position
    self.transform.position = self.cam:ScreenToWorldPoint(CS.UnityEngine.Vector3(screenPos.x - self.halfWidth, screenPos.y + self.halfHeight, 0))

    if self:IsReleaseOnSelectedGameObj(eventData) or self:IsReleaseOnTargetBlock(eventData) then
        self.data.block:TriggerFlashEvent(true)
    else
        self.data.block:TriggerFlashEvent(false)
    end
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityBuildingRepairBlockMatCell:OnEndDrag(go, eventData)
    if not self.canDrag then return end

    if self.data and self.data.host and self.data.host.OnCellEndDrag then
        self._canvasGroup.ignoreParentGroups = false
        self.data.host:OnCellEndDrag()
    end
    local keepTriggerFlashEvent
    if self:IsReleaseOnSelectedGameObj(eventData) or self:IsReleaseOnTargetBlock(eventData) then
        keepTriggerFlashEvent = self:GetParentBaseUIMediator():RequestCost(self.data)
    else
        self.transform.anchoredPosition = self.startPos
        self:SetNumberTextActive(true)
        self:TweenScaleTo(1, true)
    end
    if not keepTriggerFlashEvent then
        self.data.block:TriggerFlashEvent(false)
    end
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityBuildingRepairBlockMatCell:IsReleaseOnSelectedGameObj(eventData)
    local block = self.data.block:GetRepairBlock()
    local city = block:GetCity()
    local basicCamera = city:GetCamera()
    local ray = basicCamera:GetRayFromScreenPosition(eventData.position)
    local number, array = CameraUtils.RaycastAll(ray, 10000, LayerMask)
    if number > 0 then
        return true
    end
    return number > 0
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityBuildingRepairBlockMatCell:IsReleaseOnTargetBlock(eventData)
    local block = self.data.block:GetRepairBlock()
    local city = block:GetCity()
    local basicCamera = city:GetCamera()
    local point = basicCamera:GetHitPoint(eventData.position)
    local x, y = city:GetCoordFromPosition(point)
    return block:Contains(x, y)
end

function CityBuildingRepairBlockMatCell:SetNumberTextActive(flag)
    self._p_item_cost_cell.goItemQuantity:SetActive(flag)
    self._p_item_cost_cell.goItemQuantityTop:SetActive(flag)
end

function CityBuildingRepairBlockMatCell:TweenScaleTo(newScale, immediately)
    if immediately then
        self:StopScaleTween()
        self.transform.localScale = CS.UnityEngine.Vector3.one * newScale
    else
        self:StopScaleTween()
        self.tweener = self.transform:DOScale(CS.UnityEngine.Vector3.one * newScale, 0.1)
    end
end

function CityBuildingRepairBlockMatCell:StopScaleTween()
    if not self.tweener then return end
    self.tweener:Kill()
    self.tweener = nil
end

return CityBuildingRepairBlockMatCell