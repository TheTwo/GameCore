local BaseUIComponent = require("BaseUIComponent")
local ConfigRefer = require("ConfigRefer")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local CardTypeEnum = require("CardType")
local UIHelper = require("UIHelper")
local Utils = require("Utils")

---@class CommonSkillCard:BaseUIComponent
---@field super CommonSkillCard
local CommonSkillCard = class("CommonSkillCard", BaseUIComponent)

function CommonSkillCard:OnCreate()
    self.selfTrans = self:Transform("")
    self.selfGo = self:GameObject("")
    self.defaultNode = self:GameObject("p_group_card_default")
    self.addNode = self:Button("p_btn_add", Delegate.GetOrCreate(self, self.OnClickSkillCard))
    self.selected = self:GameObject("p_img_select")
	self.selected2 = self:GameObject("p_img_select_bg")
    self.cardBtn = self:Button("p_btn_mask_card", Delegate.GetOrCreate(self, self.OnClickSkillCard))
	self.cardBtnImg = self:Image("p_btn_mask_card")
    self.cardImg = self:Image("p_img_card")
	self.energyNode = self:GameObject("energy")
    ---@type CommonHeroHeadIcon
    self.heroIcon = self:LuaObject('child_card_hero_s')
    self.cd = self:Image("p_img_black")
	self.textCd = self:Image("p_cd")
	self.textCdText = self:Text("p_text_cd")
    self.heroNode = self:GameObject("p_card_hero")
    self.goIconLock = self:GameObject("p_icon_lock")
    self.battleIcon = self:GameObject("p_icon_battle")
    self.toggleItem = self:GameObject("p_toggle")
    self.selectToggle = self:Toggle("child_toggle", Delegate.GetOrCreate(self, self.OnSelectSkill))
    self.deadCard = self:GameObject("p_img_death")
    ---@type NotificationNode
    self.notification = self:LuaObject("child_reddot_default")
	self.cardFrame = self:Image("p_farme")
	self.lvNode = self:GameObject("p_lv")
	self.lvText = self:Text("p_text_lv")
    ---@type KheroSkillLogicalSeConfigCell
    self.skillCfgCell = nil
    ---@type HeroesConfigCell
    self.heroConfigCell = nil
    self.cardCfg = nil
    self.energy = 0
	---@type CS.FpAnimation.FpAnimationCommonTrigger
	self.vxTrigger = self:BindComponent("vx_trigger", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end

function CommonSkillCard:GetVxTrigger()
	return self.vxTrigger
end

---@param self CommonSkillCard
---@return HeroesConfigCell
function CommonSkillCard:GetHeroCfgCell()
    return self.heroConfigCell
end

---@param self CommonSkillCard
---@return KheroSkillLogicalSeConfigCell
function CommonSkillCard:GetSkillCfgCell()
    return self.skillCfgCell
end

---@param self CommonSkillCard
---@return CardConfigCell
function CommonSkillCard:GetCardCfgCell()
    return self.cardCfg
end

---@param self CommonSkillCard
---@param dead boolean
---@param showRedFrame boolean
function CommonSkillCard:SetDead(dead, showRedFrame)
    if (showRedFrame) then
        self.deadCard:SetActive(dead)
    end
end

function CommonSkillCard:GetEnergy()
    return self.energy
end

function CommonSkillCard:OnFeedData(param)
    self.onClick = param.onClick

    if (self.defaultNode) then
        if (param.showAddNode == true) then
            self.defaultNode:SetActive(false)
            self.addNode.gameObject:SetActive(true)
            return
        else
            self.defaultNode:SetActive(true)
            self.addNode.gameObject:SetActive(false)
        end
    end

    self.cardId = param.cardId
    self.petBindHeroCfgId = param.petBindHeroCfgId
	self.skillLevel = param.skillLevel or 1
	self.showSkillLevel = param.showSkillLevel
    self.getSelectCount = param.getSelectCount
    self.onSelected = param.onSelected
    self.maxSelectCount = param.maxSelectCount

	if (param.disableCardClick) then
		self.cardImg.raycastTarget = false
		self.cardBtnImg.raycastTarget = false
	else
		self.cardImg.raycastTarget = true
		self.cardBtnImg.raycastTarget = true
	end
    
    if (param.redDot) then
        ModuleRefer.NotificationModule:AttachToGameObject(param.redDot, self.notification.go, self.notification.redDot)
    elseif (param.redDotNew) then
        ModuleRefer.NotificationModule:AttachToGameObject(param.redDotNew, self.notification.go, self.notification.redNew)
    elseif (param.redDotText) then
        ModuleRefer.NotificationModule:AttachToGameObject(param.redDotText, self.notification.go, self.notification.redTextGo, self.notification.redText)
    end

    self.cardCfg = ConfigRefer.Card:Find(self.cardId)
    if (self.cardCfg) then
        local cardType = self.cardCfg:CardTypeEnum()
        if cardType == CardTypeEnum.Pet then
            -- 显示绑定的英雄头像，用宠物的品质色显示卡牌的边框颜色
            if self.petBindHeroCfgId and self.petBindHeroCfgId > 0 then
                self.heroNode:SetActive(true)
                self.heroIcon:FeedData(self.petBindHeroCfgId)
                self.heroConfigCell = ConfigRefer.Heroes:Find(self.petBindHeroCfgId)
            end

            if (self.cardCfg:PetId() > 0) then
                local petCfg = ConfigRefer.Pet:Find(self.cardCfg:PetId())
                if (petCfg) then
                    g_Game.SpriteManager:LoadSprite("sp_se_pet_0" .. petCfg:Quality() + 1, self.cardFrame)
                end
            end
        elseif cardType == CardTypeEnum.Hero then
            -- 不显示英雄头像，但是用英雄的品质显示卡牌的边框颜色
            self.heroNode:SetActive(false)
            local heroId = self.cardCfg:HeroBind()
            if heroId and heroId > 0 then
                self.heroConfigCell = ConfigRefer.Heroes:Find(heroId)
                -- g_Game.SpriteManager:LoadSprite("sp_se_skill_0" .. (self.heroConfigCell:Quality() + 1), self.cardFrame)
            end
        else
            self.heroNode:SetActive(false)
            self.heroConfigCell = nil
        end

        self.energyNode:SetActive(false)

		if (self.showSkillLevel and self.skillLevel and self.skillLevel > 0) then
			self.lvNode:SetActive(true)
			self.lvText.text = self.skillLevel
		else
			if (Utils.IsNotNull(self.lvNode)) then
				self.lvNode:SetActive(false)
			end
		end

        local skillId = ModuleRefer.SkillModule:GetSkillLevelUpId(self.cardCfg:Skill(), self.skillLevel)
        self.skillCfgCell = ConfigRefer.KheroSkillLogicalSe:Find(skillId)
        if (self.skillCfgCell) then
            if (self.skillCfgCell:SkillPic() > 0) then
                self:LoadSprite(self.skillCfgCell:SkillPic(), self.cardImg)
            end
        end
    end

    if (param.isSelected ~= nil) then
        self:ChangeSelectState(param.isSelected)
    end

    if (param.isShowToggle ~= nil) then
        self.toggleItem:SetActive(param.isShowToggle)
    end

    if (param.isToggleOn ~= nil and self.selectToggle.isOn ~= param.isToggleOn) then
        self.selectToggle.isOn = param.isToggleOn
    end

    self:SetGray(param.isGray)
end

function CommonSkillCard:ResetToDefault()
    self.selected:SetVisible(false)
    self.selected2:SetVisible(false)
    self.energyNode:SetVisible(true)
    self.heroNode:SetVisible(false)
    self.cd:SetVisible(false)
    self.textCd:SetVisible(false)
    self.deadCard:SetVisible(false)
    self.battleIcon:SetVisible(false)
    self:SetGray(false)
end

---@param self CommonSkillCard
---@param isGray boolean
function CommonSkillCard:SetGray(isGray)
    if (not isGray) then isGray = false end
    if (self.defaultNode) then
        UIHelper.SetGray(self.defaultNode, isGray)
    else
        UIHelper.SetGray(self.CSComponent.gameObject, isGray)
    end
end

function CommonSkillCard:OnClickSkillCard()
    if self.onClick then
        self.onClick(self.cardId, self.skillLevel)
    end
end

function CommonSkillCard:OnSelectSkill(isSelected)
    if self.getSelectCount then
        local selectCount, _ = self.getSelectCount()
        if selectCount == self.maxSelectCount and isSelected then
            self.selectToggle.isOn = false
            return
        end
    end
    if self.onSelected then
        self.onSelected(isSelected, self.cardId)
    end
end

---@param self CommonSkillCard
function CommonSkillCard:GetCd()
    return self.cd
end

---@param self CommonSkillCard
---@return CS.UnityEngine.UI.Image, CS.UnityEngine.UI.Text
function CommonSkillCard:GetTextCd()
	return self.textCd, self.textCdText
end

function CommonSkillCard:RefreshSkillStatus(isSelected, heroId)
    if not self.cardId then
        return
    end
    local isUnlock = ModuleRefer.HeroModule:CheckCardUnlock(heroId, self.cardId)
    self.cd.fillAmount = 1
    self.cd.gameObject:SetActive(not isUnlock)
    self.goIconLock.gameObject:SetActive(not isUnlock)
    self.battleIcon.gameObject:SetActive(isSelected)
    self.toggleItem:SetActive(false)
    self:ChangeSelectState(false)
end

function CommonSkillCard:ChangeToSelectStatus(isSelected, heroId)
    if not self.cardId then
        return
    end
    local isUnlock = ModuleRefer.HeroModule:CheckCardUnlock(heroId, self.cardId)
    self.cd.fillAmount = 1
    self.cd.gameObject:SetActive(not isUnlock)
    self.goIconLock.gameObject:SetActive(not isUnlock)
    self.toggleItem:SetActive(isUnlock)
    if isUnlock then
        self.toggleItem:SetActive(true)
        self.selectToggle.isOn = isSelected
    end
end

function CommonSkillCard:ChangeSelectState(state)
    if (self.cardId == 1) then
        local debug = true;
    end
    self.selected:SetActive(state)
	self.selected2:SetActive(state)
end

return CommonSkillCard
