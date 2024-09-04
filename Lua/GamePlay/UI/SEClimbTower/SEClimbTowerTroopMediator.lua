local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIMediatorNames = require("UIMediatorNames")
local CommonDropDown = require("CommonDropDown")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local Utils = require("Utils")
local BistateButton = require("BistateButton")
local EventConst = require("EventConst")
local DBEntityPath = require("DBEntityPath")
local Screen = CS.UnityEngine.Screen
local AttackDistanceType = require("AttackDistanceType")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local HeroType = require("HeroType")
local KingdomMapUtils = require("KingdomMapUtils")
local SEHudTroopMediatorDefine = require("SEHudTroopMediatorDefine")

---@class SEClimbTowerTroopMediator : BaseUIMediator
local SEClimbTowerTroopMediator = class('SEClimbTowerTroopMediator', BaseUIMediator)

local MAX_TROOP_COUNT = 3
local MAX_HERO_COUNT = 3

local HERO_SORT_MODE_QUALITY = 1
local HERO_SORT_MODE_LEVEL = 2

local ATTR_DISP_POWER = 100
local ATTR_DISP_SPEED = 39

local I18N_SAVE_CHECK_SWITCH = "NewFormation_SaveAlertContent01"
local I18N_SAVE_CHECK_EXIT = "NewFormation_SaveAlertContent02"
local I18N_SAVE = "setower_btn_save"
local I18N_SAVE_AND_GO = "setower_btn_savenstart"
local I18N_GO = "setower_btn_start"

local PREF_KEY_NO_AUTO_SET = "ClimbTowerTroopNoAutoSet"

---@class SEClimbTowerTroopMediatorParam
---@field challengeMode boolean @挑战模式
---@field sectionId number @章节ID

function SEClimbTowerTroopMediator:ctor()
	self._player = nil
	self._selectedTroopIndex = 1
	self._editMode = false
	---@type table<number, number>
	self._editHeroList = {}
	---@type talbe<number, number>
	self._editPetList = {}
	---@type table<number, UITroopHeroCardData>
	self._heroCardData = {}
	self._heroSelectionMode = false
	self._heroSortMode = HERO_SORT_MODE_QUALITY
	self._selectedHeroSlot = 1
	self._draggingHeroCard = false
	---@type table<number, CS.UnityEngine.Rect>
	self._heroCardRects = {}
	self._heroCardPosList = {}
	self._uiCamera = nil
	---@type talbe<number, UIPetIconData>
	self._petDataList = {}
	self._selectingPetId = 0
	self._challengeMode = false
	self._sectionId = 0
	self._noAutoSet = 0
end

function SEClimbTowerTroopMediator:OnCreate()
	self:InitObjects()
end

