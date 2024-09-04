--- scene: scene_slg_troop_new

local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local TroopEditManager = require('TroopEditManager')
local Delegate = require('Delegate')
local UI3DViewConst = require('UI3DViewConst')
local UI3DTroopModelViewHelper = require('UI3DTroopModelViewHelper')
local I18N = require('I18N')
local TroopEditTips = require('TroopEditTips')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
local UIMediatorNames = require('UIMediatorNames')
local HUDTroopUtils = require('HUDTroopUtils')
local RecoverPresetHpParameter = require("RecoverPresetHpParameter")
local TimerUtility = require('TimerUtility')
local TroopAnimator = require('TroopAnimator')
local Utils = require('Utils')
local TipsLevel = TroopEditTips.TipsLevel
local KingdomMapUtils = require('KingdomMapUtils')

---@class UITroopMediator : BaseUIMediator
local UITroopMediator = class('UITroopMediator', BaseUIMediator)

---@class UITroopMediatorParam
---@field selectedTroopIndex number

local MAX_TROOP_COUNT = ConfigRefer.ConstMain:TroopPresetMaxCount()
local CellTransDuration = 0.2

function UITroopMediator:ctor()
	self.toggleHeroListShow = true
	self.togglePetListShow = false

	self.heroListDirty = false
	self.petListDirty = false

	self.oriTipsPos = nil
end

function UITroopMediator:OnCreate()
	MAX_TROOP_COUNT = ConfigRefer.ConstMain.FormationUnlockNum and ConfigRefer.ConstMain:FormationUnlockNum() or MAX_TROOP_COUNT
	self:InitObjects()
	---@type TroopEditManager
	self.troopEditManager = TroopEditManager.new()

	self:PreloadUI3DView()
end

function UITroopMediator:InitObjects()
	---@see CommonBackButtonComponent
	self.backButton = self:LuaObject("child_common_btn_back")

	--- 战力, 为0时不显示
	self.goPower = self:GameObject("p_btn_attribute_3")
	self.textPower = self:Text("p_text_num_3")
	self.textTroopIndex = self:Text("p_text_troop_number")
	self.btnDetail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnDetailBtnClick))

	--- 中央显示英雄宠物属性的部分
	---@see UITroopHeroCardGroup
	self.luaGroupCenter = self:LuaObject("p_group_center")

	--- 侧边编队栏
	self.tableTroops = self:TableViewPro("p_table_tab")

	--- 底部英雄宠物选择栏

	-- 编队提示
	self.goHint = self:GameObject("p_hint")
	self.textHint = self:Text("p_text_hint")
	self.rectTextHint = self:RectTransform("p_text_hint")
	self.goTipsIconError = self:GameObject("p_icon_1")
	self.goTipsIconWarning = self:GameObject("p_icon_2")
	self.goTipsIconInfo = self:GameObject("p_icon_3")

	-- buff按钮
	self.btnBuff = self:Button("p_btn_buff", Delegate.GetOrCreate(self, self.OnBuffButtonClick))
	self.textBuffValue = self:Text("p_text_buff_num")

	-- 切换tabs
	self.btnTabHero = self:Button("p_btn_tab_hero", Delegate.GetOrCreate(self, self.OnTabHeroClick))
	self.goHintTabHero = self:GameObject("p_hint_hero")
	self.textHintTabHero = self:Text("p_text_hint_hero", "team_tab_tip")
	self.statusCtrlerTabHero = self:StatusRecordParent("p_btn_tab_hero")
	self.tableHeroes = self:TableViewPro("p_table_hero")

	self.btnTabPet = self:Button("p_btn_tab_pet", Delegate.GetOrCreate(self, self.OnTabPetClick))
	self.goHintTabPet = self:GameObject("p_hint_pet")
	self.textHintTabPet = self:Text("p_text_hint_pet", "team_tab_tip")
	self.statusCtrlerTabPet = self:StatusRecordParent("p_btn_tab_pet")
	self.tablePets = self:TableViewPro("p_table_pet")

	-- 筛选
	self.btnFilterOpen = self:Button("p_btn_style", Delegate.GetOrCreate(self, self.OnFilterOpenClick))
	self.btnFilterClose = self:Button("p_btn_fiter", Delegate.GetOrCreate(self, self.OnFilterCloseClick))
	self.goGroupFilters = self:GameObject("p_style_group")
	self.btnFilterAll = self:Button("p_btn_all_style", Delegate.GetOrCreate(self, self.OnStyleFilterClick))
	self.textFilterAll = self:Text("p_text_all_style", "troop_select_all")
	self.statusCtrlerFilterAll = self:StatusRecordParent("p_btn_all_style")
	self.luaFilterStyle1 = self:LuaObject("p_btn_style_1")
	self.luaFilterStyle2 = self:LuaObject("p_btn_style_2")
	self.luaFilterStyle3 = self:LuaObject("p_btn_style_3")

	self.goCurFilter = self:GameObject("p_style")
	self.imgCurFilter = self:Image("p_icon_style")

	self.filters = {self.luaFilterStyle1, self.luaFilterStyle2, self.luaFilterStyle3}

	self.vxTrigger = self:AnimTrigger("p_trigger")

	self.oriTipsPos = self.rectTextHint.localPosition
