local BaseTableViewProCell = require('BaseTableViewProCell')
local HeroCardItemListCell = class('HeroCardItemListCell',BaseTableViewProCell)

function HeroCardItemListCell:OnCreate(param)
    self.tableviewproTableItem = self:TableViewPro('')
end

function HeroCardItemListCell:OnFeedData(title)

end

return HeroCardItemListCell
