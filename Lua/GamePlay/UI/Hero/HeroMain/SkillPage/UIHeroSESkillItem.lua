local BaseTableViewProCell = require('BaseTableViewProCell')

local UIHeroSESkillItem = class('UIHeroSESkillItem',BaseTableViewProCell)

function UIHeroSESkillItem:OnCreate(param)
    self.imgIconInjure1 = self:Image('p_icon_injure_1')
    self.textInjure1 = self:Text('p_text_injure_1')
    self.textNumInjure1 = self:Text('p_text_num_injure_1')
    self.textAdd1 = self:Text('p_text_add_1')
end

---OnFeedData
---@param data ItemIconData
function UIHeroSESkillItem:OnFeedData(data)
    self.textInjure1.text = data.text
    self.textNumInjure1.text = data.number
    self.textAdd1.text = ""
    self:LoadSprite(data.icon, self.imgIconInjure1)
end

return UIHeroSESkillItem