end

---@param param UITroopMediatorParam
function UITroopMediator:OnShow(param)

	---@type TroopAnimator
	self.animator = TroopAnimator.new(self)

	if not param then
		param = {}
		param.selectedTroopIndex = 1
	end

	self.entryPresetIndex = param.selectedTroopIndex

	g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, false)
	self.troopEditManager:Init()
	self.troopEditManager:AddOnTroopEditChange(Delegate.GetOrCreate(self, self.OnTroopEditChange))
	self.troopEditManager:UpdateTroopFromPreset(param.selectedTroopIndex)

	g_Game.EventManager:AddListener(EventConst.ON_TROOP_CLICK_EMPTY, Delegate.GetOrCreate(self, self.OnEmptyClick))
	g_Game.EventManager:AddListener(EventConst.TROOP_HINT_TOGGLED, Delegate.GetOrCreate(self, self.UpdateTips))
	g_Game.EventManager:AddListener(EventConst.ON_TROOP_MEDIATOR_ADD_HP, Delegate.GetOrCreate(self, self.OnAddHp))

	g_Game.EventManager:AddListener(EventConst.ON_TROOP_SLOT_DRAG_MOVE_IN, Delegate.GetOrCreate(self, self.OnTroopSlotDragMoveIn))
	g_Game.EventManager:AddListener(EventConst.ON_TROOP_SLOT_DRAG_MOVE_OUT, Delegate.GetOrCreate(self, self.OnTroopSlotDragMoveOut))
	g_Game.EventManager:AddListener(EventConst.ON_TROOP_SLOT_CLICK, Delegate.GetOrCreate(self, self.OnTroopSlotClick))

	g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.UpdateTroopCellStatus))

	-- g_Game.ServiceManager:AddResponseCallback(RecoverPresetHpParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRecoveryHpResponse))
	self:InitUI()

	KingdomMapUtils.SetGlobalCityMapParamsId(false)
end

function UITroopMediator:OnHide(param)
	self.troopEditManager:RemoveOnTroopEditChange(Delegate.GetOrCreate(self, self.OnTroopEditChange))
	self.troopEditManager:Release()
	g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, true)

	g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_CLICK_EMPTY, Delegate.GetOrCreate(self, self.OnEmptyClick))
	g_Game.EventManager:RemoveListener(EventConst.TROOP_HINT_TOGGLED, Delegate.GetOrCreate(self, self.UpdateTips))
	g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_MEDIATOR_ADD_HP, Delegate.GetOrCreate(self, self.OnAddHp))

	g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_SLOT_DRAG_MOVE_IN, Delegate.GetOrCreate(self, self.OnTroopSlotDragMoveIn))
	g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_SLOT_DRAG_MOVE_OUT, Delegate.GetOrCreate(self, self.OnTroopSlotDragMoveOut))
	g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_SLOT_CLICK, Delegate.GetOrCreate(self, self.OnTroopSlotClick))

	g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.UpdateTroopCellStatus))

	-- g_Game.ServiceManager:RemoveResponseCallback(RecoverPresetHpParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRecoveryHpResponse))

	self.animator:Release()
	if self.textHintTimer then
		self.textHintTimer:Stop()
		self.textHintTimer = nil
	end

	KingdomMapUtils.SetGlobalCityMapParamsId(KingdomMapUtils.IsMapState())
end

function UITroopMediator:OnClose(param)
	ModuleRefer.TroopModule:RefreshRedDotStatus()
	g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
	self.animator:Release()

	if self.textHintTimer then
		self.textHintTimer:Stop()
		self.textHintTimer = nil
	end
end

function UITroopMediator:OnCmdClose()
	self:CloseSelf()
