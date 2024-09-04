local BaseTableViewProCell = require ('BaseTableViewProCell')
local I18N = require('I18N')
---@class StrengthenTipsSubTitleCell:BaseUIComponent
local StrengthenTipsSubTitleCell = class('StrengthenTipsSubTitleCell', BaseTableViewProCell)

function StrengthenTipsSubTitleCell:OnCreate()
    self.textSubtitle = self:Text('p_text_subtitle')
end

function StrengthenTipsSubTitleCell:OnFeedData(param)
    self.textSubtitle.text = param.title
end

return StrengthenTipsSubTitleCell
