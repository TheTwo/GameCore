local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CityFarmLandTouchCellData
---@field harvestMode boolean
---@field cropConfig CropConfigCell
---@field seedNeedCount number
---@field harvestIcon string
---@field host CityFarmLandTouchMediator
---@field isLocked boolean

---@class CityFarmLandTouchCell:BaseTableViewProCell
---@field new fun():CityFarmLandTouchCell
---@field super BaseTableViewProCell
local CityFarmLandTouchCell = class('CityFarmLandTouchCell', BaseTableViewProCell)

function CityFarmLandTouchCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._inDrag = false
    self._pointerDown = false
end

function CityFarmLandTouchCell:OnCreate(param)
    self._selfTrans = self:RectTransform("")
    ---@type BaseItemIcon
    self._p_item_cost_cell = self:LuaObject("p_item_cost_cell")
    self._p_root_harvest = self:GameObject("p_root_harvest")
    self._p_img_harvest = self:Image("p_img_harvest")
    self._p_rootGroup = self:BindComponent("", typeof(CS.UnityEngine.CanvasGroup))
    self:DragEvent("",  Delegate.GetOrCreate(self, self.OnBeginDrag), Delegate.GetOrCreate(self, self.OnDrag), Delegate.GetOrCreate(self, self.OnEndDrag), true)
    self:PointerUp("", Delegate.GetOrCreate(self, self.OnPointerUp))
    self:PointerDown("", Delegate.GetOrCreate(self, self.OnPointerDown))
    self:DragCancelEvent("", Delegate.GetOrCreate(self, self.OnDragCancel))
end

---@param data CityFarmLandTouchCellData
function CityFarmLandTouchCell:OnFeedData(data)
    self._p_item_cost_cell:SetIconBtnRayCastTarget(false)
    self._data = data
    self._p_root_harvest:SetVisible(data.harvestMode)
    self._p_item_cost_cell:SetVisible(not data.harvestMode)
    if data.harvestMode then
        if not string.IsNullOrEmpty(data.harvestIcon) then
            g_Game.SpriteManager:LoadSprite(data.harvestIcon, self._p_img_harvest)
        end
    else
        local config = data.cropConfig
        local itemId = config:ItemId()
        local item = ConfigRefer.Item:Find(itemId)
        ---@type ItemIconData
        local iconData = {}
        iconData.configCell = item
        iconData.count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
        iconData.addCount = -data.seedNeedCount
        iconData.useNoneMask = false
        iconData.locked = data.isLocked
        iconData.showCount = not data.isLocked
        self._p_item_cost_cell:FeedData(iconData)
        if iconData.showCount then
            if iconData.count < data.seedNeedCount then
                self._p_item_cost_cell:SetColor("#b8120e")
            else
                self._p_item_cost_cell:SetColor("#ffffff")
            end
        end
        if data.isLocked then
            self._p_item_cost_cell:SetGray(true)
        else
            self._p_item_cost_cell:SetGray(false)
        end
    end
end

function CityFarmLandTouchCell:OnRecycle()
    self:OnPointerUp(nil)
end

function CityFarmLandTouchCell:OnPointerDown(go)
    if self._inDrag then
        return
    end
    if self._pointerDown then
        return
    end
    self._pointerDown = true
    self._data.host:OnCellShowTip(self._data, self._selfTrans)
end

function CityFarmLandTouchCell:OnPointerUp(go)
    if not self._pointerDown then
        return
    end
    self._pointerDown = false
    self._data.host:OnCellHideTip()
end

---@param go CS.UnityEngine.GameObject
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFarmLandTouchCell:OnBeginDrag(go, data)
    if self._data.isLocked then
        return
    end
    if not self._data.host:OnBeginDrag(self._data, data) then
        return
    end
    self._inDrag = true
    self._p_rootGroup.alpha = 0
    self._p_rootGroup.interactable = false
end

---@param go CS.UnityEngine.GameObject
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFarmLandTouchCell:OnDrag(go, data)
    if not self._inDrag then
        return
    end
    self._data.host:OnDrag(data)
end

---@param go CS.UnityEngine.GameObject
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFarmLandTouchCell:OnEndDrag(go, data)
    if not self._inDrag then
        return
    end
    self._inDrag = false
    self._p_rootGroup.alpha = 1
    self._p_rootGroup.interactable = true
    self._data.host:OnEndDrag(data)
end

---@param go CS.UnityEngine.GameObject
function CityFarmLandTouchCell:OnDragCancel(go)
    if not self._inDrag then
        return
    end
    self._inDrag = false
    self._p_rootGroup.alpha = 1
    self._p_rootGroup.interactable = true
    self._data.host:OnDragCancel()
end

return CityFarmLandTouchCell