end

function UITroopMediator:OnBackBtnClick()
	if self.troopEditManager:IsTroopChanged() then
		self.troopEditManager:SaveTroop(Delegate.GetOrCreate(self, self.OnExitSaveCallback))
	else
		self:CloseSelf()
	end
end

---@param saveSucc boolean
---@param allowContinue boolean
function UITroopMediator:OnExitSaveCallback(saveSucc, allowContinue)
	if saveSucc or allowContinue then
		self:CloseSelf()
	end
end

function UITroopMediator:OnTroopEditChange(clearList)
	self:UpdateTitle()
	self:UpdatePower()
	self:UpdateGroupCenter()
	self:UpdateBuff()
	self:UpdateTips()
	self:UpdateCurFilterIcon()
	if self.toggleHeroListShow then
		if clearList then
			self:InitHeroList()
		else
			self:UpdateHeroList()
		end
	else
		self.heroListDirty = true
	end

	if self.togglePetListShow then
		if clearList then
			self:InitPetList()
		else
			self:UpdatePetList()
		end
	else
		self.petListDirty = true
	end

	self:UpdateTroopsList()
	self:RefreshUI3DView()

	local hasAvaliableHero = self.troopEditManager:HasAvaliableHero()
	local hasAvaliableHeroSlot = self.troopEditManager:HasAvaliableHeroSlot()
	local hasAvaliablePet = self.troopEditManager:HasAvaliablePet()
	local hasHeroWithoutPet = self.troopEditManager:HasHeroWithoutPet()
	local hasAvaliablePetSlot = self.troopEditManager:HasAvaliablePetSlot()
	self.goHintTabHero:SetActive(hasAvaliableHero and hasAvaliableHeroSlot)
	self.goHintTabPet:SetActive(hasAvaliablePet and hasHeroWithoutPet and hasAvaliablePetSlot)
end

function UITroopMediator:InitUI()
	self:ToggleHeroList(true)
	self:TogglePetList(false)

	self:UpdateFilters()
	self:InitHeroList()
	self:InitPetList()

	local teamNames = {
		'name_team01',
		'name_team02',
		'name_team03',
	}
	---@type CommonBackButtonData
	local buttonData = {}
	buttonData.title = I18N.Get(teamNames[self.entryPresetIndex])
	buttonData.onClose = Delegate.GetOrCreate(self, self.OnBackBtnClick)
	self.backButton:FeedData(buttonData)
end

function UITroopMediator:UpdateTitle()
	local teamNames = {
		'name_team01',
		'name_team02',
		'name_team03',
	}
	self.backButton:UpdateTitle(I18N.Get(teamNames[self.troopEditManager:GetCurPresetIndex()]))
end

function UITroopMediator:UpdateTroopsList()
	self.tableTroops:Clear()
	local _, maxCount, presets = ModuleRefer.TroopModule:GetPresetData()
	---@type number, wds.TroopPreset
	for i = 1, 3 do
		local preset = presets.Presets[i]
		---@type UITroopCellData
		local data = {}
		data.index = i
		data.onClick = Delegate.GetOrCreate(self, self.OnTroopCellClick)
		data.selected = i == self.troopEditManager:GetCurPresetIndex()
		if data.selected then
			data.redDot = nil
		else
			data.redDot = ModuleRefer.TroopModule:GetRedDotUITeam(i)
		end
		data.bindRedDot = not data.selected
		data.isLocked = i > maxCount
		if not preset then
			data.isEmpty = true
		else
			data.isEmpty = ModuleRefer.TroopModule:GetTroopLeadHeroId(i) <= 0
			data.leaderHeroId = ModuleRefer.TroopModule:GetTroopLeadHeroId(i)
			data.troopPreset = preset
		end
		data.manager = self.troopEditManager
		self.tableTroops:AppendData(data)
	end
end

function UITroopMediator:UpdatePower()
	local power = self.troopEditManager:GetTroopPower()
	self.animator:PlayPowerChangeAnimation(power)
	self.goPower:SetActive(power > 0)
	self.textTroopIndex.text = self.troopEditManager:GetCurPresetIndex()
end

function UITroopMediator:UpdateGroupCenter()
	---@type UITroopHeroCardGroupData
	local data = {}
	local heroSlots = {}
	local petSlots = {}
	for i = 1, MAX_TROOP_COUNT do
		local heroSlot, petSlot = self.troopEditManager:GetSlot(i)
		heroSlots[i] = heroSlot
		petSlots[i] = petSlot
	end
	data.heroSlots = heroSlots
	data.petSlots = petSlots
	self.luaGroupCenter:FeedData(data)
