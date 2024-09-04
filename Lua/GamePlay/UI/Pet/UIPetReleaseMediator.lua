local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local CommonDropDown = require("CommonDropDown")
local BistateButton = require("BistateButton")
local DBEntityPath = require("DBEntityPath")
local UIPetMediator = require("UIPetMediator")

---@class UIPetReleaseMediator : BaseUIMediator
local UIPetReleaseMediator = class('UIPetReleaseMediator', BaseUIMediator)

local TYPE_INDEX_PET = 0
local TYPE_INDEX_ALL = 1
local PET_SORT_MODE_RARITY = 1
local PET_SORT_MODE_LEVEL = 2
local PET_FILTER_QUALITY_GREEN = 1
--local PET_FILTER_QUALITY_BLUE = 2
--local PET_FILTER_QUALITY_PURPLE = 3
--local PET_FILTER_QUALITY_ORANGE = 4

function UIPetReleaseMediator:ctor()
	self._selectedType = -1
	self._selectedPets = {}
	self._selectedPetCount = 0
	self._petSortMode = PET_SORT_MODE_RARITY
	self._petData = {}
	self._selectedFilter = PET_FILTER_QUALITY_GREEN
	self._petExpItems = {}
	self._returnItemCount = 0
	self._petTypeData = {}
end

function UIPetReleaseMediator:OnCreate()
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetInfos.MsgPath, Delegate.GetOrCreate(self, self.PetDataChanged))
    self:InitObjects()
	self._petsInPresets = {}
end

function UIPetReleaseMediator:InitObjects()
	---@type CommonBackButtonComponent
	self.backButton = self:LuaObject("child_common_btn_back")

	self.textCount = self:Text("p_text_quantity")

	self.tableTypeList = self:TableViewPro("p_table_head")

	self.groupRight = self:GameObject("group_right")

	---@type CommonDropDown
	self.petSortModeDropDown = self:LuaObject("child_dropdown_sort")
	self.petListNode = self:GameObject("p_pet_list")
	self.tablePetList = self:TableViewPro("p_table_pet")
	self.emptyListNode = self:GameObject("p_pet_empty")
	self.textEmpty = self:Text("p_text_empty", "pet_memo4")

	self.rightNonEmpty = self:GameObject("p_non_empty")
	self.rightEmpty = self:GameObject("p_status_empty")
	self.rewardNode = self:GameObject("p_reward")
	self.textReward = self:Text("p_text_reward", "pet_recycle_tip0")
	self.tableRewardItem = self:TableViewPro("p_table_need_item")
	self.textHint = self:Text("p_text_hint", "pet_memo0")
	self.textSelectedNum = self:Text("p_text_hint_num")
	---@type BistateButton
	self.buttonRelease = self:LuaObject("child_comp_btn_b")
	self.tableSelected = self:TableViewPro("p_table_select")
	---@type CommonDropDown
	self.filterDropDown = self:LuaObject("child_dropdown_filter")
	self.buttonPut = self:Button("p_comp_btn_put", Delegate.GetOrCreate(self, self.OnButtonPutClick))
	self.textPut = self:Text("p_text_put", "pet_recycle_button0")
end

function UIPetReleaseMediator:OnShow(param)
	self._closeCallback = param
    self:InitData()
    self:InitUI()
    self:RefreshUI()
end

function UIPetReleaseMediator:OnHide(param)
end

function UIPetReleaseMediator:OnOpened(param)
end

function UIPetReleaseMediator:OnClose(param)
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetInfos.MsgPath, Delegate.GetOrCreate(self, self.PetDataChanged))
	if (self._closeCallback) then
		self._closeCallback()
	end
end

