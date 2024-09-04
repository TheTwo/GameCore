local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceMainNotifyPopupCellData
---@field icon string
---@field text string
---@field count number
---@field onclick fun()
---@field showCountTip boolean

---@class AllianceMainNotifyPopupCell:BaseUIComponent
---@field new fun():AllianceMainNotifyPopupCell
---@field super BaseUIComponent
local AllianceMainNotifyPopupCell = class('AllianceMainNotifyPopupCell', BaseUIComponent)

function AllianceMainNotifyPopupCell:OnCreate(param)
    self._btn_self = self:Button("", Delegate.GetOrCreate(self, self.OnClickBtnSelf))
    self._p_icon = self:Image("p_icon")
    self._p_text_content = self:Text("p_text_content")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_count_tip = self:GameObject("p_count_tip")
    self._p_text_quantity_white = self:Text("p_text_quantity_white")
end

---@param data AllianceMainNotifyPopupCellData
function AllianceMainNotifyPopupCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon)
    self._onClick = data.onclick
    self:UpdateContent(data.text)
    self:UpdateNumber(data.count, data.showCountTip)
end

function AllianceMainNotifyPopupCell:UpdateContent(content)
    self._p_text_content.text = content
end

function AllianceMainNotifyPopupCell:UpdateNumber(count, showCountTip)
    self._p_text_quantity.text = count and tostring(count) or ""
    self._p_text_quantity_white.text = count and tostring(count) or ""
    self._p_text_quantity:SetVisible(not showCountTip)
    self._p_count_tip:SetVisible(showCountTip)
end

function AllianceMainNotifyPopupCell:OnClickBtnSelf()
    if self._onClick then
        self._onClick()
    end
end

return AllianceMainNotifyPopupCell