local BaseTableViewProCell = require("BaseTableViewProCell")

---@class GiftTipsTextDetailCell:BaseTableViewProCell
---@field super BaseTableViewProCell
local GiftTipsTextDetailCell = class("GiftTipsTextDetailCell", BaseTableViewProCell)

function GiftTipsTextDetailCell:OnCreate()
    self.goCell = self:GameObject('')
    self.textDetail = self:Text('p_text_detail')
    self.rectTextDetail = self:RectTransform('p_text_detail')
end

---@param text string
function GiftTipsTextDetailCell:OnFeedData(text)
	self.textDetail.text = text
    self:TextDetailHeightAdapt(text)
end


function GiftTipsTextDetailCell:TextDetailHeightAdapt(content)
    local cellHeight = self.goCell:GetComponent(typeof(CS.CellSizeComponent)).Height / 2
    local cellWidth = self.goCell:GetComponent(typeof(CS.CellSizeComponent)).Width
    local settings = self.textDetail:GetGenerationSettings(CS.UnityEngine.Vector2(0, self.textDetail:GetPixelAdjustedRect().size.y))
    local width = self.textDetail.cachedTextGeneratorForLayout:GetPreferredWidth(content, settings) / self.textDetail.pixelsPerUnit
    local rowNum = 1
    if width > cellWidth * 2 and cellWidth ~= 0 then
        rowNum = math.floor(width / cellWidth) + 1
    end
    self.rectTextDetail.sizeDelta = CS.UnityEngine.Vector2(self.rectTextDetail.sizeDelta.x, cellHeight * rowNum)
end

return GiftTipsTextDetailCell