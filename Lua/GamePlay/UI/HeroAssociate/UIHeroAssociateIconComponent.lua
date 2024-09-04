local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local TagType = require('TagType')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local ArtResourceUtils = require('ArtResourceUtils')

---@class AssociateIconParam
---@field cfgData HeroAssociateData
---@field tagType number @TagType
---@field tagId number @AssociatedTagConfigCell.Id

---@class UIHeroAssociateIconComponent : BaseUIComponent
local UIHeroAssociateIconComponent = class('UIHeroAssociateIconComponent', BaseUIComponent)

function UIHeroAssociateIconComponent:ctor()

end

function UIHeroAssociateIconComponent:OnCreate()
    -- self.imgBase = self:Image('p_base')
    self.imgIcon = self:Image('p_icon')
    self.vfxTrigger = self:AnimTrigger('trigger')
end

---@param param AssociateIconParam
function UIHeroAssociateIconComponent:OnFeedData(param)
    if param.cfgData then
        local cfgData = param.cfgData
        local tagCfg = cfgData.tagCfg[param.tagType]
        if tagCfg then
            self:LoadSprite(tagCfg.icon, self.imgIcon)
            -- self:LoadSprite(tagCfg.base,self.imgBase)
        end
    elseif param.tagId then
        local tagCfg = ConfigRefer.AssociatedTag:Find(param.tagId)
        if tagCfg then
            self.imgIcon.gameObject:SetActive(true)
            local icon = ArtResourceUtils.GetUIItem(tagCfg:Icon())
            if param.isWhite then
                icon = icon .. "_w"
            end

            g_Game.SpriteManager:LoadSprite(icon, self.imgIcon)
            -- self:LoadSprite(tagCfg:Base(),self.imgBase)
        else
            self.imgIcon.gameObject:SetActive(false)
        end
    end
    if param.playVfx then
        self.vfxTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
    end
end

return UIHeroAssociateIconComponent
