local BaseTableViewProCell = require('BaseTableViewProCell')
local HeroCardTitleCell = class('HeroCardTitleCell',BaseTableViewProCell)

function HeroCardTitleCell:OnCreate(param)
    self.textTitle = self:Text('')
end

function HeroCardTitleCell:OnFeedData(data)
    self.textTitle.text = data.title
end

return HeroCardTitleCell
