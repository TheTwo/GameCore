local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local HeroType = require("HeroType")
local UIHelper = require("UIHelper")
local UIMediatorNames = require('UIMediatorNames')
local CommonChoosePopupDefine = require('CommonChoosePopupDefine')
local CommonChooseHelper = require('CommonChooseHelper')
local HeroQuality = require('HeroQuality')
local ArtResourceUtils = require('ArtResourceUtils')
local HeroListSorters = require('HeroListSorters')
---@class UITroopHeroSelectButtonParam
---@field buttonText string
---@field buttonEnabled boolean
---@field onClick fun()

---@class UITroopHeroSelectComponnetParam
---@field simpleMode boolean
---@field heroSortMode number
---@field customSorter fun(a: HeroConfigCache, b: HeroConfigCache):boolean
---@field selectedHeroIds number[]
---@field disableHeroIds number[]
---@field maxHpAddPct table<number,number>
---@field onHeroSelected fun(heroConfigId: number, selectionType: number)
---@field onHeroDragBegin fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)
---@field onHeroDrag fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)
---@field onHeroDragEnd fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)

---@class UITroopHeroSelectButtonParam
---@field btnParam_go UITroopHeroSelectButtonParam
---@field btnParam_attack UITroopHeroSelectButtonParam
---@field btnParam_save UITroopHeroSelectButtonParam

---@class UITroopHeroSelectComponnet : BaseUIComponent
local UITroopHeroSelectComponnet = class('UITroopHeroSelectComponnet', BaseUIComponent)

UITroopHeroSelectComponnet.SelectionType = {
    Normal = 1,
    Selected = 2,
    Disable = 3,
}

UITroopHeroSelectComponnet.SortMode = {
	Custom = -1,
	Default = 1,
	Quality = 2,
	Level = 3,
	StarLevel = 4,
}

UITroopHeroSelectComponnet.SortModeText = {
	[1] = 'hero_btn_default_sort',
	[2] = 'troop_select_quality',
	[3] = 'troop_select_level',
	[4] = 'troop_select_strength',
}


local MAX_HERO_COUNT = ConfigRefer.ConstMain:TroopPresetMaxHeroCount()

function UITroopHeroSelectComponnet:ctor()
	self.curFilterState = {}
end

function UITroopHeroSelectComponnet:OnCreate()
	self.heroSelectionTable = self:TableViewPro("p_table_hero")
    self.heroSelectionEmptyText = self:Text("p_text_empty_hero", "NewFormation_NoMoreHeroesToUse")
	---@type BistateButton
	self.btnAutoSelect = self:LuaObject("p_btn_go")
	self.txtBtnGo = self:Text("p_text")
	---@type BistateButton
	self.btnAttack = self:LuaObject("p_btn_attack")
	---@type BistateButton
	self.btnSave = self:LuaObject("p_btn_save")

	self.btnFilter = self:Button("p_btn_filter", Delegate.GetOrCreate(self, self.OnBtnFilterClick))
	self.goFilterIcon_Normal = self:GameObject('p_filter_n')
	self.goFilterIcon_Select = self:GameObject('p_filter_select')

	self.btnAllStyle = self:Button("p_btn_all_style", Delegate.GetOrCreate(self, self.OnBtnAllStyleClick))
	self.textBtnAllStyle = self:Text("p_text_all_style", "troop_select_all")
	self.statusCtrlBtnAllStyle = self:StatusRecordParent("p_btn_all_style")
	---@see UIPetFilterComp
	self.luaTemplateBtnStyle = self:LuaBaseComponent("p_btn_style")
	--- type UIPetFilterComp[]
	self.luaTagFilters = {}

	---@see CommonDropDown
	self.luaDropDown = self:LuaObject("child_dropdown")
end

