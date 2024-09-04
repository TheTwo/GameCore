local BaseTableViewProCell = require ('BaseTableViewProCell')
local UIHelper = require('UIHelper')

---@class StrengthenTipsItemCell:BaseUIComponent
local StrengthenTipsItemCell = class('StrengthenTipsItemCell', BaseTableViewProCell)

function StrengthenTipsItemCell:OnCreate()
    self.textContent = self:Text('p_text_content')
    self.textContentNum = self:Text('p_text_content_num')
end

function StrengthenTipsItemCell:OnFeedData(param)
    self.textContent.text = param.title
    self.textContentNum.text = param.num
    if param.color then
        self.textContentNum.text = UIHelper.GetColoredText(param.num, param.color)
    end
end

return StrengthenTipsItemCell
