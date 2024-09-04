local BaseUIComponent = require('BaseUIComponent')
local UIHelper = require('UIHelper')
local UIHorizentalSwingComponentType = typeof(CS.DragonReborn.UIHorizentalSwingComponent)
local SELogger = require('SELogger')

---@class SEHudBattleSkillCardItem:BaseUIComponent
---@field super BaseUIComponent
local SEHudBattleSkillCardItem = class('SEHudBattleSkillCardItem',BaseUIComponent)

function SEHudBattleSkillCardItem:ctor()
    BaseUIComponent.ctor(self)
    self._cardCfgCell = nil
    self._cardServerId = 0
	self._bindHeroCfgId = 0
	self._level = 0
	self._lastCdNum = 0
end

function SEHudBattleSkillCardItem:OnCreate(param)
    self:InitObjects()
end

function SEHudBattleSkillCardItem:OnShow(param)

end

function SEHudBattleSkillCardItem:OnOpened(param)

end

function SEHudBattleSkillCardItem:OnHide(param)

end

function SEHudBattleSkillCardItem:OnClose(param)
    BaseUIComponent.OnClose(self,param)

end

---@param self SEHudBattleSkillCardItem
function SEHudBattleSkillCardItem:InitObjects()
	self.selfGo = self:GameObject("")
    self._empty4Raycast = self:BindComponent("", typeof(CS.Empty4Raycast))
    ---@type CommonSkillCard
    self._commonSkillCard = self:LuaObject("child_card_skill")

    -- 添加摇摆组件
    if (self._commonSkillCard) then
        local swing = self._commonSkillCard.CSComponent.gameObject:GetComponent(UIHorizentalSwingComponentType)
        if (not swing) then
            swing = self._commonSkillCard.CSComponent.gameObject:AddComponent(UIHorizentalSwingComponentType)
            swing.Target = self._commonSkillCard.CSComponent.transform
            swing.UICamera = g_Game.UIManager:GetUICamera()
        end
    end

    --self._deathMask = self:GameObject("p_img_death_mask")
    ---@type UnityEngine.CanvasGroup
    self._canvasGroup = self:BindComponent("", typeof(CS.UnityEngine.CanvasGroup))
end

---@param self SEHudBattleSkillCardItem
---@param enabled boolean
function SEHudBattleSkillCardItem:SetInputEnabled(enabled)
    if (self._empty4Raycast) then
        self._empty4Raycast.enabled = enabled
    end
end

---@param self SEHudBattleSkillCardItem
---@param cardRuntimeData SECardRuntimeData
function SEHudBattleSkillCardItem:SetCardInfo(cardRuntimeData)
	self._cardCfgCell = cardRuntimeData.cardConfigCell
    self._cardServerId = cardRuntimeData.cardServerId
	self._level = cardRuntimeData.fightCardInfo.CardLevel
	self._bindHeroCfgId = cardRuntimeData.fightCardInfo.BindHeroCfgId

	self._commonSkillCard:ResetToDefault()
    self._commonSkillCard:FeedData({
        cardId = self._cardCfgCell:Id(),
        petBindHeroCfgId = self._bindHeroCfgId,
		skillLevel = self._level,
    })

	-- 永久解决UE改动导致卡牌长按失效的问题
	if (self._commonSkillCard.cardBtn) then
		self._commonSkillCard.cardBtn.enabled = false
		local pl = self._commonSkillCard.cardBtn.gameObject:GetComponent(typeof(CS.UIPointerDownListener))
		if (pl) then
			SELogger.Log('UI改动可能导致卡牌长按失效!!!')
			CS.UnityEngine.Object.Destroy(pl)
		end
	end
end

function SEHudBattleSkillCardItem:GetEnergy()
    return self._commonSkillCard:GetEnergy()
end

---@param self SEHudBattleSkillCardItem
---@param selected boolean
function SEHudBattleSkillCardItem:SetSelected(selected)
    self._commonSkillCard:ChangeSelectState(selected)
