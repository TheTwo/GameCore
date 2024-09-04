local I18N = require("I18N")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceGiftTipsPopupCellData
---@field itemConfig ItemConfigCell
---@field count number
---@field weight number
---@field isLast boolean
---@field showAsFixed boolean

---@class AllianceGiftTipsPopupCell:BaseUIComponent
---@field new fun():AllianceGiftTipsPopupCell
---@field super BaseUIComponent
local AllianceGiftTipsPopupCell = class('AllianceGiftTipsPopupCell', BaseUIComponent)

function AllianceGiftTipsPopupCell:OnCreate(param)
    ---@type BaseItemIcon
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_line = self:GameObject("p_line")
end

---@param data AllianceGiftTipsPopupCellData
function AllianceGiftTipsPopupCell:OnFeedData(data)
    ---@type ItemIconData
    local iconData = {}
    iconData.configCell = data.itemConfig
    iconData.count = data.count
    if data.showAsFixed then
        iconData.showCount = false
        self._p_text_quantity.text = tostring(data.count)
    else
        self._p_text_quantity.text = (("%0.1f%%"):format(data.weight * 100))
    end
    self._child_item_standard_s:FeedData(iconData)
    self._p_text_name.text = I18N.Get(data.itemConfig:NameKey())
    self._p_line:SetVisible(not data.isLast)
end

return AllianceGiftTipsPopupCell