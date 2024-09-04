local BaseUIComponent = require ('BaseUIComponent')

---@class CityConstructionRoomHeaderCell:BaseUIComponent
local CityConstructionRoomHeaderCell = class('CityConstructionRoomHeaderCell', BaseUIComponent)

function CityConstructionRoomHeaderCell:ctor()
    
end

function CityConstructionRoomHeaderCell:OnCreate()
    self._p_case_unactivated = self:GameObject("p_case_unactivated")
    self._p_case_activated = self:GameObject("p_case_activated")

    self._p_icon_building_activated = self:Image("p_icon_building_activated")
    self._p_material = self:GameObject("p_material")
    self._p_buff = self:GameObject("p_buff")
    self._p_quantity_building = self:GameObject("p_quantity_building")
    self._p_save = self:GameObject("p_save")
    self._p_area = self:GameObject("p_area")
    self._p_lv = self:GameObject("p_lv")
    self._p_txt_name = self:Text("p_txt_name")
    self._p_base_save = self:GameObject("p_base_save")
    self._p_txt_hint = self:GameObject("p_txt_hint")
    self._p_icon_ban = self:GameObject("p_icon_ban")
    self._child_reddot_default = self:LuaBaseComponent("child_reddot_default")
end

---@param data CityConstructionUICellDataCustomRoom
function CityConstructionRoomHeaderCell:OnFeedData(data)
    self.data = data
    self._p_case_unactivated:SetActive(false)
    self._p_case_activated:SetActive(true)
    self:LoadSprite(data.cfg:Image(), self._p_icon_building_activated)
    self._p_material:SetActive(false)
    self._p_buff:SetActive(false)
    self._p_quantity_building:SetActive(false)
    self._p_save:SetActive(false)
    self._p_area:SetActive(false)
    self._p_lv:SetActive(false)
    self._p_txt_name.text = data:GetName()
    self._p_txt_hint:SetActive(false)
    self._p_icon_ban:SetActive(false)
    self._child_reddot_default:SetVisible(false)
end

return CityConstructionRoomHeaderCell