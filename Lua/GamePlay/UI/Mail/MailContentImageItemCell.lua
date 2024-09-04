local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')

---@class MailContentImageItemCell : BaseTableViewProCell
---@field super BaseTableViewProCell
local MailContentImageItemCell = class('MailContentImageItemCell', BaseTableViewProCell)

function MailContentImageItemCell:ctor()
    MailContentImageItemCell.super.ctor(self)
    self.id = 0
end

function MailContentImageItemCell:OnCreate(param)
    self.image = self:Image("p_img")
end

function MailContentImageItemCell:OnFeedData(param)
    if (not param) then return end
    self.id = param.id
    self.cfg = param.cfg
    self:LoadSprite(self.cfg:Picture(), self.image)
end

return MailContentImageItemCell;
