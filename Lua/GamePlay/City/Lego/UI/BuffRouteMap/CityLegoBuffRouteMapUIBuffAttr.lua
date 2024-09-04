local BaseUIComponent = require ('BaseUIComponent')

---@class CityLegoBuffRouteMapUIBuffAttr:BaseUIComponent
local CityLegoBuffRouteMapUIBuffAttr = class('CityLegoBuffRouteMapUIBuffAttr', BaseUIComponent)

---@class CityLegoBuffRouteMapUIBuffAttrDatum
---@field desc string
---@field value string

function CityLegoBuffRouteMapUIBuffAttr:OnCreate()
    self._p_text_buff_title = self:Text("p_text_buff_title")
    self._p_text_buff = self:Text("p_text_buff")
end

---@param data CityLegoBuffRouteMapUIBuffAttrDatum
function CityLegoBuffRouteMapUIBuffAttr:OnFeedData(data)
    self._p_text_buff_title.text = data.desc
    self._p_text_buff.text = data.value
end

return CityLegoBuffRouteMapUIBuffAttr