---@param param UITroopHeroSelectComponnetParam
function UITroopHeroSelectComponnet:OnFeedData(param)
	self.param = param
    self._onHeroSelected = param.onHeroSelected
	self._onHeroDragBegin = param.onHeroDragBegin
	self._onHeroDrag = param.onHeroDrag
	self._onHeroDragEnd = param.onHeroDragEnd
    self._selectedHeroIds = {}
	if param.selectedHeroIds then
		for key, value in pairs(param.selectedHeroIds) do
			self._selectedHeroIds[key] = value
		end
	end

    self._disableHeroIds = {}
	if param.disableHeroIds then
		for key, value in pairs(param.disableHeroIds) do
			self._disableHeroIds[key] = value
		end
	end

	self._heroMaxHpAddPct = {}
	if param.maxHpAddPct then
		for key, value in pairs(param.maxHpAddPct) do
			self._heroMaxHpAddPct[key] = value
		end
	end

	self:InitTagFilter()
	self:InitSortTypeDropDown()
	self:OnBtnAllStyleClick()
    self:RefreshHeroSelectionList(param)
end

function UITroopHeroSelectComponnet:InitTagFilter()
	self.curFilterState[CommonChoosePopupDefine.FilterType.HeroAssociatedTag] = {}
	if not table.isNilOrZeroNums(self.luaTagFilters) then
		for _, comp in ipairs(self.luaTagFilters) do
			UIHelper.DeleteUIComponent(comp)
			self.luaTagFilters = {}
		end
	end
	self.luaTemplateBtnStyle:SetVisible(true)
	for i, tag in ConfigRefer.AssociatedTag:ipairs() do
		if not tag:IsHero() then goto continue end
		local comp = UIHelper.DuplicateUIComponent(self.luaTemplateBtnStyle)
		table.insert(self.luaTagFilters, comp)
		self.curFilterState[CommonChoosePopupDefine.FilterType.HeroAssociatedTag][tag:TagInfo()] = true
		local iconId = tag:Icon()
		local artResource = ConfigRefer.ArtResourceUI:Find(iconId)
		local iconPath = ""
		if artResource then
			iconPath = artResource:Path()
		end
		---@type UIPetFilterCompData
		local data = {}
		data.index = i
		data.icon = iconPath
		data.onClick = function(index)
			if self.luaTagFilters[index].Lua:IsSelect() then return end
			self:OnBtnStyleClick(tag:TagInfo())
			for j, filter in ipairs(self.luaTagFilters) do
				filter.Lua:IsSelect(j == index)
			end
		end
		comp:FeedData(data)
		comp.Lua:IsSelect(false)
		::continue::
	end
	self.luaTemplateBtnStyle:SetVisible(false)
end

function UITroopHeroSelectComponnet:InitSortTypeDropDown()
	---@type CommonDropDownData
	local dropDownData = {}
	---@type CommonDropDownItemData[]
	local items = {}
	local sortModes = {}
	for _, v in pairs(UITroopHeroSelectComponnet.SortMode) do
		if v >= 0 then
			table.insert(sortModes, v)
		end
	end
	table.sort(sortModes)
	for _, v in ipairs(sortModes) do
		---@type CommonDropDownItemData
		local item = {}
		item.id = v
		item.showText = UITroopHeroSelectComponnet.SortModeText[v]
		table.insert(items, item)
	end
	dropDownData.items = items
	dropDownData.defaultId = UITroopHeroSelectComponnet.SortMode.Default
	dropDownData.onSelect = function(id)
		self:OnSortTypeDropDownSelect(id)
	end
	dropDownData.autoFlip = true
	self.luaDropDown:FeedData(dropDownData)
end

function UITroopHeroSelectComponnet:OnSortTypeDropDownSelect(id)
	self.param.heroSortMode = id
	self:RefreshHeroSelectionList(self.param)
end