function SEClimbTowerTroopMediator:InitObjects()
	---@type CommonPopupBackComponent
	self.backComp = self:LuaObject("child_popup_base_m")
	self.buttonClose = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnBackButtonClick))

	---@type table<number, CS.UnityEngine.UI.Button>
	self.troopButtons = {}
	self.troopButtons[1] = self:Button("p_btn_troop_1", Delegate.GetOrCreate(self, self.OnTroopButton1Click))
	self.troopButtons[2] = self:Button("p_btn_troop_2", Delegate.GetOrCreate(self, self.OnTroopButton2Click))
	self.troopButtons[3] = self:Button("p_btn_troop_3", Delegate.GetOrCreate(self, self.OnTroopButton3Click))

	---@type table<number, CS.UnityEngine.GameObject>
	self.troopButtonsNormal = {}
	self.troopButtonsNormal[1] = self:GameObject("p_status_n_1")
	self.troopButtonsNormal[2] = self:GameObject("p_status_n_2")
	self.troopButtonsNormal[3] = self:GameObject("p_status_n_3")

	---@type table<number, CS.UnityEngine.UI.Text>
	self.troopButtonsNormalText = {}
	self.troopButtonsNormalText[1] = self:Text("p_text_troop_n_1")
	self.troopButtonsNormalText[2] = self:Text("p_text_troop_n_2")
	self.troopButtonsNormalText[3] = self:Text("p_text_troop_n_3")

	---@type table<number, CS.UnityEngine.GameObject>
	self.troopButtonsSelected = {}
	self.troopButtonsSelected[1] = self:GameObject("p_status_select_1")
	self.troopButtonsSelected[2] = self:GameObject("p_status_select_2")
	self.troopButtonsSelected[3] = self:GameObject("p_status_select_3")

	---@type table<number, CS.UnityEngine.UI.Text>
	self.troopButtonsSelectedText = {}
	self.troopButtonsSelectedText[1] = self:Text("p_text_troop_select_1")
	self.troopButtonsSelectedText[2] = self:Text("p_text_troop_selected_2")
	self.troopButtonsSelectedText[3] = self:Text("p_text_troop_selected_3")

	---@type table<number, CS.UnityEngine.GameObject>
	self.troopButtonsLocked = {}
	self.troopButtonsLocked[1] = self:GameObject("p_status_lock_1")
	self.troopButtonsLocked[2] = self:GameObject("p_status_lock_2")
	self.troopButtonsLocked[3] = self:GameObject("p_status_lock_3")

	---@type table<number, CS.UnityEngine.UI.Text>
	self.troopButtonsLockedText = {}
	self.troopButtonsLockedText[1] = self:Text("p_text_troop_lock_1")
	self.troopButtonsLockedText[2] = self:Text("p_text_troop_lock_2")
	self.troopButtonsLockedText[3] = self:Text("p_text_troop_lock_3")

	---@type table<number, CS.UnityEngine.GameObject>
	self.troopButtonsLockedSelected = {}
	self.troopButtonsLockedSelected[1] = self:GameObject("p_status_lock_select_1")
	self.troopButtonsLockedSelected[2] = self:GameObject("p_status_lock_select_2")
	self.troopButtonsLockedSelected[3] = self:GameObject("p_status_lock_select_3")

	---@type table<number, CS.UnityEngine.UI.Text>
	self.troopButtonsLockedSelectedText = {}
	self.troopButtonsLockedSelectedText[1] = self:Text("p_text_troop_lock_select_1")
	self.troopButtonsLockedSelectedText[2] = self:Text("p_text_troop_lock_select_2")
	self.troopButtonsLockedSelectedText[3] = self:Text("p_text_troop_lock_select_3")

	---@type table<number, UITroopHeroCard>
	self.heroCardList = {}
	self.heroCardList[1] = self:LuaObject("child_slg_card")
	self.heroCardList[2] = self:LuaObject("child_slg_card_1")
	self.heroCardList[3] = self:LuaObject("child_slg_card_2")

	self.nonEmptyGroup = self:GameObject("p_group_n")
	self.emptyGroup = self:GameObject("p_group_empty")
	self.emptyGroupText = self:Text("p_text_empty")
	self.timeText = self:Text("p_text_time", "setower_refresh")

	self.powerText = self:Text("p_text_power")
	self.powerTextNum = self:Text("p_text_upgrade_1")

	self.heroSelectionPanelCloseButton = self:Button("p_btn_empty_list", Delegate.GetOrCreate(self, self.OnHeroSelectionCloseButtonClick))
	self.heroSelectionPanel = self:GameObject("p_content_hero_selection_list")
	self.heroSelectionTable = self:TableViewPro("p_table_hero")
	---@type CommonDropDown
	self.heroSelectionSortFilter = self:LuaObject("child_dropdown_class")
	self.heroSelectionCloseButton = self:Button("p_btn_hero_selection_close", Delegate.GetOrCreate(self, self.OnHeroSelectionCloseButtonClick))
	self.heroSelectionEmptyText = self:Text("p_text_empty_hero", "NewFormation_NoMoreHeroesToUse")
	self.heroSelectionListText = self:Text("p_text_list", "setower_btn_selecthero")

	self.hintText = self:Text("p_text_hint")

	---@type BistateButton
	self.buttonSave = self:LuaObject("child_comp_btn_b")

	---@type BistateButton
	self.buttonGo = self:LuaObject("p_btn_confirm_a")

	---@type UIPetSelectPopupComponent
	self.petSelection = self:LuaObject("child_pet_popup_select")

	self.autoSetText = self:Text("p_text_autoset", "setower_troop_autoset")
	self.autoSetButton = self:Button("p_autoset_toggle", Delegate.GetOrCreate(self, self.OnAutoSetButtonClick))
	self.autoSetStatusRecord = self:StatusRecordParent("p_autoset_toggle")
end

function SEClimbTowerTroopMediator:OnShow(param)
	self:InitData(param)
    self:InitUI()
    self:RefreshUI()
end

function SEClimbTowerTroopMediator:OnHide(param)
end

function SEClimbTowerTroopMediator:OnOpened(param)
end

function SEClimbTowerTroopMediator:OnClose(param)

end

--- 初始化数据
---@param self SEClimbTowerTroopMediator
---@param param SEClimbTowerTroopMediatorParam
function SEClimbTowerTroopMediator:InitData(param)
	self._challengeMode = param and param.challengeMode
	self._sectionId = param and param.sectionId or 0
	self._player = ModuleRefer.PlayerModule:GetPlayer()
	self._uiCamera = g_Game.UIManager:GetUICamera()

	self.backComp:FeedData({
		title = I18N.Get("setower_systemname_troop"),
		onClose = Delegate.GetOrCreate(self, self.OnBackButtonClick),	
	})

	local heroSortData = {}
    heroSortData.items = CommonDropDown.CreateData(
        "", I18N.Get("pet_filter_condition0"),
        "", I18N.Get("pet_filter_condition1")
    )
    heroSortData.defaultId = HERO_SORT_MODE_QUALITY
    heroSortData.onSelect = Delegate.GetOrCreate(self, self.OnHeroSortSelect)
    self.heroSelectionSortFilter:FeedData(heroSortData)

	self.buttonSave:FeedData({
		onClick = Delegate.GetOrCreate(self, self.OnButtonSaveClick),
		buttonState = BistateButton.BUTTON_TYPE.BROWN

	})
	self.buttonSave:SetButtonText(I18N.Get(I18N_SAVE))
	self.buttonSave:SetEnabled(false)

	self.buttonGo:FeedData({
		onClick = Delegate.GetOrCreate(self, self.OnButtonGoClick),
	})
	self.buttonGo:SetButtonText(I18N.Get(I18N_GO))

	if (self._challengeMode) then
		self.buttonGo.CSComponent.gameObject:SetActive(true)
	else
		self.buttonGo.CSComponent.gameObject:SetActive(false)
	end

	--self:SelectDefaultTroop()
	self._noAutoSet = g_Game.PlayerPrefsEx:GetIntByUid(PREF_KEY_NO_AUTO_SET, 0)