end

function UITroopMediator:UpdateCurFilterIcon()
	local filterId = self.troopEditManager:GetStyleFilter() or 0
	if filterId == 0 then
		self.goCurFilter:SetActive(false)
	else
		self.goCurFilter:SetActive(true)
		self:LoadSprite(ConfigRefer.AssociatedTag:Find(filterId):Icon(), self.imgCurFilter)
	end
end

function UITroopMediator:InitHeroList()
	self.tableHeroes:Clear()
	local heroCellDatas = self.troopEditManager:GetHeroCellDatas()
	for _, cellData in ipairs(heroCellDatas) do
		self.tableHeroes:AppendData(cellData)
	end
end

function UITroopMediator:UpdateHeroList()
	local heroCellDatas = self.troopEditManager:GetHeroCellDatas()
	for _, cellData in ipairs(heroCellDatas) do
		self.tableHeroes:UpdateData(cellData)
	end
end

function UITroopMediator:InitPetList()
	self.tablePets:Clear()
	local petCellDatas = self.troopEditManager:GetPetCellDatas()
	for _, cellData in ipairs(petCellDatas) do
		self.tablePets:AppendData(cellData)
	end
end

function UITroopMediator:UpdatePetList()
	local petCellDatas = self.troopEditManager:GetPetCellDatas()
	for _, cellData in ipairs(petCellDatas) do
		self.tablePets:UpdateData(cellData)
	end
end

function UITroopMediator:UpdateBuff()
	local values = self.troopEditManager:GetTroopBuffValues()
	local value
	if table.nums(values) == 0 then
		value = 0
	else
		for _, v in pairs(values) do
			value = v
			break
		end
	end
	self.textBuffValue.text = "+" .. (value * 100) .. "%"
	self.animator:PlayBuffValueChangeAnimation(value)
end

function UITroopMediator:UpdateTips()
	if g_Game.PlayerPrefsEx:GetIntByUid('troop_relation_tips_toggle', 1) == 0 then
		self.goHint:SetActive(false)
		return
	end
	local tips, level = self.troopEditManager:GetTroopTip()
	if not tips then
		self.goHint:SetActive(false)
	else
		self.goHint:SetActive(true)
	end
	self.textHint.text = tips
	self.goTipsIconError:SetActive(level == TipsLevel.Error)
	self.goTipsIconWarning:SetActive(level == TipsLevel.Warning)
	self.goTipsIconInfo:SetActive(level == TipsLevel.Info)

	self.rectTextHint.localPosition = self.oriTipsPos
	self.textHint.transform:DOKill()

	self.textHintTimer = TimerUtility.DelayExecuteInFrame(function ()
		if Utils.IsNull(self.textHint) then
			return
		end
		if self.textHint.preferredWidth > self.rectTextHint.rect.width then
			self.textHint.transform:DOLocalMoveX(self.rectTextHint.rect.width - self.textHint.preferredWidth - 100, 3):SetLoops(-1, CS.DG.Tweening.LoopType.Restart)
		end
	end, 5)
end

function UITroopMediator:UpdateFilters()
	for i = 1, #self.filters do
		local filter = self.filters[i]
		---@type UIPetFilterCompData
		local data = {}
		data.index = i
		data.onClick = Delegate.GetOrCreate(self, self.OnStyleFilterClick)
		filter:FeedData(data)
	end

	self:OnStyleFilterClick(0)
end

function UITroopMediator:OnBuffButtonClick()
	local tiesId = 0
	local buffId = self.troopEditManager:GetTroopBuffId()
	if buffId > 0 then
		tiesId = ConfigRefer.TagTiesElement:Find(buffId):Ties()
	end
	---@type UITroopRelationTipsMediatorParam
	local data = {}
	data.tiesId = tiesId
	data.tags2Num = self.troopEditManager:GetTroopTagNums()
	g_Game.UIManager:Open(UIMediatorNames.UITroopRelationTipsMediator, data)
end

function UITroopMediator:OnTabHeroClick()
	self:ToggleHeroList(true)
	self:TogglePetList(false)
end

function UITroopMediator:OnTabPetClick()
	self:ToggleHeroList(false)
	self:TogglePetList(true)
end

function UITroopMediator:OnFilterOpenClick()
	self.goGroupFilters:SetActive(true)
