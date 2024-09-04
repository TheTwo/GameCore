local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require("ModuleRefer")
local UIHelper = require("UIHelper")
local ColorConsts = require('ColorConsts')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
---@class UITroopHeroSelectionCellPvpTemp : BaseTableViewProCell
---@field data HeroConfigCache
local UITroopHeroSelectionCellPvpTemp = class('UITroopHeroSelectionCellPvpTemp', BaseTableViewProCell)

---@class UITroopHeroSelectionCellPvpTempData
---@field heroId number
---@field hp number @若为空则取编队英雄血量
---@field maxHpAddPct number @当前选中状态下的最大血量加成
---@field oriMaxHpAddPct number @从Preset数据中得到的原始最大血量加成
---@field petId number @若为空则取英雄绑定的宠物
---@field simpleMode boolean
---@field selected boolean
---@field disable boolean
---
---@field onClick fun()
---@field onDragBegin fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)
---@field onDrag fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)
---@field onDragEnd fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)

function UITroopHeroSelectionCellPvpTemp:ctor()

end

function UITroopHeroSelectionCellPvpTemp:OnCreate()
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
	---@type NotificationNode
	self.notifyNode = self:LuaObject('child_reddot_default')
	self.textInjured = self:Text('p_text_injuried','formation_injuring')
	self.hpFile = self:Image('p_fill')

	self:Button('child_card_hero_s', Delegate.GetOrCreate(self,self.OnCellClick))

	-- self:DragEvent("child_card_hero_s",
	-- 	Delegate.GetOrCreate(self,self.OnHeroCellDragBegin),
	-- 	Delegate.GetOrCreate(self,self.OnHeroCellDrag),
	-- 	Delegate.GetOrCreate(self,self.OnHeroCellDragEnd),
	-- 	true
	-- )

end

function UITroopHeroSelectionCellPvpTemp:OnOpened(param)
	if self.notifyNode then
		self.notifyNode:HideAllRedDot()
	end
end


function UITroopHeroSelectionCellPvpTemp:OnShow(param)

end


function UITroopHeroSelectionCellPvpTemp:OnClose(param)
end

---@param data UITroopHeroSelectionCellPvpTempData
function UITroopHeroSelectionCellPvpTemp:OnFeedData(data)
	if (data) then
		self.data = data
		local hp = ModuleRefer.TroopModule:GetTroopHeroHp(data.heroId)
		local oriHpMax = ModuleRefer.TroopModule:GetTroopHeroHPMax(data.heroId, data.oriMaxHpAddPct or 0)
		local hpMax = ModuleRefer.TroopModule:GetTroopHeroHPMax(data.heroId, data.maxHpAddPct or 0)
		hp = math.floor((hp / oriHpMax) * hpMax)
		local battleMinHpPct = ConfigRefer.ConstMain:PresetBattleHeroHpPercentThreshold() / 100
		local isInjured = (hp  < math.floor(hpMax * battleMinHpPct)) and not data.simpleMode
		local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(data.heroId)
		---@type HeroInfoData
		local compData = {}
		compData.heroData = heroData
		-- compData.onClick = data.onClick
		compData.hideJobIcon = isInjured
		compData.hideStyle = isInjured
		compData.hideStrengthen = isInjured
		compData.showInjured = isInjured
		compData.hideName = data.simpleMode
		compData.onClick = Delegate.GetOrCreate(self, self.OnCellClick)
		self.heroComp:FeedData(compData)

		self.hpSlider.value = math.clamp01(hp / hpMax)
		self.hpText.text = tostring(hp) .. "/" .. tostring(math.floor(hpMax))

		-- 简易模式
		if (data.simpleMode) or isInjured then
			self.goHpComp:SetActive(false)
			-- self.hpSlider.gameObject:SetActive(false)
			-- self.hpText.gameObject:SetActive(false)
		else
			self.goHpComp:SetActive(true)
			-- self.hpSlider.gameObject:SetActive(true)
			-- self.hpText.gameObject:SetActive(true)
		end

		self.hpFile.color = UIHelper.TryParseHtmlString(isInjured and ColorConsts.army_red or ColorConsts.white)
		if self.textInjured then
			self.textInjured:SetVisible(isInjured)
		end

		-- if data.selected then
		-- 	self.heroComp:ChangeStateSelect(true)
		-- else
		-- 	self.heroComp:ChangeStateSelect(false)
		-- end
		local needGray = false
		local needDark = false
		if data.selected then
			self.goSelected:SetVisible(true)
			needDark = true
		else
			self.goSelected:SetVisible(false)
		end

		if data.disable then
			needGray = true
			-- self.canvasgroupHero.alpha = 0.5
			self.goBaseOtherTeam:SetVisible(true)
			self.textTeamIndex.text = tostring( ModuleRefer.TroopModule:GetHeroTeamIndex(data.heroId) )
		else
			self.goBaseOtherTeam:SetVisible(false)
			-- self.canvasgroupHero.alpha = 1
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
		self:CheckHeroRedState(data.heroId,data.selected or data.disable )
	end
end

function UITroopHeroSelectionCellPvpTemp:Select(param)

end

function UITroopHeroSelectionCellPvpTemp:UnSelect(param)

end

function UITroopHeroSelectionCellPvpTemp:CheckHeroRedState(heroId,isSelected)
	if isSelected then
		self.notifyNode:HideAllRedDot()
		return
	end
    -- local heroHeadIconNode = ModuleRefer.NotificationModule:GetDynamicNode("HeroHeadIcon" .. heroId, NotificationType.HERO_HEAD_ICON)
    -- ModuleRefer.NotificationModule:AttachToGameObject(heroHeadIconNode, self.notifyNode.go, self.notifyNode.redDot)
    local isNew = ModuleRefer.HeroModule:CheckHeroHeadIconNew(heroId)
    --如果是新英雄则需要更换对应显示的红点类型
    if isNew then
        -- heroHeadIconNode.uiNode:ChangeToggleObject(self.notifyNode.redNew)
		self.notifyNode:ShowNewRedDot()
    else
        self.notifyNode:HideAllRedDot()
    end
end

function UITroopHeroSelectionCellPvpTemp:OnCellClick()
	if self.data.onClick then
		self.data.onClick(self.data)
	end
end

function UITroopHeroSelectionCellPvpTemp:OnHeroCellDragBegin(go,pointData)
	if self.data.disable or self.data.selected then
		return
	end
	UIHelper.SetGray(self.heroComp.CSComponent.gameObject, true)
	if self.data.onDragBegin then
		self.data.onDragBegin(go,pointData,self.data)
	end
end

function UITroopHeroSelectionCellPvpTemp:OnHeroCellDrag(go,pointData)
	if self.data.disable or self.data.selected then
		return
	end
	if self.data.onDrag then
		self.data.onDrag(go,pointData,self.data)
	end
end

function UITroopHeroSelectionCellPvpTemp:OnHeroCellDragEnd(go,pointData)
	if self.data.disable or self.data.selected then
		return
	end
	UIHelper.SetGray(self.heroComp.CSComponent.gameObject, false)
	if self.data.onDragEnd then
		self.data.onDragEnd(go,pointData,self.data)
	end
end


return UITroopHeroSelectionCellPvpTemp;