end

--- 选择默认编队
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:SelectDefaultTroop()
	if (self._challengeMode) then
		for i = 1, MAX_TROOP_COUNT do
			self._selectedTroopIndex = i
			local preset = self:GetPreset(i)
			for j = 1, MAX_HERO_COUNT do
				if (preset and preset.Heros and preset.Heros[j] and preset.Heros[j].Info and preset.Heros[j].Info.ConfigId > 0) then
					local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(preset.Heros[j].Info.ConfigId)
					if (heroData and heroData.dbData and heroData.dbData.ClimbTowerHpPercent > 0) then
						return
					end
				end
			end
		end
	end
	self._selectedTroopIndex = 1
end

--- 初始化UI
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:InitUI()
	self.timeText.gameObject:SetActive(false)
	for i = 1, MAX_HERO_COUNT do
		self._heroCardRects[i] = self.heroCardList[i].CSComponent.gameObject.transform:GetScreenRect(self._uiCamera)
		self._heroCardPosList[i] = self.heroCardList[i].CSComponent.gameObject.transform.localPosition
	end
	local dispConf = ConfigRefer.AttrDisplay:Find(ATTR_DISP_POWER)
	self.powerText.text = I18N.Get(dispConf:DisplayAttr())
end

--- 刷新UI
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:RefreshUI()
	if (self._noAutoSet == 0) then
		self:DoAutoSet()
	else
		self:RefreshSelectedTroopInfo()
	end
end

--- 刷新编队列表
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:RefreshTroopList()
	for i = 1, MAX_TROOP_COUNT do
		local isOpen = self:IsPresetOpen(i)
		self.troopButtonsLocked[i]:SetActive(not isOpen and self._selectedTroopIndex ~= i)
		self.troopButtonsLockedSelected[i]:SetActive(not isOpen and self._selectedTroopIndex == i)
		self.troopButtonsSelected[i]:SetActive(isOpen and self._selectedTroopIndex == i)
		self.troopButtonsNormal[i]:SetActive(isOpen and self._selectedTroopIndex ~= i)
		local troopDes = I18N.Get(ConfigRefer.ClimbTowerConst.TroopDes and ConfigRefer.ClimbTowerConst:TroopDes(i) or ("*" .. i))
		self.troopButtonsSelectedText[i].text = troopDes
		self.troopButtonsNormalText[i].text = troopDes
		self.troopButtonsLockedText[i].text = troopDes
		self.troopButtonsLockedSelectedText[i].text = troopDes
	end
	self:RefreshSelectedTroopInfo()
end

--- 编队是否开启
---@param self SEClimbTowerTroopMediator
---@param index number
---@return boolean, wds.ClimbTowerPreset
function SEClimbTowerTroopMediator:IsPresetOpen(index)
	local preset = self:GetPreset(index)
	if (not preset) then return false end
	return preset.IsOpen, preset
end

--- 编队是否可编辑
---@param self SEClimbTowerTroopMediator
---@param index number
---@return boolean, wds.ClimbTowerPreset
function SEClimbTowerTroopMediator:IsPresetEditable(index)
	local preset = self:GetPreset(index)
	if (not preset) then return false end
	return preset.IsOpen and preset.CanEdit, preset
end

---@return wds.ClimbTowerPreset
function SEClimbTowerTroopMediator:GetPreset(index)
	return self._player.PlayerWrapper2.ClimbTower.Presets[index]
end

--- 刷新选定的编队信息
---@param self SEClimbTowerTroopMediator
-- 英雄卡片
function SEClimbTowerTroopMediator:RefreshSelectedTroopInfo()
	local isOpen = self:IsPresetOpen(self._selectedTroopIndex)
	local editable = self:IsPresetEditable(self._selectedTroopIndex)

	if (not isOpen) then
		self.emptyGroup:SetActive(true)
		self.nonEmptyGroup:SetActive(false)
		local unlockSection = ModuleRefer.SEClimbTowerModule:GetTroopUnlockSection(self._selectedTroopIndex)
		if (unlockSection and unlockSection > 0) then
			local sectionCfg = ConfigRefer.ClimbTowerSection:Find(unlockSection)
			self.emptyGroupText.text = I18N.GetWithParams("setower_unlock_troop", sectionCfg and sectionCfg:Name())
		end
	else
		self.emptyGroup:SetActive(false)
		self.nonEmptyGroup:SetActive(true)
		local power = 0
		for i = 1, MAX_HERO_COUNT do
			local heroId, hp = self:GetHeroData(i)
			local petId = self:GetPetId(i)
			---@type UITroopHeroCardData
			local data = {}
			data.editable = editable			
			data.slotIndex = i
			data.heroCfgId = heroId
			data.heroHp = hp
			data.hpPreview = 0
			data.petCompId = petId
			data.heroHpMax = ModuleRefer.TroopModule:GetTroopHeroHPMax(heroId)
			data.onHeroInfoClick = Delegate.GetOrCreate(self, self.OnHeroCardClick)
			-- data.onHeroAddClick = Delegate.GetOrCreate(self, self.OnHeroCardAddClick)
			data.onHeroDeleteClick = Delegate.GetOrCreate(self, self.OnHeroCardDeleteClick)
			data.onPetClick = Delegate.GetOrCreate(self, self.OnPetClick)
			data.onDragBegin = Delegate.GetOrCreate(self, self.OnHeroCardDragBegin)
			data.onDragEnd = Delegate.GetOrCreate(self, self.OnHeroCardDragEnd)
			data.onDrag = Delegate.GetOrCreate(self, self.OnHeroCardDrag)
			self._heroCardData[i] = data
			self.heroCardList[i]:FeedData(data)
			if (heroId and heroId > 0) then
				power = power + ModuleRefer.HeroModule:GetHeroAttrDisplayValue(heroId, ATTR_DISP_POWER)
			end
			if (petId and petId > 0) then
				power = power + ModuleRefer.PetModule:GetPetAttrDisplayValue(petId, ATTR_DISP_POWER)
			end
		end
		self.powerTextNum.text = CS.System.String.Format("{0:#,0}", power)
		self.autoSetStatusRecord:ApplyStatusRecord(1 - self._noAutoSet)
	end