--- 初始化数据
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:InitData()
    self.backButton:FeedData({
        title = I18N.Get("pet_title1"),
    })

	local sortDropDownData = {}
    sortDropDownData.items = CommonDropDown.CreateData(
        "", I18N.Get("pet_filter_condition0"),
        "", I18N.Get("pet_filter_condition1")
    )
    sortDropDownData.defaultId = 1
    sortDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnSortDropDownSelect)
    self.petSortModeDropDown:FeedData(sortDropDownData)

	local filterDropDownData = {}
	filterDropDownData.items = CommonDropDown.CreateData(
		"", I18N.Get("pet_filter_condition2"),
		"", I18N.Get("pet_filter_condition3"),
		"", I18N.Get("pet_filter_condition4"),
		"", I18N.Get("pet_filter_condition5"),
		"", I18N.Get("pet_type_name0")
	)
	filterDropDownData.defaultId = 1
	filterDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnFilterDropDownSelect)
	self.filterDropDown:FeedData(filterDropDownData)

	self.buttonRelease:FeedData({
		onClick = Delegate.GetOrCreate(self, self.OnButtonReleaseClick),
		buttonState = BistateButton.BUTTON_TYPE.RED
	})
	self.buttonRelease:SetButtonText(I18N.Get("pet_recycle_button1"))

	--self:LoadPetExpItems()

	self._petsInPresets = ModuleRefer.TroopModule:GetAllPetsInPresets()
end

--- 初始化UI
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:InitUI()

end

--- 刷新UI
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:RefreshUI()
	self:RefreshType()
end

--- 刷新类别
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:RefreshType()
	self.textCount.text = string.format("%s/%s", ModuleRefer.PetModule:GetPetCount(), ModuleRefer.PetModule:GetMaxCount())

	local add = self.tableTypeList.DataCount == 0
	--self.tableTypeList:Clear()

	if (add) then
		local dataAll = {
			selected = (self._selectedType <= 0),
			onClick = Delegate.GetOrCreate(self, self.OnTypeAllSelected),
		}
		self.tableTypeList:AppendData(dataAll, TYPE_INDEX_ALL)
		self._petTypeData[-1] = dataAll
	else
		local dataAll = self._petTypeData[-1]
		dataAll.selected = (self._selectedType <= 0)
	end

	local selectedData = nil
	local typeList = ModuleRefer.PetModule:GetTypeList()
	local typeSortList = {}
	if (typeList) then
		for _, typeId in ipairs(typeList) do
			table.insert(typeSortList, {
				id = typeId,
				count = ModuleRefer.PetModule:GetPetCountByType(typeId),
			})
		end
		table.sort(typeSortList, UIPetMediator.SortPetType)
		for _, item in ipairs(typeSortList) do
			local type = ModuleRefer.PetModule:GetTypeCfg(item.id)
			local data = self._petTypeData[item.id]
			if (not data) then
				data = {
					id = item.id,
					icon = type:Icon(),
					selected = (item.id == self._selectedType),
					hasPet = item.count and item.count > 0,
					onClick = Delegate.GetOrCreate(self, self.OnTypeSelected),
				}
			else
				data.selected = (item.id == self._selectedType)
				data.hasPet = item.count and item.count > 0
			end
			self._petTypeData[item.id] = data
			if (data.selected) then selectedData = data end
			if (add) then
				self.tableTypeList:AppendData(data)
			end
		end
	end
	if (selectedData) then
		self.tableTypeList:SetDataVisable(selectedData)
	end

	self:RefreshPetList(true)
end

