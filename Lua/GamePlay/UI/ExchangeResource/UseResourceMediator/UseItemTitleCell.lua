local BaseTableViewProCell = require('BaseTableViewProCell')
local UseItemTitleCell = class('UseItemTitleCell',BaseTableViewProCell)

function UseItemTitleCell:OnCreate(param)
    self.textWay = self:Text('p_text_way')
end

function UseItemTitleCell:OnFeedData(data)
    self.textWay.text = data.title
end

return UseItemTitleCell