end

---@param self SEClimbTowerTroopMediator
---@param data UITroopHeroCardData
function SEClimbTowerTroopMediator:OnHeroCardClick(data)
	if (self._draggingHeroCard) then return end
	self._selectedHeroSlot = data.slotIndex
	self:RefreshHeroCardSelectedStatus()
	if (not self._heroSelectionMode) then
		self:OpenHeroSelectionPanel()
	end
end

--- 刷新英雄卡片选中状态
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:RefreshHeroCardSelectedStatus()
	for i = 1, MAX_HERO_COUNT do
		local data = self._heroCardData[i]
		if (data) then
			data.selected = i == self._selectedHeroSlot
		end
		self.heroCardList[i]:RefreshUI()
	end
end

---@param self SEClimbTowerTroopMediator
---@param data UITroopHeroCardData
function SEClimbTowerTroopMediator:OnHeroCardAddClick(data)
	if (self._draggingHeroCard) then return end

	self._selectedHeroSlot = data.slotIndex
	self:RefreshHeroCardSelectedStatus()
	if (not self._heroSelectionMode) then
		self:OpenHeroSelectionPanel()
	end
end

---@param self SEClimbTowerTroopMediator
---@param data UITroopHeroCardData
function SEClimbTowerTroopMediator:OnHeroCardDeleteClick(data)
	if (self._draggingHeroCard) then return end
	if (not data) then return end
	if (not data.heroCfgId or data.heroCfgId <= 0) then return end
	if (not self._editMode) then
		self:EnterEditMode()
	end
	self._editHeroList[data.slotIndex] = 0
	self._editPetList[data.slotIndex] = 0
	self:RefreshSelectedTroopInfo()
	self:OpenHeroSelectionPanel()
	self._selectedHeroSlot = data.slotIndex
	self:RefreshHeroCardSelectedStatus()
end

--- 进入编辑模式
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:EnterEditMode()
	self:SetToNoAutoSet()
	self._editMode = true

	local preset = self:GetPreset(self._selectedTroopIndex)
	self._editHeroList, self._editPetList = self:CreateClientTroopPresetCache(preset)

	self:RefreshButtonStatus()
end

---@param self SEClimbTowerTroopMediator
---@param preset wds.ClimbTowerPreset
function SEClimbTowerTroopMediator:CreateClientTroopPresetCache(preset)
	local heroList = {}
	local petList = {}
	if (preset and preset.Heros) then
		for i = 1, MAX_HERO_COUNT do
			if (preset.Heros[i]) then
				heroList[i] = preset.Heros[i].Info.ConfigId
				petList[i] = preset.Heros[i].Info.PetInfos and preset.Heros[i].Info.PetInfos[0] and preset.Heros[i].Info.PetInfos[0].CompId or 0
			else
				heroList[i] = 0
				petList[i] = 0
			end
		end
	end
	return heroList, petList
end

--- 退出编辑模式
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:ExitEditMode()
	self._editMode = false
	self:RefreshButtonStatus()
end

--- 刷新按钮状态
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:RefreshButtonStatus()
	if (self._editMode) then
		self.buttonSave:SetEnabled(true)
		self.buttonGo:SetButtonText(I18N.Get(I18N_SAVE_AND_GO))
	else
		self.buttonSave:SetEnabled(false)
		self.buttonGo:SetButtonText(I18N.Get(I18N_GO))
	end
end

---@param self SEClimbTowerTroopMediator
---@param data UITroopHeroCardData
function SEClimbTowerTroopMediator:OnPetClick(data)
	if (self._draggingHeroCard) then return end
	if (self._heroSelectionMode) then
		self:CloseHeroSelectionPanel()
	end

	self._selectedHeroSlot = data.slotIndex
	self:RefreshHeroCardSelectedStatus()
	---@type UIPetSelectPopupComponentParam
	local param = {
		showAllType = true,
		petDataPostProcess = Delegate.GetOrCreate(self, self.PetDataPostProcess),
		petDataFilter = Delegate.GetOrCreate(self, self.PetDataFilter),
		hintText = I18N.Get("formation-chongwu"),
		sortMode = 1,
		selectedType = -1,
	}
	self.petSelection:SetVisible(true, param)
