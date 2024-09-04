local BaseUIComponent = require("BaseUIComponent")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local Utils = require("Utils")
local I18N = require("I18N")
local CommonDropDown = require("CommonDropDown")

---@class UIPetSelectPopupComponent : BaseUIComponent
local UIPetSelectPopupComponent = class("UIPetSelectPopupComponent", BaseUIComponent)

local PET_SORT_MODE_RARITY = 1
local PET_SORT_MODE_RANK = 2

---@class UIPetSelectPopupComponentParam
---@field onSelectPet fun(data: UIPetIconData)
---@field onUnselectPet fun(data: UIPetIconData)
---@field showAllType boolean
---@field petDataPostProcess fun(data: table<number, UIPetIconData>)
---@field hintText string
---@field sortMode number
---@field reverseOrder boolean
---@field selectedType number
---@field petDataFilter fun(data: UIPetIconData):boolean

---@class UIPetSortData
---@field id number
---@field rarity number
---@field level number
---@field rank number

function UIPetSelectPopupComponent:ctor()
    self._selectedType = -1
    self._petSortMode = PET_SORT_MODE_RARITY
	---@type table<number, UIPetIconData>
	self._petData = {}
	---@type table<UIPetSortData>
	self._petSortData = {}
end

function UIPetSelectPopupComponent:OnCreate()
	self:InitObjects()
end

---@param param UIPetSelectPopupComponentParam
function UIPetSelectPopupComponent:OnShow(param)
	if (param) then
		self.onSelectPet = param.onSelectPet
		self.onUnselectPet = param.onUnselectPet
		self.showAllType = param.showAllType
		self.onlyShowType = param.onlyShowType
		self.petDataPostProcess = param.petDataPostProcess
		self.hintText = param.hintText
		self.sortMode = param.sortMode
		self.reverseOrder = param.reverseOrder
		self.petDataFilter = param.petDataFilter
		self._selectedType = param.selectedType or -1
	end

	self:InitUI()
	self:RefreshUI()
end

function UIPetSelectPopupComponent:InitObjects()
	self.btnClose = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.textHint = self:Text("p_text_hint")
    self.tableTypeList = self:TableViewPro("p_table_head")
    self.tablePetList = self:TableViewPro("p_table_pet")
	---@type CommonDropDown
    self.filterSort = self:LuaBaseComponent("child_dropdown_sort")
    self.closePanel = self:Button("p_close_panel", Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.emptyNode = self:GameObject("p_empty")
    self.emptyText = self:Text("p_text_empty")
end

function UIPetSelectPopupComponent:InitUI()
	self._petSortMode = self.sortMode or PET_SORT_MODE_RANK
	if (self._petSortMode <= 0) then
		self._petSortMode = PET_SORT_MODE_RANK
	end
    local sortDropDownData = {}
    sortDropDownData.items = CommonDropDown.CreateData(
		"", I18N.Get("pet_filter_condition0"),
		"", I18N.Get("pet_sorted_by_rank_name")
	)
    sortDropDownData.defaultId = self._petSortMode
    sortDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnDropDownSortSelect)
    self.filterSort:FeedData(sortDropDownData)
	self:SetHintText(self.hintText)
end

function UIPetSelectPopupComponent:RefreshUI()
	self:RefreshType()
end

function UIPetSelectPopupComponent:OnDropDownSortSelect(id)
    self._petSortMode = id
    self:SortPetData()
    self:RefreshPetList()
end

function UIPetSelectPopupComponent:OnHide(param)
    g_Game.EventManager:TriggerEvent(EventConst.ON_UI_PET_SELECT_POPUP_COMPONENT_CLOSE)
end

function UIPetSelectPopupComponent:OnOpened(param)
end

function UIPetSelectPopupComponent:OnClose(param)
end

function UIPetSelectPopupComponent:OnBtnCloseClicked(args)
    self:SetVisible(false)
end

function UIPetSelectPopupComponent:SetHintText(text)
	self.textHint.text = text
end

--- 刷新类型
function UIPetSelectPopupComponent:RefreshType()
    self.tableTypeList:Clear()
    -- All type
	if (self.showAllType) then
		self.tableTypeList:AppendData(
			{
				id = -1,
				selected = self._selectedType < 0,
				onClick = Delegate.GetOrCreate(self, self.OnTypeSelected)
			},
			0
		)
	end
    local typeList = ModuleRefer.PetModule:GetTypeList()
	local typeSortList = {}
	local selectedData = nil
    if (typeList) then
		for _, typeId in ipairs(typeList) do
			table.insert(typeSortList, {
				id = typeId,
				count = ModuleRefer.PetModule:GetPetCountByType(typeId),
			})
		end
		table.sort(typeSortList, UIPetSelectPopupComponent.SortTypeWithCount)
		for _, item in ipairs(typeSortList) do
			if self.onlyShowType and item.id == self._selectedType or not self.onlyShowType then
				local type = ModuleRefer.PetModule:GetTypeCfg(item.id)
				local data = {
					id = item.id,
					icon = type:Icon(),
					selected = (item.id == self._selectedType),
					hasPet = item.count and item.count > 0,
					onClick = Delegate.GetOrCreate(self, self.OnTypeSelected),
				}
				if (data.selected) then selectedData = data end
				self.tableTypeList:AppendData(data, 1)
			end
		end
    end
	if (selectedData) then
		self.tableTypeList:SetDataVisable(selectedData)
	end
    self.tableTypeList:RefreshAllShownItem()
    self:RefreshPetList()