end

function UITroopMediator:OnFilterCloseClick()
	self.goGroupFilters:SetActive(false)
end

function UITroopMediator:ToggleHeroList(show)
	self.toggleHeroListShow = show
	self.tableHeroes.gameObject:SetActive(show)
	if show then
		self.statusCtrlerTabHero:ApplyStatusRecord(1)
		if self.heroListDirty then
			self:InitHeroList()
			self.heroListDirty = false
		end
	else
		self.statusCtrlerTabHero:ApplyStatusRecord(0)
	end
end

function UITroopMediator:TogglePetList(show)
	self.togglePetListShow = show
	self.tablePets.gameObject:SetActive(show)
	if show then
		self.statusCtrlerTabPet:ApplyStatusRecord(1)
		if self.petListDirty then
			self:InitPetList()
			self.petListDirty = false
		end
	else
		self.statusCtrlerTabPet:ApplyStatusRecord(0)
	end
end

function UITroopMediator:OnTroopCellClick(index)
	self.toPresetIndex = index
	if self.troopEditManager:GetCurPresetIndex() == index then
		return
	end
	self.animator:KillTween()
	local _, maxCount, _ = ModuleRefer.TroopModule:GetPresetData()
	if index > maxCount then
		local index2FurName = {
			'furniture_main_13',
			'furniture_main_17',
			'furniture_main_21',
		}
		ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams('toast_unlock_furniture_flag', I18N.Get(index2FurName[index])))
		return
	end
	if self.troopEditManager:IsTroopChanged() then
		self.troopEditManager:SaveTroop(Delegate.GetOrCreate(self, self.OnSwitchSaveCallBack))
	else
		self.troopEditManager:UpdateTroopFromPreset(index)
	end
end

function UITroopMediator:OnSwitchSaveCallBack(saveSucc, allowContinue)
	if saveSucc or allowContinue then
		self.troopEditManager:UpdateTroopFromPreset(self.toPresetIndex)
	end
end

function UITroopMediator:OnStyleFilterClick(index)
	if not index then
		index = 0
	end
	local styles = {}
	for id, _ in ConfigRefer.AssociatedTag:ipairs() do
		table.insert(styles, id)
	end
	for i, filter in ipairs(self.filters) do
		filter:IsSelect(index == i or index == 0)
	end
	self.statusCtrlerFilterAll:ApplyStatusRecord(index == 0 and 1 or 0)
	self.troopEditManager:SetStyleFilter(styles[index] or 0)

	if self.toggleHeroListShow then
		self:InitHeroList()
	else
		self.heroListDirty = true
	end

	if self.togglePetListShow then
		self:InitPetList()
	else
		self.petListDirty = true
	end

	self:OnFilterCloseClick()
	self:UpdateCurFilterIcon()
end

function UITroopMediator:OnEmptyClick()
	self:OnFilterCloseClick()
	g_Game.UIManager:CloseAllByName(UIMediatorNames.UITroopPetCellDetailMediator)
end

function UITroopMediator:OnDetailBtnClick()
	---@type CommonPlainTextInfoParam
	local data = {}
	data.title = I18N.Get('bw_village_breakingice_rule')
	data.tabs = {}
	data.contents = {{list = {{rule = I18N.Get('team_rule')}}}}
	data.startTab = 1
	g_Game.UIManager:Open(UIMediatorNames.CommonPlainTextInfoMediator, data)
end

function UITroopMediator:OnRecoveryHpResponse()
	self.troopEditManager:UpdateTroopFromPreset(self.troopEditManager:GetCurPresetIndex())
end

---@param clickTransform CS.UnityEngine.Transform
function UITroopMediator:OnAddHp(clickTransform)
	local targetTransforms = {}
	for _, unit in ipairs(self.troopEditManager:GetTroopCanHealUnits()) do
		table.insert(targetTransforms, unit:GetUIGameObject().transform)
	end
	self.animator:PlayAddHpAnimation(clickTransform, targetTransforms)
end

-- 3dUI相关，下版本重构

function UITroopMediator:PreloadUI3DView()
	self:SetAsyncLoadFlag()
	---@type UI3DViewerParam
	local data = {}
	data.envPath = "mdl_ui3d_normalTroopbackground1"
	data.callback = function(viewer)
		self:RemoveAsyncLoadFlag()
	end
	data.type = UI3DViewConst.TroopViewType.SingleTroop
	g_Game.UIManager:SetupUI3DView(
		self:GetRuntimeId(),UI3DViewConst.ViewType.TroopViewer,
		data
	)