end

--- 获取英雄数据
---@param self SEClimbTowerTroopMediator
---@param slot number
---@return number, number @heroId, hp
function SEClimbTowerTroopMediator:GetHeroData(slot)
	local heroId, hp
	if (self._editMode) then
		heroId = self._editHeroList[slot]
	else
		local preset = self:GetPreset(self._selectedTroopIndex)
		local heroInfo = preset and preset.Heros and preset.Heros[slot] and preset.Heros[slot].Info
		heroId = heroInfo and heroInfo.ConfigId or 0
	end
	local petId = self:GetPetId(slot)
	local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroId)
	hp = heroData and math.floor(heroData.dbData.ClimbTowerHpPercent * ModuleRefer.TroopModule:GetTroopHeroHPMax(heroId)) or 0
	return heroId, hp
end

--- 获取宠物ID
---@param self SEClimbTowerTroopMediator
---@param slot number
---@return number
function SEClimbTowerTroopMediator:GetPetId(slot)
	local preset = self:GetPreset(self._selectedTroopIndex)
	if (self._editMode) then
		return self._editPetList[slot]
	else
		local heroInfo = preset and preset.Heros and preset.Heros[slot] and preset.Heros[slot].Info
		return heroInfo and heroInfo.PetInfos and heroInfo.PetInfos[0] and heroInfo.PetInfos[0].CompId or 0
	end
end

---@param self SEClimbTowerTroopMediator
---@return table<number, boolean>
function SEClimbTowerTroopMediator:GetHeroesFromAllPresets()
	---@type table<number, boolean>
	local result = {}
	for i = 1, MAX_TROOP_COUNT do
		local preset = self:GetPreset(i)
		if (self._selectedTroopIndex == i and self._editMode) then
			for _, heroId in ipairs(self._editHeroList) do
				result[heroId] = true
			end
		elseif (preset and preset.Heros) then
			for _, hero in pairs(preset.Heros) do
				if (hero and hero.Info.ConfigId > 0) then
					result[hero.Info.ConfigId] = true
				end
			end
		end
	end
	return result
end

--- 打开英雄选择面板
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:OpenHeroSelectionPanel()
	self.heroSelectionPanelCloseButton.gameObject:SetActive(true)
	self.heroSelectionPanel:SetActive(true)
	self._heroSelectionMode = true
	self:RefreshHeroSelectionList()
end

--- 关闭英雄选择面板
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:CloseHeroSelectionPanel()
	self.heroSelectionPanelCloseButton.gameObject:SetActive(false)
	self.heroSelectionPanel:SetActive(false)
	self._heroSelectionMode = false
	self._selectedHeroSlot = 0
	self:RefreshHeroCardSelectedStatus()
end

function SEClimbTowerTroopMediator:OnHeroSelectionCloseButtonClick()
	self:CloseHeroSelectionPanel()
end

function SEClimbTowerTroopMediator:OnHeroSortSelect(id)
	self._heroSortMode = id
	self:RefreshHeroSelectionList()
end

--- 英雄选择单元格点击
---@param self SEClimbTowerTroopMediator
---@param data HeroConfigCache
function SEClimbTowerTroopMediator:OnHeroSelectionCellClick(data)
	if (not data) then return end
	if (not self._editMode) then
		self:EnterEditMode()
	end
	self._editHeroList[self._selectedHeroSlot] = data.id
	self:RefreshTroopList()
	self:SelectNextEmptyHeroSlot()
	self:RefreshHeroCardSelectedStatus()
	self:RefreshHeroSelectionList()
end

---@param self SEClimbTowerTroopMediator
---@param slotIndex number
function SEClimbTowerTroopMediator:GetHeroIdBySlot(slotIndex)
	if (self._editMode) then
		return self._editHeroList[slotIndex]
	else
		local preset = self:GetPresetData(self._selectedTroopIndex)
		return preset and preset.Heroes and preset.Heroes[slotIndex] and preset.Heroes[slotIndex].HeroCfgID
	end
end

--- 选择下一个空英雄槽位
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:SelectNextEmptyHeroSlot()
	for index = self._selectedHeroSlot + 1, MAX_HERO_COUNT do
		local heroId = self:GetHeroIdBySlot(index)
		if (not heroId or heroId <= 0) then
			self._selectedHeroSlot = index
			return
		end
	end
	for index = 1, self._selectedHeroSlot - 1 do
		local heroId = self:GetHeroIdBySlot(index)
		if (not heroId or heroId <= 0) then
			self._selectedHeroSlot = index
			return
		end
	end
end

