local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
---@type MailModule
local Mail = ModuleRefer.MailModule

---@class SkillTipTextCell : BaseTableViewProCell
local SkillTipTextCell = class('SkillTipTextCell', BaseTableViewProCell)

function SkillTipTextCell:ctor()
    self.id = 0
end

function SkillTipTextCell:OnCreate(param)
    self.text = self:Text("")
end

function SkillTipTextCell:OnShow(param)
end

function SkillTipTextCell:OnOpened(param)
end

function SkillTipTextCell:OnClose(param)
end

function SkillTipTextCell:OnFeedData(text)
    self.text.text = text
end

function SkillTipTextCell:Select(param)

end

function SkillTipTextCell:UnSelect(param)

end

return SkillTipTextCell;
