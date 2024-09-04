local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local PetSkillDefine = require('PetSkillDefine')
local ArtResourceUtils = require('ArtResourceUtils')
local UIHelper = require('UIHelper')
local HeroUIUtilities = require('HeroUIUtilities')

---@class UIPetMainLockedPet : BaseTableViewProCell
local UIPetMainLockedPet = class('UIPetMainLockedPet', BaseTableViewProCell)

function UIPetMainLockedPet:ctor()

end

function UIPetMainLockedPet:OnCreate()
    self.p_btn_pet = self:Button('p_btn_pet', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_base_frame = self:Image('p_base_frame')
    self.mask = self:Image('mask')
    self.p_img_pet = self:Image('p_img_pet')
end

function UIPetMainLockedPet:OnFeedData(param)
    self.data = param
    self.onClick = param.onClick
    local cfg = ModuleRefer.PetModule:GetPetCfg(param.cfgId)
    local quality = cfg:Quality()
    local petIcon = UIHelper.GetFitPetHeadIcon(self.p_img_pet, cfg)
    g_Game.SpriteManager:LoadSprite(petIcon, self.p_img_pet)
    local rarityCfg = ConfigRefer.PetRarity:Find(quality)
    if (rarityCfg) then
        local frame = HeroUIUtilities.GetQualitySpriteID(quality)
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(frame), self.p_base_frame)
    end
end

function UIPetMainLockedPet:OnBtnClick(param)
    if self.onClick then
        self.onClick(self.data.cfgId)
    end
end

return UIPetMainLockedPet