--- 刷新英雄选择列表
---@param self SEClimbTowerTroopMediator
function SEClimbTowerTroopMediator:RefreshHeroSelectionList()
	local player = ModuleRefer.PlayerModule:GetPlayer()
	local heroList = {}
	local presetHeroes = self:GetHeroesFromAllPresets()
	for _, heroInfo in pairs(player.Hero.HeroInfos) do
		local heroCfg = ConfigRefer.Heroes:Find(heroInfo.CfgId)
		if (not presetHeroes[heroInfo.CfgId] and heroCfg:Type() == HeroType.Heros) then
			table.insert(heroList, ModuleRefer.HeroModule:GetHeroByCfgId(heroInfo.CfgId))
		end
	end
	if (self._heroSortMode == HERO_SORT_MODE_QUALITY) then
		table.sort(heroList, SEClimbTowerTroopMediator.HeroSortByQuality)
	elseif (self._heroSortMode == HERO_SORT_MODE_LEVEL) then
		table.sort(heroList, SEClimbTowerTroopMediator.HeroSortByLevel)
	end

	self.heroSelectionTable:Clear()
	for _, heroData in ipairs(heroList) do
		---@type UITroopHeroSelectionCellData
		local data = {}
		data.heroId = heroData.configCell:Id()
		data.hp = ModuleRefer.HeroModule:GetHeroClimbTowerHp(heroData.configCell:Id())
		data.petId = 0
		data.onClick = Delegate.GetOrCreate(self, self.OnHeroSelectionCellClick)
		self.heroSelectionTable:AppendData(data)
	end
	self.heroSelectionEmptyText.gameObject:SetActive(#heroList == 0)
end

--- 按品质排序英雄
---@param a HeroConfigCache
---@param b HeroConfigCache
function SEClimbTowerTroopMediator.HeroSortByQuality(a, b)
	local qualityA = a.configCell:Quality()
	local qualityB = b.configCell:Quality()
	if (qualityA ~= qualityB) then
		return qualityA > qualityB
	else
		local levelA = a.dbData.Level
		local levelB = b.dbData.Level
		if (levelA ~= levelB) then
			return levelA > levelB
		else
			local rankA = a.dbData.StarLevel
			local rankB = b.dbData.StarLevel
			if (rankA ~= rankB) then
				return rankA > rankB
			else
				return a.id < b.id
			end
		end
	end
end

--- 按等级排序英雄
---@param a HeroConfigCache
---@param b HeroConfigCache
function SEClimbTowerTroopMediator.HeroSortByLevel(a, b)
	local levelA = a.dbData.Level
	local levelB = b.dbData.Level
	if (levelA ~= levelB) then
		return levelA > levelB
	else
		local qualityA = a.configCell:Quality()
		local qualityB = b.configCell:Quality()
		if (qualityA ~= qualityB) then
			return qualityA > qualityB
		else
			local rankA = a.dbData.StarLevel
			local rankB = b.dbData.StarLevel
			if (rankA ~= rankB) then
				return rankA > rankB
			else
				return a.id < b.id
			end
		end
	end
end

---@param self SEClimbTowerTroopMediator
---@param data UITroopHeroCardData
---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function SEClimbTowerTroopMediator:OnHeroCardDragBegin(data, go, eventData)
	self._draggingHeroCard = true
	go.transform.parent:SetAsLastSibling()
end

---@param self SEClimbTowerTroopMediator
---@param data UITroopHeroCardData
---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function SEClimbTowerTroopMediator:OnHeroCardDrag(data, go, eventData)
	local uiPos = UIHelper.ScreenPos2UIPos(eventData.position)
	go.transform.parent.localPosition = uiPos
	self._selectedHeroSlot = 0
	for i = 1, MAX_HERO_COUNT do
		if (i ~= data.slotIndex and
				self._heroCardRects[i]:Contains(CS.UnityEngine.Vector2(eventData.position.x, Screen.height - eventData.position.y))) then
			self._selectedHeroSlot = i
			break
		end
	end
	self:RefreshHeroCardSelectedStatus()
end

---@param self SEClimbTowerTroopMediator
---@param data UITroopHeroCardData
---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function SEClimbTowerTroopMediator:OnHeroCardDragEnd(data, go, eventData)
	self._draggingHeroCard = false
	go.transform.parent.localPosition = self._heroCardPosList[data.slotIndex]
	if (self._selectedHeroSlot > 0 and self._selectedHeroSlot <= MAX_HERO_COUNT and self._selectedHeroSlot ~= data.slotIndex) then
		if (not self._editMode) then
			self:EnterEditMode()
		end
		local heroId = self._editHeroList[self._selectedHeroSlot]
		self._editHeroList[self._selectedHeroSlot] = data.heroCfgId
		self._editHeroList[data.slotIndex] = heroId
		local petId = self._editPetList[self._selectedHeroSlot]
		self._editPetList[self._selectedHeroSlot] = self._editPetList[data.slotIndex]
		self._editPetList[data.slotIndex] = petId
		self:RefreshSelectedTroopInfo()
		if (not self._heroSelectionMode) then
			self._selectedHeroSlot = 0
		end
		self:RefreshHeroCardSelectedStatus()
	end
end

function SEClimbTowerTroopMediator:OnButtonSaveClick()
	-- 保存
	if (not self._editMode) then return end

	self:SaveSelectedTroop(function(rsp)
		self:ExitEditMode()
		self:RefreshSelectedTroopInfo()
	end)
end

--- 编队检查是否能进本
---@param self SEClimbTowerTroopMediator
---@return boolean
function SEClimbTowerTroopMediator:TroopCheck()
	for i = 1, MAX_TROOP_COUNT do
		local preset = self:GetPreset(i)
		if (preset) then
			for _, heroInfo in pairs(preset.Heros) do
				if (heroInfo and heroInfo.Info.ConfigId and heroInfo.Info.ConfigId > 0) then
					local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroInfo.Info.ConfigId)
					if (heroData and heroData.dbData.ClimbTowerHpPercent > 0) then return true end
				end
			end
		end
	end
	return false
