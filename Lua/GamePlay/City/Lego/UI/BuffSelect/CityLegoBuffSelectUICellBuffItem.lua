local BaseUIComponent = require ('BaseUIComponent')

---@class CityLegoBuffSelectUICellBuffItem:BaseUIComponent
local CityLegoBuffSelectUICellBuffItem = class('CityLegoBuffSelectUICellBuffItem', BaseUIComponent)

function CityLegoBuffSelectUICellBuffItem:OnCreate()
    self._p_text_buff_title = self:Text("p_text_buff_title")
    self._p_text_buff = self:Text("p_text_buff")
end

---@param data CityLegoBuffDifferData
function CityLegoBuffSelectUICellBuffItem:OnFeedData(data)
    self._p_text_buff_title.text = data:GetName()
    self._p_text_buff.text = data:GetOldValueText()
end

return CityLegoBuffSelectUICellBuffItem