local BaseTableViewProCell = require('BaseTableViewProCell')
local HeroCardProbabilityCell = class('HeroCardProbabilityCell',BaseTableViewProCell)

function HeroCardProbabilityCell:OnCreate(param)
    self.textQuantity = self:Text('p_text_quantity')
    self.textNumber = self:Text('p_text_number')
end

function HeroCardProbabilityCell:OnFeedData(data)
    self.textQuantity.text = data.qualityText
    self.textNumber.text = data.probablilityText
end

return HeroCardProbabilityCell