end

function SEClimbTowerTroopMediator:OnButtonGoClick()
	local enterScene = function()
		-- 队伍检查
		if (not self:TroopCheck()) then
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("setower_tips_troopnull"))
			return
		end

		local sectionCfg = ConfigRefer.ClimbTowerSection:Find(self._sectionId)
		if (sectionCfg) then
			-- 各种环境参数

			-- 大世界
			if (KingdomMapUtils.IsMapState()) then
				g_Game.StateMachine:WriteBlackboard("SE_FROM_TYPE", SEHudTroopMediatorDefine.FromType.World, true)
			-- 内城
			else
				g_Game.StateMachine:WriteBlackboard("SE_FROM_TYPE", SEHudTroopMediatorDefine.FromType.City, true)
			end
			g_Game.StateMachine:WriteBlackboard("SE_USE_DEFAULT_POS", true, true)

			g_Game.StateMachine:WriteBlackboard("SE_FROM_CLIMB_TOWER", sectionCfg:ChapterId(), true)
			ModuleRefer.EnterSceneModule:EnterSeClimbTowerScene(sectionCfg:MapInstanceId(), nil, self._sectionId)
			g_Game.UIManager:CloseAllByName(UIMediatorNames.SEClimbTowerMainMediator)
			self:CloseSelf()
		end
	end

	if (self._editMode) then
		self:SaveSelectedTroop(function(rsp)
			enterScene()
		end)
	else
		enterScene()
	end
end

--- 获取当前选定编队英雄列表
---@param self SEClimbTowerTroopMediator
---@return table<number, number>, number @heroList, heroCount
function SEClimbTowerTroopMediator:GetSelectedTroopHeroList()
	local result = {}
	local count = 0
	local preset = self:GetPreset(self._selectedTroopIndex)
	for i = 1, MAX_HERO_COUNT do
		local heroId
		if (self._editMode) then
			heroId = self._editHeroList[i]
		else
			heroId = preset and preset.Heros and preset.Heros[i] and preset.Heros[i].Info.ConfigId or 0
		end
		if (heroId > 0) then
			count = count + 1
		end
		result[i] = heroId
	end
	return result, count
end

--- 检查并保存选定的编队
---@param self SEClimbTowerTroopMediator
---@param sucCallback fun()
---@param content string
function SEClimbTowerTroopMediator:CheckAndSaveSelectedTroop(sucCallback, content)
	if (not self._editMode) then
		if (sucCallback) then
			sucCallback()
		end
		return
	end

	local saveAndSwitch = function()
		self:SaveSelectedTroop(function(rsp)
			self:ExitEditMode()
			if (sucCallback) then
				sucCallback()
			end
		end)
	end

	local giveUpAndSwitch = function()
		self:ExitEditMode()
		if (sucCallback) then
			sucCallback()
		end
	end

	---@type CommonConfirmPopupMediatorParameter
	local dialogParam = {}
	dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
	dialogParam.title = I18N.Get("NewFormation_SaveAlertTitle")
	dialogParam.content = I18N.Get(content)
	dialogParam.onConfirm = function(context)
		saveAndSwitch()
		return true
	end
	dialogParam.onCancel = function(context)
		giveUpAndSwitch()
		return true
	end
	g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

--- 保存选定的编队
---@param self SEClimbTowerTroopMediator
---@param sucCallback fun(rsp)
---@param failCallback fun(rsp)
function SEClimbTowerTroopMediator:SaveSelectedTroop(sucCallback, failCallback)
	local msg = require("SaveClimbTowerPresetParameter").new()
	msg.args.QueueIdx = self._selectedTroopIndex - 1
	for i = 1, MAX_HERO_COUNT do
		local heroId = self:GetHeroData(i)
		local petId = self:GetPetId(i)
		local info = wrpc.ClimbTowerHero.New(heroId)
		info.PetCompId:Add(petId)
		msg.args.HeroInfos:Add(info)
	end
	msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, rsp)
		if (suc) then
			if (sucCallback) then
				sucCallback(rsp)
			end
		else
			if (failCallback) then
				failCallback(rsp)
			end
		end
	end)
end

function SEClimbTowerTroopMediator:OnBackButtonClick()
	if (self._heroSelectionMode) then
		self:CloseHeroSelectionPanel()
		return
	end
	self:CheckAndSaveSelectedTroop(function()
		self:CloseSelf()
	end, I18N_SAVE_CHECK_EXIT)
end

function SEClimbTowerTroopMediator:TrySelectTroop(index)
	if (self._draggingHeroCard) then return end
	if (self._heroSelectionMode) then
		self:CloseHeroSelectionPanel()
		return
	end

	if (self._selectedTroopIndex == index) then return end

	self:CheckAndSaveSelectedTroop(function()
		self._selectedTroopIndex = index
		self:RefreshTroopList()
	end, I18N_SAVE_CHECK_SWITCH)
