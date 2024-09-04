local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CityConstructionRoomSubCell:BaseTableViewProCell
local CityConstructionRoomSubCell = class('CityConstructionRoomSubCell', BaseTableViewProCell)

function CityConstructionRoomSubCell:OnCreate()
    self._go = self:GameObject("")
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

    self._child_reddot_default = self:LuaBaseComponent("child_reddot_default")
    self._child_reddot_default:SetVisible(false)
end

function CityConstructionRoomSubCell:OnFeedData(data)
    self.data = data
    self.data:FeedCell(self)
end

function CityConstructionRoomSubCell:OnRecycle()
    self.data:RecycleCell(self)
    self.data = nil
end

return CityConstructionRoomSubCell