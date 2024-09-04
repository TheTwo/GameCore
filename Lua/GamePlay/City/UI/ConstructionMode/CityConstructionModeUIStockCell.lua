local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local EventConst = require("EventConst")

---@class CityConstructionModeUIStockCell:BaseUIComponent
local CityConstructionModeUIStockCell = class('CityConstructionModeUIStockCell', BaseUIComponent)

function CityConstructionModeUIStockCell:OnCreate()
    self._p_btn_save = self:Button("p_btn_save", Delegate.GetOrCreate(self, self.OnClick))
    self:DragEvent("p_btn_save", Delegate.GetOrCreate(self, self.BeginDrag), Delegate.GetOrCreate(self, self.Drag), Delegate.GetOrCreate(self, self.EndDrag), true)

    self._p_lv_save = self:GameObject("p_lv_save")
    self._p_text_lv_save = self:Text("p_text_lv_save")
    self._p_txt_name_save = self:Text("p_txt_name_save")

    self._p_img_select_save = self:Image("p_img_select_save")

    self._p_icon_building_activated_save = self:Image("p_icon_building_activated_save")
    self._p_quantity_building_save = self:GameObject("p_quantity_building_save")
    self._p_txt_quantity_building_save = self:Text("p_txt_quantity_building_save")

    self._p_quantity_save = self:GameObject("p_quantity_save")
    self._p_txt_quantity_save = self:Text("p_txt_quantity_save")
end

---@param data CityConstructionUICellDataBuilding|CityConstructionUICellDataFurniture
function CityConstructionModeUIStockCell:OnFeedData(data)
    self.data = data
    self._p_text_lv_save.text = tostring(data:GetLevel())
    self._p_txt_name_save.text = data:GetName()

    self._p_lv_save:SetActive(true)
    self._p_quantity_save:SetActive(true)

    g_Game.SpriteManager:LoadSprite(data:GetImage(), self._p_icon_building_activated_save)

    local limit = data:IsLimit()
    self._p_quantity_building_save:SetActive(limit)
    if limit then
        local quantityStr = ("%d/%d"):format(data:Existed(), data:LimitCount())
        if data:Existed() >= data:LimitCount() then
            quantityStr = ("<color=red>%s</color>"):format(quantityStr)
        end
        self._p_txt_quantity_building_save.text = quantityStr
    end
    self._p_txt_quantity_save.text = tostring(data:GetStock())
end

function CityConstructionModeUIStockCell:OnClick()
    if self.data and not string.IsNullOrEmpty(self.data:PrefabName()) then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_SELECTION, self.data)
    else
        g_Logger.Error("模型配置为空, 请检查配置")
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionModeUIStockCell:BeginDrag(go, eventData)
    self.dragChecking = true
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionModeUIStockCell:Drag(go, eventData)
    if self.dragChecking then
        local result = eventData.pointerCurrentRaycast.gameObject
        if result == nil then
            if self.data and not string.IsNullOrEmpty(self.data:PrefabName()) then
                self.dragChecking = false
                g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_SELECTION, self.data, eventData.position)
            else
                g_Logger.Error("模型配置为空, 请检查配置")
            end
        end
    else
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_PREVIEW_POS, eventData.position)
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionModeUIStockCell:EndDrag(go, eventData)
    self.dragChecking = false
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_UICELL_DRAG_RELEASE)
end

return CityConstructionModeUIStockCell