end

function SEClimbTowerTroopMediator:OnTroopButton1Click()
	self:TrySelectTroop(1)
end

function SEClimbTowerTroopMediator:OnTroopButton2Click()
	self:TrySelectTroop(2)
end

function SEClimbTowerTroopMediator:OnTroopButton3Click()
	self:TrySelectTroop(3)
end

---@param petData table<number, UIPetIconData>
function SEClimbTowerTroopMediator:PetDataPostProcess(petDataList)
	if (petDataList) then
		self._petDataList = petDataList
	end
	self._selectingPetId = self:GetPetId(self._selectedHeroSlot)
	if (not table.isNilOrZeroNums(self._petDataList)) then
		for id, data in pairs(self._petDataList) do
			data.selected = (id == self._selectingPetId)
			data.onClick = Delegate.GetOrCreate(self, self.OnSelectPet)
		end
	end
end

---@param self UIPetRankUpMediator
---@param petData UIPetIconData
---@return boolean
function SEClimbTowerTroopMediator:PetDataFilter(petData)
	if (not petData) then return false end

	-- 过滤宠物
	if (not self:FilterPet(petData.id)) then
		return false
	end

	return true
end

--- 过滤宠物
---@param self SEClimbTowerTroopMediator
---@param petId number
---@return boolean
function SEClimbTowerTroopMediator:FilterPet(petId)
	local selectedPetId = self:GetPetId(self._selectedHeroSlot)

	if (petId == selectedPetId) then return true end
	local petInfo = ModuleRefer.PetModule:GetPetByID(petId)
	if (not petInfo) then return false end

	local petList = {}
	local petTypeList = {}
	for i = 1, MAX_TROOP_COUNT do
		local preset = self:GetPreset(i)
		for j = 1, MAX_HERO_COUNT do
			if (i == self._selectedTroopIndex and j == self._selectedHeroSlot) then goto continue end
			local cpid
			if (self._editMode and i == self._selectedTroopIndex) then
				cpid = self._editPetList[j] or 0
			else
				cpid = preset and preset.Heros and preset.Heros[j] and preset.Heros[j].Info.PetInfos and preset.Heros[j].Info.PetInfos[0] and preset.Heros[j].Info.PetInfos[0].CompId or 0
			end
			if (cpid > 0) then
				local cpInfo = ModuleRefer.PetModule:GetPetByID(cpid)
				if (cpInfo) then
					if (i == self._selectedTroopIndex) then
						petTypeList[cpInfo.Type] = true
					else
						petList[cpid] = true
					end
				end
			end
			::continue::
		end
	end

	return not petList[petId] and not petTypeList[petInfo.Type]
end

---@param self SEClimbTowerTroopMediator
---@param data UIPetIconData
function SEClimbTowerTroopMediator:OnSelectPet(data)
	if (not data) then return end
	if (data.id == self._selectingPetId) then return end
	if (not self._editMode) then
		self:EnterEditMode()
	end
	local selectedData = self.petSelection:GetPetData(self._selectingPetId)
	if (selectedData) then
		selectedData.selected = false
	end
	data.selected = true
	self._selectingPetId = data.id
	self._editPetList[self._selectedHeroSlot] = data.id
	self:RefreshSelectedTroopInfo()
	self.petSelection:RefreshPetTable()
end

function SEClimbTowerTroopMediator:OnAutoSetButtonClick()
	if (self._noAutoSet == 1) then
		self._noAutoSet = 0
		self:DoAutoSet()
	else
		self._noAutoSet = 1
	end
	g_Game.PlayerPrefsEx:SetIntByUid(PREF_KEY_NO_AUTO_SET, self._noAutoSet)
	self.autoSetStatusRecord:ApplyStatusRecord(1 - self._noAutoSet)
end

function SEClimbTowerTroopMediator:SetToNoAutoSet()
	self._noAutoSet = 1
	g_Game.PlayerPrefsEx:SetIntByUid(PREF_KEY_NO_AUTO_SET, self._noAutoSet)
	self.autoSetStatusRecord:ApplyStatusRecord(1 - self._noAutoSet)
end

function SEClimbTowerTroopMediator:DoAutoSet()
	local castle = ModuleRefer.PlayerModule:GetCastle()
	local preset = castle.TroopPresets.Presets[1]

	for i = 1, MAX_HERO_COUNT do
		self._editHeroList[i] = preset and preset.Heroes and preset.Heroes[i] and preset.Heroes[i].HeroCfgID or 0
		self._editPetList[i] = 0
		if (self._editHeroList[i] > 0) then
			local petId = ModuleRefer.HeroModule:GetHeroLinkPet(self._editHeroList[i])
			if (petId and petId > 0) then
				self._editPetList[i] = petId
			end
		end
	end

	self._editMode = true
	self:SaveSelectedTroop(function(rsp)
		self:ExitEditMode()
		self:RefreshSelectedTroopInfo()
	end, function(rsp)
		self:RefreshSelectedTroopInfo()
	end)
end

return SEClimbTowerTroopMediator