end

---@param self SEHudBattleSkillCardItem
---@param amount number
function SEHudBattleSkillCardItem:SetCdFillAmount(amount)
	local img = self._commonSkillCard:GetTextCd()
	local cd = self._commonSkillCard:GetCd()
	if (cd) then
		if (img) then
			img.gameObject:SetActive(false)
		end
		local oldAmount = cd.fillAmount
		cd.gameObject:SetActive(true)
		cd.fillAmount = math.clamp01(amount)
		if (oldAmount > 0 and amount <= 0) then
			local vxTrigger = self._commonSkillCard:GetVxTrigger()
			if (vxTrigger) then
				vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
			end
		end
	end
end

function SEHudBattleSkillCardItem:SetCdNum(num)
	local img, text = self._commonSkillCard:GetTextCd()
	if (not img or not text) then return end

	local cd = self._commonSkillCard:GetCd()
	if (cd) then
		cd.gameObject:SetActive(false)
	end
	
	if (not num or num <= 0) then
		img.gameObject:SetActive(false)
	else
		img.gameObject:SetActive(true)
		text.text = num
	end
	
	if (self._lastCdNum > 0 and num <= 0) then
		local vxTrigger = self._commonSkillCard:GetVxTrigger()
		if (vxTrigger) then
			vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
		end
	end
	self._lastCdNum = num
end

function SEHudBattleSkillCardItem:PlayVxTrigger(triggerType)
	local vxTrigger = self._commonSkillCard:GetVxTrigger()
	if (vxTrigger) then
		vxTrigger:PlayAll(triggerType)
	end
end

---@param self SEHudBattleSkillCardItem
---@param dead boolean
function SEHudBattleSkillCardItem:SetDead(dead)
    self._commonSkillCard:SetDead(dead, true)
end

---@param self SEHudBattleSkillCardItem
---@param gray boolean
function SEHudBattleSkillCardItem:SetGray(gray)
    UIHelper.SetGray(self._commonSkillCard.selfGo, gray)
end

---@param self SEHudBattleSkillCardItem
---@param trans boolean
function SEHudBattleSkillCardItem:SetTransparent(trans)
    if (trans) then
        self._canvasGroup.alpha = 0
    else
        self._canvasGroup.alpha = 1
    end
end

---@param self SEHudBattleSkillCardItem
---@return number
function SEHudBattleSkillCardItem:GetCardCfgId()
    return self._cardCfgCell:Id()
end

function SEHudBattleSkillCardItem:GetLevel()
	return self._level
end

---@param self SEHudBattleSkillCardItem
---@return CardConfigCell
function SEHudBattleSkillCardItem:GetCardConfig()
    return self._cardCfgCell
end

function SEHudBattleSkillCardItem:GetCardServerId()
    return self._cardServerId
end

---@param self SEHudBattleSkillCardItem
---@return HeroesConfigCell
function SEHudBattleSkillCardItem:GetHeroCfgCell()
    return self._commonSkillCard:GetHeroCfgCell()
end

---@param self SEHudBattleSkillCardItem
---@return KheroSkillLogicalSeConfigCell
function SEHudBattleSkillCardItem:GetSkillCfgCell()
    return self._commonSkillCard:GetSkillCfgCell()
end

---@param self SEHudBattleSkillCardItem
---@return UnityEngine.Transform
function SEHudBattleSkillCardItem:GetCardTransform()
    return self._commonSkillCard.selfTrans
end

---@param self SEHudBattleSkillCardItem
---@return UnityEngine.Transform
function SEHudBattleSkillCardItem:GetDeathMaskTransform()
    if (not self._deathMask) then return nil end
    return self._deathMask.transform
end

function SEHudBattleSkillCardItem:ResetToDefault()
	self._commonSkillCard:ResetToDefault()
end

return SEHudBattleSkillCardItem