end

function UIPetSelectPopupComponent:OnTypeSelected(id)
    if (self._selectedType ~= id) then
        if (not id) then
            id = -1
        end
        self._selectedType = id
        self:RefreshType()
    end
end

function UIPetSelectPopupComponent:GetPetListTable()
	return self.tablePetList
end

--- 刷新宠物数据及列表
---@param self UIPetSelectPopupComponent
function UIPetSelectPopupComponent:RefreshPetList()
	---@type table<number, wds.PetInfo>
    local pets
    if self._selectedType > 0 then
        pets = ModuleRefer.PetModule:GetPetsByType(self._selectedType)
    else
        pets = ModuleRefer.PetModule:GetPetList()
    end

	self._petData = {}
	self._petSortData = {}
    self.tablePetList:Clear()

	self.emptyNode:SetActive(false)

	if table.isNilOrZeroNums(pets) then
        self.emptyNode:SetActive(true)
        return
    end

    for id, pet in pairs(pets) do
		---@type UIPetIconData
        local data = {
            id = id,
            cfgId = pet.ConfigId,
            level = pet.Level,
			rank = pet.RankLevel,
			templateIds = pet.TemplateIds,
        }

		if (not self.petDataFilter or self.petDataFilter(data)) then
			self._petData[id] = data
		end
    end

	-- 宠物数据后处理
	if (self.petDataPostProcess) then
		self.petDataPostProcess(self._petData)
	end

	if table.isNilOrZeroNums(self._petData) then
        self.emptyNode:SetActive(true)
        return
    end

	-- 排序
	for id, data in pairs(self._petData) do
        local cfg = ModuleRefer.PetModule:GetPetCfg(data.cfgId)
        table.insert(self._petSortData, {
			id = id,
			rarity = cfg:Quality(),
			level = data.level,
			rank = data.rank,
			templateIds = data.templateIds,
		})
	end
	self:SortPetData()

	local selectedData
	for _, item in ipairs(self._petSortData) do
		if (self._petData[item.id].selected) then
			selectedData = self._petData[item.id]
		end
        self.tablePetList:AppendData(self._petData[item.id])
    end
	if (selectedData) then
		self.tablePetList:SetDataVisable(selectedData)
	end
    self.tablePetList:RefreshAllShownItem()
end

---@param self UIPetSelectPopupComponent
---@param func fun(data: table<number, table>)
function UIPetSelectPopupComponent:SetPetDataPostProcess(func)
	self.petDataPostProcess = func
end

--- 伙伴数据排序
function UIPetSelectPopupComponent:SortPetData()
    if (self._petSortMode == PET_SORT_MODE_RARITY) then
        table.sort(self._petSortData, UIPetSelectPopupComponent.SortPetDataByRarity)
    -- elseif (self._petSortMode == PET_SORT_MODE_LEVEL) then
    --     table.sort(self._petSortData, UIPetSelectPopupComponent.SortPetDataByLevel)
	elseif (self._petSortMode == PET_SORT_MODE_RANK) then
		table.sort(self._petSortData, UIPetSelectPopupComponent.SortPetDataByRank)
    end
	if (self.reverseOrder) then
		Utils.ReverseArray(self._petSortData)
	end
end

---@param a UIPetSortData
---@param b UIPetSortData
function UIPetSelectPopupComponent.SortPetDataByRarity(a, b)
	if (a.rarity ~= b.rarity) then
		return a.rarity > b.rarity
	elseif (a.level ~= b.level) then
		return a.level > b.level
	elseif (a.rank ~= b.rank) then
		return a.rank > b.rank
	end
	return a.id < b.id
end

---@param a UIPetSortData
---@param b UIPetSortData
function UIPetSelectPopupComponent.SortPetDataByLevel(a, b)
	if (a.level ~= b.level) then
		return a.level > b.level
	elseif (a.rarity ~= b.rarity) then
		return a.rarity > b.rarity
	elseif (a.rank ~= b.rank) then
		return a.rank > b.rank
	end
	return a.id < b.id
end

---@param a UIPetSortData
---@param b UIPetSortData
function UIPetSelectPopupComponent.SortPetDataByRank(a, b)
	if (a.rank ~= b.rank) then
		return a.rank > b.rank
	elseif (a.level ~= b.level) then
		return a.level > b.level
	elseif (a.rarity ~= b.rarity) then
		return a.rarity > b.rarity
	end
	return a.id < b.id
end

function UIPetSelectPopupComponent:GetPetData(id)
	return self._petData[id]
end

--- 刷新宠物列表(不刷新数据)
---@param self UIPetSelectPopupComponent
function UIPetSelectPopupComponent:RefreshPetTable()
	self.tablePetList:RefreshAllShownItem()
end

function UIPetSelectPopupComponent.SortTypeWithCount(a, b)
	if (not a.count and not b.count) then
		return a.id < b.id
	elseif (a.count and not b.count) then
		return true
	elseif (not a.count and b.count) then
		return false
	elseif (a.count > b.count) then
		return true
	elseif (a.count < b.count) then
		return false
	else
		return a.id < b.id
	end
end

return UIPetSelectPopupComponent
