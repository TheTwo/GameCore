local BaseUIComponent = require ('BaseUIComponent')
local NumberFormatter = require('NumberFormatter')
local ConfigRefer = require('ConfigRefer')
local AttrValueType = require('AttrValueType')

local I18N = require("I18N")

---@class CityWorkUIPropertyChangeItem:BaseUIComponent
local CityWorkUIPropertyChangeItem = class('CityWorkUIPropertyChangeItem', BaseUIComponent)

function CityWorkUIPropertyChangeItem:OnCreate()
    self._p_text_property_name = self:Text("p_text_property_name")
    self._p_text_property_value_old = self:Text("p_text_property_value_old")
    self._p_text_property_value_new = self:Text("p_text_property_value_new")
end

---@param data CityWorkUIPropertyChangeItemData
function CityWorkUIPropertyChangeItem:OnFeedData(data)
    local attrElementCfg = ConfigRefer.AttrElement:Find(data.eleId)
    self._p_text_property_name.text = I18N.Get(attrElementCfg:Name())
    local flag = attrElementCfg:ValueType() ~= AttrValueType.Fix
    if self._p_text_property_value_old then
        self._p_text_property_value_old.text = flag and NumberFormatter.PercentWithSignSymbol(data.oldValue) or NumberFormatter.WithSign(data.oldValue)
    end
    if self._p_text_property_value_new then
        self._p_text_property_value_new.text = flag and NumberFormatter.PercentWithSignSymbol(data.newValue) or NumberFormatter.WithSign(data.newValue)
    end
end

return CityWorkUIPropertyChangeItem