end

function UITroopMediator:RefreshUI3DView(playVfx)
	---@type UI3DViewerParam
	local data = {}
	data.envPath = "mdl_ui3d_normalTroopbackground1"

	data.preCallback = function() end

	data.callback = function(viewer)
		if viewer == nil then
            return
        end
		self:SetupUI3DView(viewer , self.isDraging and CellTransDuration or 0,playVfx)
	end
	data.type = UI3DViewConst.TroopViewType.SingleTroop
	g_Game.UIManager:SetupUI3DView(
		self:GetRuntimeId(),UI3DViewConst.ViewType.TroopViewer,
		data
	)

	self.ui3dView:UnloadSlotHoldingVfx()
end

---@param viewer UI3DTroopModelView
function UITroopMediator:SetupUI3DView(viewer,animDuration,playVfx)
	---@type UI3DTroopModelView
	self.ui3dView = viewer
	self.troopEditManager:SetView(viewer)
	self.ui3dView:EnableVirtualCameraOffset(true)

	self.ui3dView:OnStartLoadUnit()
	local heroIds = {}
	local petIds = {}
	local heroHps = {}
	local petHps = {}

	for i = 1, 3 do
		local heroSlot, petSlot = self.troopEditManager:GetSlot(i)
		if heroSlot:IsEmpty() then
			heroIds[i] = 0
			heroHps[i] = false
		else
			heroIds[i] = heroSlot:GetUnit():GetId()
			heroHps[i] = not heroSlot:GetUnit():IsInjured()
		end

		if petSlot:IsEmpty() then
			petIds[i] = 0
			petHps[i] = false
		else
			petIds[i] = petSlot:GetUnit():GetCfgId()
			petHps[i] = not petSlot:GetUnit():IsInjured()
		end
	end

	local data = UI3DTroopModelViewHelper.CreateTroopViewData(heroIds,petIds,heroHps,petHps)
	self.ui3dView:SetupHeros_S(data)
	self.ui3dView:SetupPets_S(data)
	self.ui3dView:LoadFlagModel(self.troopEditManager:GetCurPresetIndex())
	self.ui3dView:PlayChangePosSequence(data,1,animDuration,playVfx,nil)
end

function UITroopMediator:GetShowCameraSetting()
	local cameraSetting = {}
    for i = 1, 2 do
        local singleSetting = {}
        singleSetting.fov = ConfigRefer.ConstMain:HeroEuipShowMoveFOV(i)
        singleSetting.nearCp = ConfigRefer.ConstMain:HeroEuipShowMoveNCP(i)
        singleSetting.farCp = ConfigRefer.ConstMain:HeroEuipShowMoveFCP(i)
        if i == 1 then
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipShowCameraMove(1), ConfigRefer.ConstMain:HeroEuipShowCameraMove(2), ConfigRefer.ConstMain:HeroEuipShowCameraMove(3))
        else
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipShowCameraMove(4), ConfigRefer.ConstMain:HeroEuipShowCameraMove(5), ConfigRefer.ConstMain:HeroEuipShowCameraMove(6))
        end
        cameraSetting[i] = singleSetting
    end
    return cameraSetting
end

function UITroopMediator:OnTroopSlotDragMoveIn(slotIndex, slotType)
	if self.troopEditManager:GetCurDraggingIndex() == slotIndex then
		return
	end

	if self.troopEditManager:GetCurDraggingType() ~= slotType then
		return
	end

	if self.troopEditManager:GetSlotByType(slotIndex, slotType):IsLocked() then
		return
	end

	self.ui3dView:LoadSlotHoldingVfx(slotIndex, slotType)
end

function UITroopMediator:OnTroopSlotDragMoveOut(slotIndex, slotType)
	self.ui3dView:UnloadSlotHoldingVfx()
end

function UITroopMediator:OnTroopSlotClick(slotIndex, slotType)
	local slot = self.troopEditManager:GetSlotByType(slotIndex, slotType)
	if slot:IsLocked() then
		ModuleRefer.ToastModule:AddSimpleToast(slot:GetUnlockCondStr())
	end
end

function UITroopMediator:UpdateTroopCellStatus()
	for i = 0, MAX_TROOP_COUNT do
		local cell = self.tableTroops:GetCell(i)
		if cell then
			cell.Lua:RefreshData()
		end
	end
end


return UITroopMediator