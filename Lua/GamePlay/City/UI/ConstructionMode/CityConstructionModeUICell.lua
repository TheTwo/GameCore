local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')

---@class CityConstructionModeUICell:BaseTableViewProCell
---@field testStruct CS.UnityEngine.Camera.MonoOrStereoscopicEye
---@field child_reddot_default NotificationNode
local CityConstructionModeUICell = class('CityConstructionModeUICell', BaseTableViewProCell)

function CityConstructionModeUICell:OnCreate()
    self.transform = self:Transform("")
    self._p_canvas = self:BindComponent("p_canvas", typeof(CS.UnityEngine.Canvas))
    self._p_btn_click = self:Button("p_btn_click")
    self:PointerClick("p_btn_click", Delegate.GetOrCreate(self, self.OnClick))
    self:DragEvent("p_btn_click", Delegate.GetOrCreate(self, self.BeginDrag), Delegate.GetOrCreate(self, self.Drag),
        Delegate.GetOrCreate(self, self.EndDrag), true, Delegate.GetOrCreate(self, self.OnSendToParent))
    self:PointerDown("p_btn_click", Delegate.GetOrCreate(self, self.OnPointerDown))
    self:PointerUp("p_btn_click", Delegate.GetOrCreate(self, self.OnPointerUp))

    self._p_icon_ban = self:GameObject("p_icon_ban")
    self._p_case_unactivated = self:GameObject("p_case_unactivated")
    self._p_case_activated = self:GameObject("p_case_activated")
    self._p_txt_hint = self:Text("p_txt_hint")

    self._p_txt_unlock = self:Text("p_txt_unlock", "build_unknown")

    self._p_img_select = self:GameObject("p_img_select")

    self._p_lv = self:GameObject("p_lv")
    self._p_text_lv = self:Text("p_text_lv")
    self._p_txt_name = self:Text("p_txt_name")
    self._p_icon_building_activated = self:Image("p_icon_building_activated")
    self._p_quantity_building = self:GameObject("p_quantity_building")
    self._p_txt_quantity_building = self:Text("p_txt_quantity_building")

    self._p_material = self:GameObject("p_material")
    self._p_item_material_1 = self:GameObject("p_item_material_1")
    self._p_icon_material_1 = self:Image("p_icon_material_1")
    self._p_txt_quantity_n_1 = self:Text("p_txt_quantity_n_1")
    self._p_txt_quantity_red_1 = self:Text("p_txt_quantity_red_1")

    self._p_item_material_2 = self:GameObject("p_item_material_2")
    self._p_icon_material_2 = self:Image("p_icon_material_2")
    self._p_txt_quantity_n_2 = self:Text("p_txt_quantity_n_2")
    self._p_txt_quantity_red_2 = self:Text("p_txt_quantity_red_2")

    self._p_item_material_3 = self:GameObject("p_item_material_3")
    self._p_icon_material_3 = self:Image("p_icon_material_3")
    self._p_txt_quantity_n_3 = self:Text("p_txt_quantity_n_3")
    self._p_txt_quantity_red_3 = self:Text("p_txt_quantity_red_3")

    self._p_area = self:GameObject("p_area")
    self._p_txt_quantity_area = self:Text("p_txt_quantity_area")

    self._p_save = self:GameObject("p_save")
    self._p_base_save = self:GameObject("p_base_save")
    self._p_quantity_save = self:GameObject("p_quantity_save")
    self._p_txt_quantity_save = self:Text("p_txt_quantity_save")
    self._p_detail = self:Button("p_detail", Delegate.GetOrCreate(self, self.OnClickDetails))

    self.child_reddot_default = self:LuaObject("child_reddot_default")

    self._p_txt_desc = self:Text("p_txt_desc")
end

function CityConstructionModeUICell:OnOpened()
    
end

function CityConstructionModeUICell:OnClose()

end

---@param data CityConstructionUICellDataBuilding|CityConstructionUICellDataFurniture
function CityConstructionModeUICell:OnFeedData(data)
    self.data = data
    self.data:OnFeedData(self)
    self.sendToParent = false
    self:ShowCanvas()
end

function CityConstructionModeUICell:OnRecycle(_)
    self.data:OnRecycle(self)
    self.data = nil
end

function CityConstructionModeUICell:OnClick()
    if self.sendToParent then return end
    if self.data then
        self.data:OnClick(self)
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionModeUICell:BeginDrag(go, eventData)
    if self.data then
        self.data:BeginDrag(self, go, eventData)
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionModeUICell:Drag(go, eventData)
    if self.data then
        self.data:Drag(self, go, eventData)
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionModeUICell:EndDrag(go, eventData)
    if self.data then
        self.data:EndDrag(self, go, eventData)
    end
end

function CityConstructionModeUICell:OnPointerDown(go)
    if self.data and self.data.OnPointerDown then
        self.data:OnPointerDown(self)
    end
end

function CityConstructionModeUICell:OnPointerUp(go)
    if self.data and self.data.OnPointerUp then
        self.data:OnPointerUp(self)
    end
end

function CityConstructionModeUICell:OnClickDetails()
    if self.data then
        self.data:OnClickDetails(self)
    end
end

function CityConstructionModeUICell:HideCanvas()
    self._p_canvas.enabled = false
end

function CityConstructionModeUICell:ShowCanvas()
    self._p_canvas.enabled = true
end

function CityConstructionModeUICell:OnSendToParent(flag)
    self.sendToParent = flag
    if flag then
        self:OnPointerUp()
    end
end

return CityConstructionModeUICell