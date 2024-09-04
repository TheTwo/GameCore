local BaseTableViewProCell = require("BaseTableViewProCell")

---@class GiftTipsTextCell:BaseTableViewProCell
---@field super BaseTableViewProCell
local GiftTipsTextCell = class("GiftTipsTextCell", BaseTableViewProCell)

function GiftTipsTextCell:OnCreate()
    self.textName = self:Text('p_text_name')
end

---@param text string
function GiftTipsTextCell:OnFeedData(text)
	self.textName.text = text
end

return GiftTipsTextCell