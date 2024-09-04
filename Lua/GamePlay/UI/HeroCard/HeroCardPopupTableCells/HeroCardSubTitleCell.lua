local BaseTableViewProCell = require('BaseTableViewProCell')
local HeroCardSubTitleCell = class('HeroCardSubTitleCell',BaseTableViewProCell)

function HeroCardSubTitleCell:OnCreate(param)
    self.textTitle = self:Text('p_text_title')
end

function HeroCardSubTitleCell:OnFeedData(data)
    self.textTitle.text = data.title
end

return HeroCardSubTitleCell