--- 刷新英雄选择列表
---@param param UITroopHeroSelectComponnetParam
function UITroopHeroSelectComponnet:RefreshHeroSelectionList(param)
	local player = ModuleRefer.PlayerModule:GetPlayer()
	local selectedHeroes = {}
	local disableHeroes = {}
	local idleHeroes = {}

	for _, heroInfo in pairs(player.Hero.HeroInfos) do
		local heroData = (heroInfo and heroInfo.CfgId) and ModuleRefer.HeroModule:GetHeroByCfgId(heroInfo.CfgId) or nil
		if heroData and heroData.dbData and heroData.configCell then
			if (heroData.configCell:Type() == HeroType.Heros) and self:FiltHero(heroData.configCell) then
				local index = -1
				if self._disableHeroIds then
					index = table.indexof(self._disableHeroIds, heroInfo.CfgId,1)
					if index > 0 then
						table.insert(disableHeroes,heroData)
					end
				end

				if index < 0 and self._selectedHeroIds then
					index = table.indexof(self._selectedHeroIds, heroInfo.CfgId,1)
					if index > 0 then
						table.insert(selectedHeroes, heroData)
					end
				end
				if index < 0 then
					table.insert(idleHeroes, heroData)
				end
			end
		end
	end

	param.heroSortMode = param.heroSortMode or UITroopHeroSelectComponnet.SortMode.Quality

	self:SortHeros(param, selectedHeroes)
	self:SortHeros(param, disableHeroes)
	self:SortHeros(param, idleHeroes)

	self.heroSelectionTable:Clear()
	if not self.heroTableDatas then
		---@type UITroopHeroSelectionCellData[]
		self.heroTableDatas = {}
	end

	local index = 1
	--选中的在最前面
	if selectedHeroes and #selectedHeroes > 0 then
		for _, heroData in ipairs(selectedHeroes) do
			---@type UITroopHeroSelectionCellData
			local data = {}
			data.heroId = heroData.id
			data.onClick = Delegate.GetOrCreate(self, self.OnHeroSelectionCellClick)
			data.onDragBegin = Delegate.GetOrCreate(self, self.OnHeroCellDragBegin)
			data.onDrag = Delegate.GetOrCreate(self, self.OnHeroCellDrag)
			data.onDragEnd = Delegate.GetOrCreate(self, self.OnHeroCellDragEnd)
			data.simpleMode = param.simpleMode
			data.selected = true
			data.disable = false
			data.index = index
			self.heroTableDatas[index] = data
			self.heroSelectionTable:AppendData(data)
			index = index + 1
		end
	end

	--备选在中间
	if idleHeroes and #idleHeroes > 0 then
		for _, heroData in ipairs(idleHeroes) do
			---@type UITroopHeroSelectionCellData
			local data = {}
			data.heroId = heroData.id
			data.onClick = Delegate.GetOrCreate(self, self.OnHeroSelectionCellClick)
			data.onDragBegin = Delegate.GetOrCreate(self, self.OnHeroCellDragBegin)
			data.onDrag = Delegate.GetOrCreate(self, self.OnHeroCellDrag)
			data.onDragEnd = Delegate.GetOrCreate(self, self.OnHeroCellDragEnd)
			data.simpleMode = param.simpleMode
			data.selected = false
			data.disable = false
			data.index = index
			self.heroTableDatas[index] = data
			self.heroSelectionTable:AppendData(data)
			index = index + 1
		end
	end

	--禁用的在最后面
	if disableHeroes and #disableHeroes > 0 then
		for _, heroData in ipairs(disableHeroes) do
			---@type UITroopHeroSelectionCellData
			local data = {}
			data.heroId = heroData.id
			data.onClick = Delegate.GetOrCreate(self, self.OnHeroSelectionCellClick)
			data.simpleMode = param.simpleMode
			data.selected = false
			data.disable = true
			data.index = index
			self.heroTableDatas[index] = data
			self.heroSelectionTable:AppendData(data)
			index = index + 1
		end
	end

	if index > 1 then
		for i = 1, index-1 do
			local data = self.heroTableDatas[i]
			local heroCfg = ConfigRefer.Heroes:Find(data.heroId)
			self.heroSelectionTable:AppendCellCustomName(heroCfg:Name())
		end
	end

	self.heroSelectionEmptyText.gameObject:SetActive(index <= 1)
	self:UpdateSelectedHeroData()
end

function UITroopHeroSelectComponnet:SortHeros(param, heroes)
	if (param.heroSortMode == UITroopHeroSelectComponnet.SortMode.Custom) then
		if (param.customSorter) then
			table.sort(heroes, param.customSorter)
		end
	elseif (param.heroSortMode == UITroopHeroSelectComponnet.SortMode.Quality) then
		table.sort(heroes, UITroopHeroSelectComponnet.HeroSortByQuality)
	elseif (param.heroSortMode == UITroopHeroSelectComponnet.SortMode.Level) then
		table.sort(heroes, UITroopHeroSelectComponnet.HeroSortByLevel)
	elseif (param.heroSortMode == UITroopHeroSelectComponnet.SortMode.StarLevel) then
		table.sort(heroes, UITroopHeroSelectComponnet.HeroSortByStarLevel)
	else
		table.sort(heroes, UITroopHeroSelectComponnet.HeroSortByPower)
	end
