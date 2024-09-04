local BaseTableViewProCell = require('BaseTableViewProCell')

---@class UIHeroStrengthenCellData
---@field strengthLv number

---@class UIHeroStrengthenCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIHeroStrengthenCell = class('UIHeroStrengthenCell', BaseTableViewProCell)

function UIHeroStrengthenCell:OnCreate()
    -- self.imgIconStrengthen = self:Image('p_icon_strengthen')
    self.go = self:GameObject('')
    self.imgIconSatr1 = self:Image('p_icon_satr_1')
    self.imgIconSatr2 = self:Image('p_icon_satr_2')
    self.imgIconSatr3 = self:Image('p_icon_satr_3')
    self.imgIconSatr4 = self:Image('p_icon_satr_4')
    self.imgIconSatr5 = self:Image('p_icon_satr_5')
    -- self.imgIconSatr6 = self:Image('p_icon_satr_6')
    self.strengthIconImages = {self.imgIconSatr1, self.imgIconSatr2, self.imgIconSatr3, self.imgIconSatr4, self.imgIconSatr5}
end

---@param param UIHeroStrengthenCellData
function UIHeroStrengthenCell:OnFeedData(num)
    if type(num) == "number" then
        for i = 1, #self.strengthIconImages do
            self.strengthIconImages[i]:SetVisible(i <= num)
        end
    else
        g_Logger.ErrorChannel("UIHeroStrengthenCell", "'num' is of wrong type.")
    end
end

return UIHeroStrengthenCell;
