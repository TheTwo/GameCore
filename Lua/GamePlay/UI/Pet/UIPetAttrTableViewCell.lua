local ModuleRefer = require("ModuleRefer")
local BaseTableViewProCell = require('BaseTableViewProCell')

---@class UIPetAttrTableViewCell : BaseTableViewProCell
local UIPetAttrTableViewCell = class('UIPetAttrTableViewCell', BaseTableViewProCell)

function UIPetAttrTableViewCell:ctor()

end

function UIPetAttrTableViewCell:OnCreate()
    -- self.icon = self:Image("p_icon_addtion")
    self.text = self:Text("p_text_content")
    self.value = self:Text("p_text_content_num")
    self.line = self:GameObject('line')
end

function UIPetAttrTableViewCell:OnShow(param)
end

function UIPetAttrTableViewCell:OnOpened(param)
end

function UIPetAttrTableViewCell:OnClose(param)
end

function UIPetAttrTableViewCell:OnFeedData(data)
    self.line:SetVisible(data.index % 2 == 0)
    self.text.text = data.text
    self.value.text = data.value
end

function UIPetAttrTableViewCell:Select(param)

end

function UIPetAttrTableViewCell:UnSelect(param)

end

return UIPetAttrTableViewCell;