end

function UITroopHeroSelectComponnet:UpdateHeroSelectionState(heroConfigId, selectionType)
	if (self.heroTableDatas) then
		for _, data in ipairs(self.heroTableDatas) do
			if (data.heroId == heroConfigId) then
				data.selected = (selectionType == UITroopHeroSelectComponnet.SelectionType.Selected)
				data.disable = (selectionType == UITroopHeroSelectComponnet.SelectionType.Disable)
				self.heroSelectionTable:UpdateData(data)
			end
		end
	end

	if (self._selectedHeroIds) then
		if (selectionType == UITroopHeroSelectComponnet.SelectionType.Selected) then
			table.insert(self._selectedHeroIds, heroConfigId)
		else
			local index = table.indexof(self._selectedHeroIds, heroConfigId, 1)
			if index > 0 then
				table.remove(self._selectedHeroIds, index)
			end
		end
	end
	self:UpdateSelectedHeroData()
end

function UITroopHeroSelectComponnet:UpdateSelectedHeroData()
	if not self.heroTableDatas then
		return
	end
end

---@param param UITroopHeroSelectButtonParam
function UITroopHeroSelectComponnet:RefreshButtonState(param)
	if param.btnParam_go then
		local canAutoSelect,tipString = self:CanAutoSelect(param)
		self.btnAutoSelect.CSComponent.gameObject:SetActive(true)
		---@type BistateButtonParameter
		local btnAutoSelectParam = {}
		btnAutoSelectParam.onClick = Delegate.GetOrCreate(self, self.OnBtnAutoSelectClick)
		btnAutoSelectParam.disableClick = function(go)
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(tipString))
		end
		btnAutoSelectParam.buttonText = I18N.Get(param.btnParam_go.buttonText)
		self.btnAutoSelect:FeedData(btnAutoSelectParam)
		self.btnAutoSelect:SetEnabled(canAutoSelect)
		self.onBtnGoClick = param.btnParam_go.onClick
	else
		self.btnAutoSelect.CSComponent.gameObject:SetActive(false)
	end

	if param.btnParam_attack then
		self.btnAttack.CSComponent.gameObject:SetActive(true)
		---@type BistateButtonParameter
		local btnAttackParam = {}
		btnAttackParam.onClick = Delegate.GetOrCreate(self, self.OnBtnAttackClick)
		btnAttackParam.buttonText = I18N.Get(param.btnParam_attack.buttonText)
		self.btnAttack:FeedData(btnAttackParam)
		self.btnAttack:SetEnabled(param.btnParam_attack.buttonEnabled)
		self.onBtnAttackClick = param.btnParam_attack.onClick
	else
		self.btnAttack.CSComponent.gameObject:SetActive(false)
	end

	if param.btnParam_save then
		self.btnSave.CSComponent.gameObject:SetActive(true)
		---@type BistateButtonParameter
		local btnSaveParam = {}
		btnSaveParam.onClick = Delegate.GetOrCreate(self, self.OnBtnSaveClick)
		btnSaveParam.buttonText = I18N.Get(param.btnParam_save.buttonText)
		self.btnSave:FeedData(btnSaveParam)
		self.btnSave:SetEnabled(param.btnParam_save.buttonEnabled)
		self.onBtnSaveClick = param.btnParam_save.onClick
	else
		self.btnSave.CSComponent.gameObject:SetActive(false)
	end

end

function UITroopHeroSelectComponnet:OnBtnAutoSelectClick()

	local canSelect,tipString = self:CanAutoSelect(self.param)
	if not canSelect then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(tipString))
		return
	end

	if self.onBtnGoClick then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("formation_quicktips"))
		self.onBtnGoClick()
	end
end


function UITroopHeroSelectComponnet:OnBtnAttackClick()
	if self.onBtnAttackClick then
		self.onBtnAttackClick()
	end
end

function UITroopHeroSelectComponnet:OnBtnSaveClick()
	if self.onBtnSaveClick then
		self.onBtnSaveClick()
	end
end

