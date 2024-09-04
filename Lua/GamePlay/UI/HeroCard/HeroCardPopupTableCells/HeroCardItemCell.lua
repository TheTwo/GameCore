local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local HeroCardItemCell = class('HeroCardItemCell',BaseTableViewProCell)

function HeroCardItemCell:OnCreate(param)
    self.imgFarme = self:Image('p_farme')
    self.imgImgHero = self:Image('p_img_hero')
    self.btnItem = self:Button('p_btn_item', Delegate.GetOrCreate(self, self.OnBtnItemClicked))
end

function HeroCardItemCell:OnFeedData(title)

end

function HeroCardItemCell:OnBtnItemClicked(args)

end

return HeroCardItemCell
