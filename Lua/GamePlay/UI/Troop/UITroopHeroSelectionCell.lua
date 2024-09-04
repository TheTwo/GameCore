local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require("ModuleRefer")
local UIHelper = require("UIHelper")
local ColorConsts = require('ColorConsts')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
---@class UITroopHeroSelectionCell : BaseTableViewProCell
local UITroopHeroSelectionCell = class('UITroopHeroSelectionCell', BaseTableViewProCell)

---@class UITroopHeroSelectionCellData
---@field heroId number
---@field hp number @若为空则取编队英雄血量
---@field maxHpAddPct number @当前选中状态下的最大血量加成
---@field oriMaxHpAddPct number @从Preset数据中得到的原始最大血量加成
---@field petId number @若为空则取英雄绑定的宠物
---@field simpleMode boolean
---@field selected boolean
---@field otherTeamIndex number
---
---@field onClick fun()
---@field onDragBegin fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)
---@field onDrag fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)
---@field onDragEnd fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)

function UITroopHeroSelectionCell:ctor()
	self.tick = false
	self.tickTimer = 0
	self.longPressTime = 0.7
	self.shortPressTime = 0.2
end

function UITroopHeroSelectionCell:OnCreate()
	self.rectTransform = self:RectTransform('')
	---@see HeroInfoItemSmallComponent
	self.heroComp = self:LuaObject("child_card_hero_s")
	---@type CS.UnityEngine.CanvasGroup
	self.canvasgroupHero = self:BindComponent('child_card_hero_s', typeof(CS.UnityEngine.CanvasGroup))
	self.goHpComp = self:GameObject('p_hp')
	self.hpSlider = self:Slider("p_troop_hp")
	self.hpText = self:Text("p_text_hp")
	self.goSelected = self:GameObject("p_img_current_team")
	self.goBaseOtherTeam = self:GameObject('p_base_other_team')
    self.textTeamIndex = self:Text('p_text_team_index')
	---@see NotificationNode
	self.notifyNode = self:LuaObject('child_reddot_default')
	self.textInjured = self:Text('p_text_injuried','formation_injuring')
	self.hpFile = self:Image('p_fill')

	self.goInjured = self:GameObject("p_injuried")

	self.goCircleTimer = self:GameObject("child_progress_circle")
	self.imgCircleProgress = self:Image("p_progress")

	self:Button('child_card_hero_s', Delegate.GetOrCreate(self,self.OnCellClick))
end

function UITroopHeroSelectionCell:OnOpened(param)
	if self.notifyNode then
		self.notifyNode:HideAllRedDot()
	end
end

function UITroopHeroSelectionCell:OnShow()
	g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function UITroopHeroSelectionCell:OnHide()
	g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function UITroopHeroSelectionCell:OnRecycle()
	g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

