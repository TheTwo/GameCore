local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class SkillTipTitleCell : BaseTableViewProCell
local SkillTipTitleCell = class('SkillTipTitleCell', BaseTableViewProCell)

function SkillTipTitleCell:ctor()

end

function SkillTipTitleCell:OnCreate(param)
    self.textTitle = self:Text('p_text_title')
end

function SkillTipTitleCell:OnShow(param)
end

function SkillTipTitleCell:OnOpened(param)
end

function SkillTipTitleCell:OnClose(param)
end

function SkillTipTitleCell:OnFeedData(text)
    self.textTitle.text = text
end

function SkillTipTitleCell:Select(param)

end

function SkillTipTitleCell:UnSelect(param)

end

return SkillTipTitleCell