--- 刷新伙伴列表
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:RefreshPetList()
	local pets
	if (self._selectedType <= 0) then
		pets = ModuleRefer.PetModule:GetPetList()
	else
		pets = ModuleRefer.PetModule:GetPetsByType(self._selectedType)
	end
	if (not pets) then
		self.emptyListNode:SetActive(true)
		self.petListNode:SetActive(false)
		--self.groupRight:SetActive(false)
		return
	end
	self.emptyListNode:SetActive(false)
	self.petListNode:SetActive(true)
	--self.groupRight:SetActive(true)

	self._petData = {}
	self._petSortData = {}

	for id, pet in pairs(pets) do
		local heroId = ModuleRefer.PetModule:GetPetLinkHero(id)
		if (not self._petsInPresets[id] and (not heroId or heroId <= 0)) then
			local selected = (self._selectedPets[id] ~= nil)
			---@type UIPetIconData
			local data = {
				id = id,
				cfgId = pet.ConfigId,
				onClick = Delegate.GetOrCreate(self, self.OnLeftPetSelected),
				onDeleteClick = Delegate.GetOrCreate(self, self.OnLeftPetDeselected),
				showMask = selected,
				showDelete = selected,
				level = pet.Level,
				--exp = pet.Exp,
			}
			self._petData[id] = data
			local cfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
			table.insert(self._petSortData, {
				id = id,
				rarity = cfg:Quality(),
				level = pet.Level
			})
		end
	end
	self:SortPetData()

	self.tablePetList:Clear()
	for _, item in ipairs(self._petSortData) do
		self.tablePetList:AppendData(self._petData[item.id])
	end
	self.tablePetList:RefreshAllShownItem()
	self:RefreshRightGroupStatus()
end

function UIPetReleaseMediator:OnSortDropDownSelect(id)
    self._petSortMode = id
	self:SortPetData()
    self:RefreshPetList()
end

function UIPetReleaseMediator:OnFilterDropDownSelect(id)
	self._selectedFilter = id
end

function UIPetReleaseMediator:OnTypeSelected(id)
	if (self._selectedType ~= id) then
		self._selectedType = id
		self:RefreshType()
	end
end

function UIPetReleaseMediator:OnTypeAllSelected()
	if (self._selectedType ~= -1) then
		self._selectedType = -1
		self:RefreshType()
	end
end

function UIPetReleaseMediator:OnRightPetClick(data)
	self:RemoveFromSelected(data.id)
end

function UIPetReleaseMediator:OnLeftPetDeselected(data)
	self:RemoveFromSelected(data.id)
end

--- 清除所有选定的伙伴
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:ClearSelected()
	self.tableSelected:Clear()
	self._selectedPets = {}
	self._selectedPetCount = 0
	self:RefreshRightGroupStatus()
end

--- 移除选定的伙伴
---@param self UIPetReleaseMediator
---@param id number
function UIPetReleaseMediator:RemoveFromSelected(id)
	local data = self._petData[id]
	local selectedData = self._selectedPets[id]
	if (selectedData) then
		self.tableSelected:RemData(selectedData)
		self.tableSelected:RefreshAllShownItem()
		self._selectedPets[id] = nil
		self._selectedPetCount = self._selectedPetCount - 1
		if (data) then
			data.showMask = false
			data.showDelete = false
			self.tablePetList:RefreshAllShownItem()
		end
	end
	self:RefreshRightGroupStatus()
end

function UIPetReleaseMediator:OnLeftPetSelected(data)
	self:AddToSelected(data.id, data.cfgId, true)
end

--- 添加选定的伙伴
---@param self UIPetReleaseMediator
---@param id number
---@param cfgId number
---@param refresh boolean
function UIPetReleaseMediator:AddToSelected(id, cfgId, refresh)
	local data = self._petData[id]
	local selectedData = self._selectedPets[id]
	if (not selectedData) then
		if (data) then
			local newData = {
				id = id,
				cfgId = cfgId,
				onDeleteClick = Delegate.GetOrCreate(self, self.OnRightPetClick),
				level = data.level,
				showDelete = true,
			}
			self._selectedPets[id] = newData
			self._selectedPetCount = self._selectedPetCount + 1
			self.tableSelected:AppendData(newData)
			if (refresh) then
				self.tableSelected:RefreshAllShownItem()
			end
			data.showMask = true
			data.showDelete = true
			if (refresh) then
				self.tablePetList:RefreshAllShownItem()
			end
		end
	end
	if (refresh) then
		self:RefreshRightGroupStatus()
	end
end