--- 按品质排序英雄
---@param a HeroConfigCache
---@param b HeroConfigCache
function UITroopHeroSelectComponnet.HeroSortByQuality(a, b)
	if not a and not b then return false end
	if not a then return false end
	if not b then return true end
	local qualityA = a.configCell and a.configCell:Quality() or -1
	local qualityB = b.configCell and b.configCell:Quality() or -1
	if (qualityA ~= qualityB) then
		return qualityA > qualityB
	else
		local rankA = a.dbData and a.dbData.StarLevel or -1
		local rankB = b.dbData and b.dbData.StarLevel or -1
		if (rankA ~= rankB) then
			return rankA > rankB
		else
			local levelA = a.dbData and a.dbData.Level or -1
			local levelB = b.dbData and b.dbData.Level or -1
			if (levelA ~= levelB) then
				return levelA > levelB
			else
				return a.id < b.id
			end
		end
	end
end

--- 按等级排序英雄
---@param a HeroConfigCache
---@param b HeroConfigCache
function UITroopHeroSelectComponnet.HeroSortByLevel(a, b)
	if not a and not b then return false end
	if not a then return false end
	if not b then return true end
	local levelA = a.dbData and a.dbData.Level or -1
	local levelB = b.dbData and b.dbData.Level or -1
	if (levelA ~= levelB) then
		return levelA > levelB
	else
		local qualityA = a.configCell and a.configCell:Quality() or -1
		local qualityB = b.configCell and b.configCell:Quality() or -1
		if (qualityA ~= qualityB) then
			return qualityA > qualityB
		else
			local rankA = a.dbData and a.dbData.StarLevel or -1
			local rankB = b.dbData and b.dbData.StarLevel or -1
			if (rankA ~= rankB) then
				return rankA > rankB
			else
				return a.id < b.id
			end
		end
	end
end

--- 按星级排序英雄
---@param a HeroConfigCache
---@param b HeroConfigCache
function UITroopHeroSelectComponnet.HeroSortByStarLevel(a, b)
	if not a and not b then return false end
	if not a then return false end
	if not b then return true end
	local rankA = a.dbData and a.dbData.StarLevel or -1
	local rankB = b.dbData and b.dbData.StarLevel or -1
	if (rankA ~= rankB) then
		return rankA > rankB
	else
		local qualityA = a.configCell and a.configCell:Quality() or -1
		local qualityB = b.configCell and b.configCell:Quality() or -1
		if (qualityA ~= qualityB) then
			return qualityA > qualityB
		else
			local levelA = a.dbData and a.dbData.Level or -1
			local levelB = b.dbData and b.dbData.Level or -1
			if (levelA ~= levelB) then
				return levelA > levelB
			else
				return a.id < b.id
			end
		end
	end
end

---@param a HeroConfigCache
---@param b HeroConfigCache
function UITroopHeroSelectComponnet.HeroSortByPower(a, b)
	if not a and not b then return false end
	if not a then return false end
	if not b then return true end
	local powerA = ModuleRefer.HeroModule:CalcHeroPower(a.id)
	local powerB = ModuleRefer.HeroModule:CalcHeroPower(b.id)
	if (powerA ~= powerB) then
		return powerA > powerB
	else
		local qualityA = a.configCell and a.configCell:Quality() or -1
		local qualityB = b.configCell and b.configCell:Quality() or -1
		if (qualityA ~= qualityB) then
			return qualityA > qualityB
		else
			local rankA = a.dbData and a.dbData.StarLevel or -1
			local rankB = b.dbData and b.dbData.StarLevel or -1
			if (rankA ~= rankB) then
				return rankA > rankB
			else
				local levelA = a.dbData and a.dbData.Level or -1
				local levelB = b.dbData and b.dbData.Level or -1
				if (levelA ~= levelB) then
					return levelA > levelB
				else
					return a.id < b.id
				end
			end
		end
	end
end

--- 英雄选择单元格点击
---@param data UITroopHeroSelectionCellData
function UITroopHeroSelectComponnet:OnHeroSelectionCellClick(data)
    if (self._onHeroSelected) then
        local heroConfigId = data.heroId
        local state = UITroopHeroSelectComponnet.SelectionType.Normal
        if self._selectedHeroIds and table.ContainsValue(self._selectedHeroIds, heroConfigId) then
            state = UITroopHeroSelectComponnet.SelectionType.Selected
        elseif self._disableHeroIds and table.ContainsValue(self._disableHeroIds, heroConfigId) then
            state = UITroopHeroSelectComponnet.SelectionType.Disable
        end
        self._onHeroSelected(heroConfigId, state)
    end
