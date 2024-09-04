local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class StrengthenTipsTitleCell:BaseUIComponent
local StrengthenTipsTitleCell = class('StrengthenTipsTitleCell', BaseTableViewProCell)

function StrengthenTipsTitleCell:OnCreate()
    self.textTitle = self:Text('p_text_title')
    self.textStrengthNum = self:Text('p_text_strength_num')
end

function StrengthenTipsTitleCell:OnFeedData(param)
    self.textTitle.text = param.title
    self.textStrengthNum.text = param.num
end

return StrengthenTipsTitleCell