--- 刷新右侧面板状态
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:RefreshRightGroupStatus()
	self.rightNonEmpty:SetActive(self._selectedPetCount > 0)
	self.rightEmpty:SetActive(self._selectedPetCount <= 0)
	self.textSelectedNum.text = I18N.GetWithParams("pet_recycle_tip1", self._selectedPetCount)
	self.tableSelected:RefreshAllShownItem()

	-- 计算放生返还道具
	local items = {}
	for _, pet in pairs(self._selectedPets) do
		local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.cfgId)
		local itemGroup = ConfigRefer.ItemGroup:Find(petCfg:ReleaseItemGroup())
		if (itemGroup) then
			for i = 1, itemGroup:ItemGroupInfoListLength() do
				local info = itemGroup:ItemGroupInfoList(i)
				local itemId = info:Items()
				local amount = info:Nums()
				if (not items[itemId]) then
					items[itemId] = {
						itemId = itemId,
						count = 0,
					}
				end
				items[itemId].count = items[itemId].count + amount
			end
		end
	end

	if (not table.isNilOrZeroNums(items)) then
		self.rewardNode:SetActive(true)
		self.tableRewardItem:Clear()
		for _, item in pairs(items) do
			local data = {
				configCell = ConfigRefer.Item:Find(item.itemId),
				count = item.count,
				showTips = true,
			}
			self._returnItemCount = self._returnItemCount + item.count
			self.tableRewardItem:AppendData(data)
		end
		self.tableRewardItem:RefreshAllShownItem()
	else
		self.rewardNode:SetActive(false)
	end
end

--- 一键放入
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:OnButtonPutClick()
	self:ClearSelected()

	local pets
	if (self._selectedType <= 0) then
		pets = ModuleRefer.PetModule:GetPetList()
	else
		pets = ModuleRefer.PetModule:GetPetsByType(self._selectedType)
	end
	if (not pets) then return end

	for id, pet in pairs(pets) do
		local cfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
		if (cfg:Quality() <= self._selectedFilter) then
			self:AddToSelected(id, pet.ConfigId, false)
		end
	end
	self.tableSelected:RefreshAllShownItem()
	self.tablePetList:RefreshAllShownItem()
	self:RefreshRightGroupStatus()
end

--- 放生
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:OnButtonReleaseClick()
	---@type CommonConfirmPopupMediatorParameter
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("check_title")
    local content = I18N.Get("check_content")
    dialogParam.content = I18N.GetWithParams(content, self._returnItemCount)
    dialogParam.onConfirm = function(context)
		self:DoRelease()
		return true
    end
	dialogParam.onCancel = function(context)
		return true
	end
    dialogParam.forceClose = true
	g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

function UIPetReleaseMediator:DoRelease()
	local msg = require("PetReleaseParameter").new()
	for id, _ in pairs(self._selectedPets) do
		msg.args.PetCompIds:Add(id)
	end
	msg:Send()
	self.tableSelected:Clear()
	self._selectedPets = {}
	self._selectedPetCount = 0
	self:RefreshRightGroupStatus()
end

--- 伙伴数据排序
---@param self UIPetReleaseMediator
function UIPetReleaseMediator:SortPetData()
	if (self._petSortMode == PET_SORT_MODE_RARITY) then
		table.sort(self._petSortData, UIPetReleaseMediator.SortPetDataByRarity)
	elseif (self._petSortMode == PET_SORT_MODE_LEVEL) then
		table.sort(self._petSortData, UIPetReleaseMediator.SortPetDataByLevel)
	end
end

function UIPetReleaseMediator:PetDataChanged()
	self:RefreshUI()
end

function UIPetReleaseMediator.SortPetDataByRarity(a, b)
	if (a.rarity ~= b.rarity) then
		return a.rarity < b.rarity
	elseif (a.level ~= b.level) then
		return a.level < b.level
	else
		return a.id < b.id
	end
end

function UIPetReleaseMediator.SortPetDataByLevel(a, b)
	if (a.level ~= b.level) then
		return a.level < b.level
	elseif (a.rarity ~= b.rarity) then
		return a.rarity < b.rarity
	else
		return a.id < b.id
	end
end

function UIPetReleaseMediator.SortPetExpItem(a, b)
	return a.exp > b.exp
end

return UIPetReleaseMediator