end


function UITroopHeroSelectComponnet:OnHeroCellDragBegin(go,pointData,cellData)
	if self._onHeroDragBegin then
		self._onHeroDragBegin(go,pointData,cellData)
	end
end

function UITroopHeroSelectComponnet:OnHeroCellDrag(go,pointData,cellData)
	if self._onHeroDrag then
		self._onHeroDrag(go,pointData,cellData)
	end
end

function UITroopHeroSelectComponnet:OnHeroCellDragEnd(go,pointData,cellData)
	if self._onHeroDragEnd then
		self._onHeroDragEnd(go,pointData,cellData)
	end
end


function UITroopHeroSelectComponnet:OnBtnFilterClick()

	---@type FilterParam[]
	local filterCode = self.curFilterCode
	local filterParam = {}
	local defaultFilterCode = 0
	-- local saveDefaultFilter = self.curFilterCode == nil

	table.insert(filterParam, {
		typeIndex = CommonChoosePopupDefine.FilterType.Quality,
		name = I18N.Get("skincollection_rarity"),
		chooseType = CommonChoosePopupDefine.ChooseType.Multiple,
		subFilterType = CommonChooseHelper.GetSubFilterTypeListByType(CommonChoosePopupDefine.FilterType.Quality
			, filterCode, 1, 3
		),
	})
	-- if saveDefaultFilter then
	-- 	defaultFilterCode = defaultFilterCode | CommonChooseHelper.GetDefaultFilterCodeByType(CommonChoosePopupDefine.FilterType.Quality)
	-- end

	table.insert(filterParam, {
		typeIndex = CommonChoosePopupDefine.FilterType.HeroBattleType,
		name = I18N.Get("formation_battleposition"),
		chooseType = CommonChoosePopupDefine.ChooseType.Multiple,
		subFilterType = CommonChooseHelper.GetSubFilterTypeListByType(CommonChoosePopupDefine.FilterType.HeroBattleType
			, filterCode
		),
	})
	-- if saveDefaultFilter then
	-- 	defaultFilterCode = defaultFilterCode | CommonChooseHelper.GetDefaultFilterCodeByType(CommonChoosePopupDefine.FilterType.HeroBattleType)
	-- end

	table.insert(filterParam, {
		typeIndex = CommonChoosePopupDefine.FilterType.HeroAssociatedTag,
		name = I18N.Get("formation_tagstyle"),
		chooseType = CommonChoosePopupDefine.ChooseType.Multiple,
		subFilterType = CommonChooseHelper.GetSubFilterTypeListByType(CommonChoosePopupDefine.FilterType.HeroAssociatedTag
			, filterCode
		),
	})
	-- if saveDefaultFilter then
	-- 	defaultFilterCode = defaultFilterCode | CommonChooseHelper.GetDefaultFilterCodeByType(CommonChoosePopupDefine.FilterType.HeroAssociatedTag)
	-- end

	-- if saveDefaultFilter then
	-- 	self.defaultFilterCode = defaultFilterCode
	-- end

	-- self:SetDefaultFilterCode(filterCode)
	g_Game.UIManager:Open(UIMediatorNames.CommonChoosePopupMediator, {
		title = I18N.Get("skincollection_screen"),
		filterType = filterParam,
		confirmCallBack = function(data)
			self:OnConfirmFilter(data)
		end,
		defaultFilterCode = 0 --self.defaultFilterCode,
	})
end

function UITroopHeroSelectComponnet:OnConfirmFilter(filterData)
	self.curFilterData = filterData
	self.curFilterCode = CommonChooseHelper.GetFilterCode(filterData)
	self.curFilterState = CommonChooseHelper.GetFilterStateByFilterData(filterData)
	self:RefreshHeroSelectionList(self.param)
	if self.curFilterCode > 0 then
		self.goFilterIcon_Normal:SetActive(false)
		self.goFilterIcon_Select:SetActive(true)
	else
		self.goFilterIcon_Normal:SetActive(true)
		self.goFilterIcon_Select:SetActive(false)
	end
end

