
local BaseUIComponent = require("BaseUIComponent")

---@class AllianceActiveTipCellData
---@field icon string
---@field name string
---@field quantity string

---@class AllianceActiveTipCell:BaseUIComponent
---@field new fun():AllianceActiveTipCell
---@field super BaseUIComponent
local AllianceActiveTipCell = class('AllianceActiveTipCell', BaseUIComponent)

function AllianceActiveTipCell:OnCreate()
    self._p_icon_active_detail = self:Image("p_icon_active_detail")
    self._p_text_name_detail = self:Text("p_text_name_detail")
    self._p_text_quantity = self:Text("p_text_quantity")
end

---@param data AllianceActiveTipCellData
function AllianceActiveTipCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_active_detail)
    self._p_text_name_detail.text = data.name
    self._p_text_quantity.text = data.quantity
end

return AllianceActiveTipCell