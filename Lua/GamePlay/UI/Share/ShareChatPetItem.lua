local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')


local SHARE_PET_QUALITY_BASE = "sp_chat_base_quality_0"

---@class ShareChatPetItem : BaseUIComponent
local ShareChatPetItem = class('ShareChatPetItem', BaseUIComponent)

function ShareChatPetItem:OnCreate()
    self.imgQualityBase = self:Image('p_quality_base')
    self.imgQualityHead = self:Image('p_quality_head')
    self.imgIconPet = self:Image('p_icon_pet')
    self.textPetName = self:Text('p_text_pet_name')
    -- self.imgAptitude1 = self:Image('p_aptitude_1')
    -- self.imgAptitude2 = self:Image('p_aptitude_2')
    -- self.imgAptitude3 = self:Image('p_aptitude_3')
        --- @type PetStarLevelComponent
    self.group_star = self:LuaObject('group_star')
end

function ShareChatPetItem:RefreshPet(param)
    self.skillLevels = param.skillLevels
    local petCfg = ModuleRefer.PetModule:GetPetCfg(param.configID)
    g_Game.SpriteManager:LoadSprite(SHARE_PET_QUALITY_BASE .. petCfg:Quality(), self.imgQualityBase)
    self:LoadSprite(petCfg:Icon(), self.imgIconPet)
    self.textPetName.text = I18N.Get(petCfg:Name())
	g_Game.SpriteManager:LoadSprite("sp_hero_frame_circle_" .. (petCfg:Quality() + 2), self.imgQualityHead)
    -- local randAttrCfg = ConfigRefer.PetRandomAttrItem:Find(param.z)
	-- if (randAttrCfg) then
	-- 	local sp1 = ModuleRefer.PetModule:GetPetAttrQualitySP(randAttrCfg:AttrQuality(1))
	-- 	g_Game.SpriteManager:LoadSprite(sp1, self.imgAptitude1)
	-- 	local sp2 = ModuleRefer.PetModule:GetPetAttrQualitySP(randAttrCfg:AttrQuality(2))
	-- 	g_Game.SpriteManager:LoadSprite(sp2, self.imgAptitude2)
	-- 	local sp3 = ModuleRefer.PetModule:GetPetAttrQualitySP(randAttrCfg:AttrQuality(3))
	-- 	g_Game.SpriteManager:LoadSprite(sp3, self.imgAptitude3)
	-- end
    self:SetStars()
end

function ShareChatPetItem:SetStars()
    if self.group_star then
        if self.skillLevels then
            local param = {skillLevels = self.skillLevels}
            self.group_star:FeedData(param)
            self.group_star:SetVisible(true)
        else
            self.group_star:SetVisible(false)
        end
    end
end

return ShareChatPetItem