function UITroopHeroSelectComponnet:OnBtnStyleClick(tagType, selectAll)
	if selectAll then
		self.statusCtrlBtnAllStyle:ApplyStatusRecord(1)
		for type, _ in pairs(self.curFilterState[CommonChoosePopupDefine.FilterType.HeroAssociatedTag] or {}) do
			self.curFilterState[CommonChoosePopupDefine.FilterType.HeroAssociatedTag][type] = true
		end
	else
		self.statusCtrlBtnAllStyle:ApplyStatusRecord(0)
		for type, state in pairs(self.curFilterState[CommonChoosePopupDefine.FilterType.HeroAssociatedTag] or {}) do
			self.curFilterState[CommonChoosePopupDefine.FilterType.HeroAssociatedTag][type] = (type == tagType)
		end
	end
	self:RefreshHeroSelectionList(self.param)
end

function UITroopHeroSelectComponnet:OnBtnAllStyleClick()
	for _, filter in ipairs(self.luaTagFilters) do
		filter.Lua:IsSelect(false)
	end
	self:OnBtnStyleClick(nil, true)
end

---@param heroConfig HeroesConfigCell
---@return boolean @true:Pass Filter
function UITroopHeroSelectComponnet:FiltHero(heroConfig)
	if not heroConfig or not self.curFilterState then
		return true
	end

	--hero quality
	if self.curFilterState[CommonChoosePopupDefine.FilterType.Quality] then
		--品质从1开始，排序与HeroQuality相反
		local heroQuality = HeroQuality.Golden - heroConfig:Quality() + 1
		if not self.curFilterState[CommonChoosePopupDefine.FilterType.Quality][heroQuality] then
			return false
		end
	end

	if self.curFilterState[CommonChoosePopupDefine.FilterType.HeroBattleType] then
		local heroBattleType = heroConfig:BattleType() + 1
		if not self.curFilterState[CommonChoosePopupDefine.FilterType.HeroBattleType][heroBattleType] then
			return false
		end
	end

	if self.curFilterState[CommonChoosePopupDefine.FilterType.HeroAssociatedTag] then
		local tagId = heroConfig:AssociatedTagInfo()
		local tagCfg = ConfigRefer.AssociatedTag:Find(tagId)
		local tagType = (tagCfg and tagCfg:TagInfo()) or 0
		if not self.curFilterState[CommonChoosePopupDefine.FilterType.HeroAssociatedTag][tagType] then
			return false
		end
	end

	return true
end

---@param param UITroopHeroSelectComponnetParam
---@return boolean, string @can AutoSelect, Toast string
function UITroopHeroSelectComponnet:CanAutoSelect(param)
	if param.btnParam_save and param.btnParam_save.buttonEnabled then
		return false, "formation_quickfailtips"
	end

	if param.btnParam_go and not param.btnParam_go.buttonEnabled then
		return false, "UNKONW ERROR"
	end

	--Check Select HeroCount
	local heroCount = #self._selectedHeroIds
	local petCount = 0
	--check pets
	for i = 1, heroCount do
		local heroId = self._selectedHeroIds[i]
		local petCompId = ModuleRefer.HeroModule:GetHeroLinkPet(heroId,false)
		if petCompId and petCompId > 0 then
			petCount = petCount + 1
		end
	end
	if heroCount >= MAX_HERO_COUNT and petCount >= MAX_HERO_COUNT then
		return false, "formation_fullposition"
	end

	local allHeroCount = self.heroTableDatas and table.nums(self.heroTableDatas) or 0
	local disableHeroCount = self._disableHeroIds and #self._disableHeroIds or 0
	local hasFreeHero = (allHeroCount - disableHeroCount - heroCount) > 0
	local hasFreePet = ModuleRefer.PetModule:HasFreePet()

	if not hasFreeHero and not hasFreePet then
		return false, "formation_noheroandpet"
	end

	local needHero = heroCount < MAX_HERO_COUNT
	local needPet = petCount < heroCount

	if (needHero and hasFreeHero) or (needPet and hasFreePet) then
		return true
	end

	if needHero and not hasFreeHero then
		return false, "formation_noheroandpet"
	elseif needPet and not hasFreePet then
		return false, "formation_nousepet"
	end

	g_Logger.Warn("Unkown Situation")
	return true
end

return UITroopHeroSelectComponnet
