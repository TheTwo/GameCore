local BaseTableViewProCell = require ('BaseTableViewProCell')
local NumberFormatter = require('NumberFormatter')
local AttrValueType = require("AttrValueType")

---@class CityLegoBuffDifferCell:BaseTableViewProCell
local CityLegoBuffDifferCell = class('CityLegoBuffDifferCell', BaseTableViewProCell)

function CityLegoBuffDifferCell:OnCreate()
    self._p_text_property_name = self:Text("p_text_property_name")
    self._p_text_property_value_old = self:Text("p_text_property_value_old")
    self._arrow = self:GameObject("arrow")
    self._p_text_property_value_new = self:Text("p_text_property_value_new")
end

---@param data CityLegoBuffDifferData
function CityLegoBuffDifferCell:OnFeedData(data)
    self.data = data
    self._p_text_property_name.text = data:GetName()

    self._arrow:SetActive(data:ShowArrow())
    if self._p_text_property_value_old then
        self._p_text_property_value_old.text = data:GetOldValueText()
    end

    if self._p_text_property_value_new then
        self._p_text_property_value_new.text = data:GetNewValueText()
    end
end

return CityLegoBuffDifferCell