---@param data UITroopHeroSelectionCellData
function UITroopHeroSelectionCell:OnFeedData(data)
	if (data) then
		self.data = data
		local hp = ModuleRefer.TroopModule:GetTroopHeroHp(data.heroId)
		local oriHpMax = ModuleRefer.TroopModule:GetTroopHeroHPMax(data.heroId, data.oriMaxHpAddPct or 0)
		local hpMax = ModuleRefer.TroopModule:GetTroopHeroHPMax(data.heroId, data.maxHpAddPct or 0)
		hp = math.floor((hp / oriHpMax) * hpMax)
		local battleMinHpPct = ConfigRefer.ConstMain:PresetBattleHeroHpPercentThreshold() / 100
		local isInjured = (hp <= math.floor(hpMax * battleMinHpPct)) and not data.simpleMode
		local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(data.heroId)
		---@type HeroInfoData
		local compData = {}
		compData.heroData = heroData
		compData.showInjured = isInjured
		compData.hideName = data.simpleMode
		compData.showLevelPrefix = true
		compData.onClick = Delegate.GetOrCreate(self, self.OnCellClick)
		compData.onPressDown = Delegate.GetOrCreate(self, self.OnPressDown)
		compData.onPressUp = Delegate.GetOrCreate(self, self.OnPressUp)
		self.heroComp:FeedData(compData)

		self.hpSlider.value = math.clamp01(hp / hpMax)

		-- 简易模式
		if (data.simpleMode) or isInjured then
			self.goHpComp:SetActive(false)
		else
			self.goHpComp:SetActive(true)
		end

		self.hpFile.color = UIHelper.TryParseHtmlString(isInjured and ColorConsts.army_red or ColorConsts.white)
		if self.textInjured then
			self.textInjured:SetVisible(isInjured)
		end

		if self.goInjured then
			self.goInjured:SetActive(isInjured)
		end

		local needGray = false
		local needDark = false
		if data.selected then
			self.goSelected:SetVisible(true)
			needDark = true
		else
			self.goSelected:SetVisible(false)
		end

		if data.otherTeamIndex and data.otherTeamIndex > 0 then
			needGray = true
			self.goBaseOtherTeam:SetVisible(true)
			self.textTeamIndex.text = data.otherTeamIndex
		else
			self.goBaseOtherTeam:SetVisible(false)
		end

		if needGray then
			UIHelper.SetGray(self.heroComp.CSComponent.gameObject, true)
		else
			UIHelper.SetGray(self.heroComp.CSComponent.gameObject, false)
		end

		if needDark then
			self.heroComp:SetColor(UIHelper.TryParseHtmlString(ColorConsts.dark_grey))
		else
			self.heroComp:SetColor(UIHelper.TryParseHtmlString(ColorConsts.white))
		end

		self:CheckHeroRedState(data.heroId, data.selected or data.disable)
	end
end

function UITroopHeroSelectionCell:CheckHeroRedState(heroId,isSelected)
	if isSelected then
		self.notifyNode:HideAllRedDot()
		return
	end
    local isNew = ModuleRefer.HeroModule:CheckHeroHeadIconNew(heroId)
    --如果是新英雄则需要更换对应显示的红点类型
    if isNew then
		self.notifyNode:ShowNewRedDot()
    else
        self.notifyNode:HideAllRedDot()
    end
end

function UITroopHeroSelectionCell:OnCellClick()
	if self.data.onClick then
		self.data.onClick(self.data)
	end
end

function UITroopHeroSelectionCell:OnPressDown()
	self.tick = true
    self.tickTimer = 0
end

function UITroopHeroSelectionCell:OnPressUp()
	if self.tickTimer < self.longPressTime then
        -- self:OnCellClick()
    else
        ---@type UITroopHeroCellDetailParam
        local data = {}
        data.heroId = self.data.heroId
        data.rectTransform = self.rectTransform
        g_Game.UIManager:Open(UIMediatorNames.UITroopHeroCellDetailMediator, data)
    end

    self.tick = false
    self.tickTimer = 0
	self.goCircleTimer:SetActive(false)
end

function UITroopHeroSelectionCell:OnHeroCellDragBegin(go,pointData)
	if self.data.disable or self.data.selected then
		return
	end
	UIHelper.SetGray(self.heroComp.CSComponent.gameObject, true)
	if self.data.onDragBegin then
		self.data.onDragBegin(go,pointData,self.data)
	end
end

function UITroopHeroSelectionCell:OnHeroCellDrag(go,pointData)
	if self.data.disable or self.data.selected then
		return
	end
	if self.data.onDrag then
		self.data.onDrag(go,pointData,self.data)
	end
end

function UITroopHeroSelectionCell:OnHeroCellDragEnd(go,pointData)
	if self.data.disable or self.data.selected then
		return
	end
	UIHelper.SetGray(self.heroComp.CSComponent.gameObject, false)
	if self.data.onDragEnd then
		self.data.onDragEnd(go,pointData,self.data)
	end
end

function UITroopHeroSelectionCell:Tick(dt)
	if not self.tick then return end
	self.tickTimer = self.tickTimer + dt

	self.goCircleTimer:SetActive(self.tickTimer >= self.shortPressTime)
	local precent = self.tickTimer / self.longPressTime
	self.imgCircleProgress.fillAmount = precent
end


return UITroopHeroSelectionCell;
