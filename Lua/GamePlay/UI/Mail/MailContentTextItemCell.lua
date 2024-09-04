local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')

---@class MailContentTextItemCell : BaseTableViewProCell
---@field super BaseTableViewProCell
local MailContentTextItemCell = class('MailContentTextItemCell', BaseTableViewProCell)

function MailContentTextItemCell:ctor()
    MailContentTextItemCell.super.ctor(self)
    self.id = 0
end

function MailContentTextItemCell:OnCreate(param)
    self.text = self:Text("")
end

function MailContentTextItemCell:OnFeedData(param)
    if (not param) then return end
    self.id = param.id
    self.text.text = param.text
end

return MailContentTextItemCell;
