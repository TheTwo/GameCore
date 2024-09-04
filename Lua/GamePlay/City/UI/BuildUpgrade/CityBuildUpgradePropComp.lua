local BaseUIComponent = require ('BaseUIComponent')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
---@class CityBuildUpgradePropComp:BaseUIComponent
local CityBuildUpgradePropComp = class('CityBuildUpgradePropComp', BaseUIComponent)

local QUALITY_COLOR = {
    ColorConsts.quality_green,
    ColorConsts.quality_blue,
    ColorConsts.quality_purple,
    ColorConsts.quality_orange,
}

function CityBuildUpgradePropComp:OnCreate()
    self.goGrid = self:GameObject('')
    self.imgIcon = self:Image('p_icon')
    self.textGrid = self:Text('p_text_grid')
    self.textGridNow = self:Text('p_text_grid_now')
    self.goArrow = self:GameObject('arrow')
    self.imgBase = self:Image('p_base')
    self.textGridAfter = self:Text('p_text_grid_after')
end

---@param data CityCitizenData
function CityBuildUpgradePropComp:OnFeedData(data)
    self.textGrid.text = data.propName
    self.goArrow:SetActive(data.propNow ~= nil and data.propNext ~= nil)
    if data.propNow then
        self.textGridNow.text = data.propNow
    else
        self.textGridNow.text = ""
    end
    if data.propNext then
        self.textGridAfter.text = data.propNext
    else
        self.textGridAfter.text = ""
    end
    if data.propIcon then
        g_Game.SpriteManager:LoadSprite(data.propIcon, self.imgIcon)
    end
    if data.quality and data.quality >= 0 and data.quality < 99 then
        self.imgBase.gameObject:SetActive(true)
        self.imgBase.color = UIHelper.TryParseHtmlString(QUALITY_COLOR[data.quality + 1])
    else
        self.imgBase.gameObject:SetActive(false)
    end
end

return CityBuildUpgradePropComp