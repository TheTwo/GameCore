local ModuleRefer = require('ModuleRefer')
local Utils = require('Utils')
local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')

---@class UIPetAttrLockCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIPetAttrLockCell = class('UIPetAttrLockCell', BaseTableViewProCell)

function UIPetAttrLockCell:OnCreate()
    self.textLv = self:Text('p_text_lv')
    self.imgIconStrengthen = self:Image('p_icon_strengthen')
    self.goIconSatr1 = self:GameObject('p_icon_satr_1')
    self.goIconSatr2 = self:GameObject('p_icon_satr_2')
    self.goIconSatr3 = self:GameObject('p_icon_satr_3')
    self.goIconSatr4 = self:GameObject('p_icon_satr_4')
    self.goIconSatr5 = self:GameObject('p_icon_satr_5')

    self.imgIconSatr1 = self:Image('p_icon_satr_1')
    self.imgIconSatr2 = self:Image('p_icon_satr_2')
    self.imgIconSatr3 = self:Image('p_icon_satr_3')
    self.imgIconSatr4 = self:Image('p_icon_satr_4')
    self.imgIconSatr5 = self:Image('p_icon_satr_5')

	self.goBaseAdditionLock = self:GameObject("p_base_basics_lock")
	self.goBaseAddition = self:GameObject("p_base_addition_lock")
    self.animtriggerTrigger = self:AnimTrigger('trigger_lock')
	if Utils.IsNotNull(self.goBaseAdditionLock) then
        self.goBaseAdditionLock:SetActive(false)
    end
    if Utils.IsNotNull(self.goBaseAddition) then
        self.goBaseAddition:SetActive(false)
    end
    if Utils.IsNotNull(self.animtriggerTrigger) then
        self.animtriggerTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        self.animtriggerTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
    end
    self.stars = {self.goIconSatr1, self.goIconSatr2, self.goIconSatr3, self.goIconSatr4, self.goIconSatr5}
    self.imgStars = {self.imgIconSatr1, self.imgIconSatr2, self.imgIconSatr3, self.imgIconSatr4, self.imgIconSatr5}
end

function UIPetAttrLockCell:OnFeedData(param)
	if Utils.IsNotNull(self.goBaseAdditionLock) then
		self.goBaseAdditionLock:SetActive(param.showBase)
    end
    if Utils.IsNotNull(self.goBaseAddition) then
		self.goBaseAddition:SetActive(param.showBase)
    end
    local unlockLevel = param.unlockLevel
    local petId = param.petId
    local stageLevel = math.floor(unlockLevel / 5) + 1
	local showIndex = unlockLevel % 5
	if showIndex ~= 0 then
		stageLevel = stageLevel + 1
        for i, star in ipairs(self.imgStars) do
			star.gameObject:SetActive(i <= showIndex)
			if i <= showIndex then
				if i < #self.imgStars then
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s", star)
				else
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l", star)
				end
			end
		end
	else
        for i, star in ipairs(self.imgStars) do
			-- if i < #self.imgStars then
			-- 	g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s", star)
			-- else
			-- 	g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l", star)
			-- end
			star.gameObject:SetActive(false)
		end
	end
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
	local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
    if stageLevel <= ConfigRefer.PetConsts:PetRankIconLength() then
        local icon = ConfigRefer.PetConsts:PetRankIcon(stageLevel)
		self:LoadSprite(icon, self.imgIconStrengthen)
	end
    if param.isUnlockItem then
        param.isUnlockItem = false
        if Utils.IsNotNull(self.animtriggerTrigger) then
            self.animtriggerTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
                g_Game.EventManager:TriggerEvent(EventConst.PET_REFRESH_UNLOCK_ITEM)
            end)
        end
    end
    self.textLv.text = I18N.Get("pet_extra_attr_unlock_rank_name")
    self.showUnlock = param.showUnlock
end

function UIPetAttrLockCell:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.PET_BREAK_UP, Delegate.GetOrCreate(self, self.RefreshUnlockState))
end

function UIPetAttrLockCell:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.PET_BREAK_UP, Delegate.GetOrCreate(self, self.RefreshUnlockState))
end

function UIPetAttrLockCell:RefreshUnlockState(isCanBreak)
    if self.showUnlock and isCanBreak then
        self.textLv.text = I18N.Get("pet_rank_up_attr_unlock_des")
        if Utils.IsNotNull(self.animtriggerTrigger) then
            self.animtriggerTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
        end
    else
        if Utils.IsNotNull(self.animtriggerTrigger) then
            self.animtriggerTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
        end
        self.textLv.text = I18N.Get("pet_extra_attr_unlock_rank_name")
    end
end

return UIPetAttrLockCell;
