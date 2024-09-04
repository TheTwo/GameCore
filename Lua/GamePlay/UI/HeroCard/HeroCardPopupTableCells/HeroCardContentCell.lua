local BaseTableViewProCell = require('BaseTableViewProCell')
local HeroCardContentCell = class('HeroCardContentCell',BaseTableViewProCell)

function HeroCardContentCell:OnCreate(param)
    self.textContent = self:Text('p_text_content')
end

function HeroCardContentCell:OnFeedData(data)
    self.textContent.text = data.content
end

return HeroCardContentCell
