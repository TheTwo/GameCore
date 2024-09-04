---scene: scene_pet_carry
local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local ProtocolId = require('ProtocolId')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local CommonDropDown = require("CommonDropDown")
local HeroBindPetParameter = require("HeroBindPetParameter")
local HeroCancelBindPetParameter = require("HeroCancelBindPetParameter")
local UIMediatorNames = require('UIMediatorNames')
local Delegate = require('Delegate')
local UIHeroLocalData = require('UIHeroLocalData')
local UIHelper = require('UIHelper')

---@class UIPetCarryMediator : BaseUIMediator
---@param troopHeroList number[]
---@field petLinkInfo table<number,number> @heroId,petId
local UIPetCarryMediator = class('UIPetCarryMediator',BaseUIMediator)

local PET_SORT_MODE_RARITY = 1
local PET_SORT_MODE_LEVEL = 2
local PET_SORT_MODE_STAR = 3

---@class UIPetCarryMediatorParam
---@field heroId number
---@field petId number
---@field isPvP boolean
---@field heroList number[]
---@field petLinkInfo table<number,number> @heroId,petId
---@field onPetModified fun(heroId:number,petId:number):void
---@field troopIndex number
---@field slotIndex number

function UIPetCarryMediator:ctor()
	self.selectedType = -1
	self.selectedId = -1
	self.selectedFilterTag = 0
	self.petSortMode = PET_SORT_MODE_RARITY
	self.closing = false
	self.bgAnimOpened = false
end

function UIPetCarryMediator:OnCreate()
    self.tableviewproTableHead = self:TableViewPro('p_table_head')
    self.goPetList = self:GameObject('p_pet_list')
    self.tableviewproTablePet = self:TableViewPro('p_table_pet')
    self.compChildDropdown = self:LuaObject('child_dropdown')
    self.goHero = self:GameObject('p_hero')
	self.textText = self:Text('p_text', I18N.Get("hero_pet_carry"))
    self.compChildCardHeroS = self:LuaObject('child_card_hero_s')
    self.btnUpgrade = self:Button('p_btn_upgrade', Delegate.GetOrCreate(self, self.OnBtnUpgradeClicked))
    self.textUpgrade = self:Text('p_text_upgrade', I18N.Get("hero_pet_prom"))
    self.btnCarry = self:Button('p_btn_carry', Delegate.GetOrCreate(self, self.OnBtnCarryClicked))
    self.textCarry = self:Text('p_text_carry', I18N.Get("troop_pet_btn_carried"))
    self.btnCancle = self:Button('p_btn_cancle', Delegate.GetOrCreate(self, self.OnBtnCancleClicked))
    self.textCancle = self:Text('p_text_cancle', I18N.Get("hero_pet_unload"))
	self.compChildPetInfo = self:LuaObject('child_pet_info')
    self.compChildTipsSkillCard = self:LuaObject('child_tips_skill_card')
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.goHint = self:GameObject('p_hint')
	self.baseStatus = self:Image('base_status')
    self.imgIconPosition = self:Image('icon_status')
    self.textHintPosition = self:Text('p_text_hint_position', I18N.Get("hero_pet_carried_tips"))
	self.goTableTab = self:GameObject('p_table_tab')
    self.tableTroopHeroes = self:TableViewPro('p_table_tab')
	self.btnItemAll = self:Button('p_item_all', Delegate.GetOrCreate(self, self.OnBtnItemAllClicked))
    self.textAll = self:Text('p_text_all', I18N.Get("hero_pet_carried_all"))
	self.btnItemAllSelect = self:Button('p_item_all_select', Delegate.GetOrCreate(self, self.OnBtnItemAllSelectClicked))
    self.textAllSelect = self:Text('p_text_all_select', I18N.Get("hero_pet_carried_all"))
	self.goTableTab:SetActive(false)
	self.btnItemAll.gameObject:SetActive(false)

	-- 筛选
	self.btnAllStyle = self:Button("p_btn_all_style", Delegate.GetOrCreate(self, self.OnBtnAllStyleClick))
	self.textBtnAllStyle = self:Text("p_text_all_style", "troop_select_all")
	self.statusCtrlBtnAllStyle = self:StatusRecordParent("p_btn_all_style")
	---@see UIPetFilterComp
	self.luaTemplateBtnStyle = self:LuaBaseComponent("p_btn_style")
	--- type UIPetFilterComp[]
	self.luaTagFilters = {}

	-- 宠物状态
	self.goPetStatus = self:GameObject("p_pet_status")
	self.textPetStatus = self:Text("p_text_status")
end

function UIPetCarryMediator:OnShow()
	local typeList = ModuleRefer.PetModule:GetTypeList()
	local hasPet = false
	if typeList then
		for _, typeId in ipairs(typeList) do
			local count = ModuleRefer.PetModule:GetPetCountByType(typeId)
			if count and count > 0 then
                hasPet = true
            end
        end
    end
    if not hasPet then
		self:BackToPrevious()
		return
	end
end

---@param param UIPetCarryMediatorParam
function UIPetCarryMediator:OnOpened(param)
    self.compChildCommonBack:FeedData({title = I18N.Get("hero_pet_carry")})
    self.heroId = param.heroId
	self.outPetId = param.petId
	self.troopHeroList = param.heroList
	self.petLinkInfo = param.petLinkInfo
	self.isPvP = param.isPvP
	self.closeCallback = param.closeCallback
	self.troopIndex = param.troopIndex
	self.onPetModified = param.onPetModified
	self.selectedType = -1
	self.selectedId = -1
	self.slotIndex = param.slotIndex
	self:InitPetFilters()
    --self:RefreshLeftHead()
	self:RefreshHeroLeftHead()
    local sortDropDownData = {}
    sortDropDownData.items = CommonDropDown.CreateData(
	"", I18N.Get("pet_filter_condition0"),
	"", I18N.Get("pet_filter_condition1"),
	"", I18N.Get("pet_sort_star_desc"))
    sortDropDownData.defaultId = 1
    sortDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnDropDownSelect)
    self.compChildDropdown:FeedData(sortDropDownData)
    g_Game.EventManager:TriggerEvent(EventConst.OPEN_3D_SHOW_UI)
	g_Game.ServiceManager:AddResponseCallback(ProtocolId.HeroBindPet, Delegate.GetOrCreate(self, self.BindPet))
	g_Game.ServiceManager:AddResponseCallback(ProtocolId.HeroCancelBindPet, Delegate.GetOrCreate(self, self.CancleBindPet))
end

function UIPetCarryMediator:OnClose(param)
	if self.closeCallback then
		self.closeCallback()
	end
    g_Game.EventManager:TriggerEvent(EventConst.CLOSE_3D_SHOW_UI)
	--g_Game.UIManager:CloseUI3DModelView()
	g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.HeroBindPet, Delegate.GetOrCreate(self, self.BindPet))
	g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.HeroCancelBindPet, Delegate.GetOrCreate(self, self.CancleBindPet))
end


function UIPetCarryMediator:OnDropDownSelect(id)
    self.petSortMode = id
	self:SortPetData()
    self.selectedId = -1
    self:RefreshPetList()
end

function UIPetCarryMediator:InitPetFilters()
	if not table.isNilOrZeroNums(self.luaTagFilters) then
		for _, comp in ipairs(self.luaTagFilters) do
			UIHelper.DeleteUIComponent(comp)
			self.luaTagFilters = {}
		end
	end
	self.luaTemplateBtnStyle:SetVisible(true)
	for i, tag in ConfigRefer.AssociatedTag:ipairs() do
		local comp = UIHelper.DuplicateUIComponent(self.luaTemplateBtnStyle)
		table.insert(self.luaTagFilters, comp)
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
			self.statusCtrlBtnAllStyle:ApplyStatusRecord(0)
			if self.luaTagFilters[index].Lua:IsSelect() then return end
			self.selectedFilterTag = tag:TagInfo()
			self:RefreshPetList()
			for j, filter in ipairs(self.luaTagFilters) do
				filter.Lua:IsSelect(j == index)
			end
		end
		comp:FeedData(data)
		comp.Lua:IsSelect(false)
	end
	self.luaTemplateBtnStyle:SetVisible(false)
end

function UIPetCarryMediator:OnBtnAllStyleClick()
	self.statusCtrlBtnAllStyle:ApplyStatusRecord(1)
	self.selectAll = true
	self.selectedType = -1
	self.selectedId = -1
	self.selectedFilterTag = 0
	for _, filter in ipairs(self.luaTagFilters) do
		filter.Lua:IsSelect(false)
	end
	self:ShowAllPets()
end

function UIPetCarryMediator.SortTypeWithCount(a, b)
	if a.isCanCarry ~= b.isCanCarry then
		return a.isCanCarry
	elseif (not a.count and not b.count) then
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

function UIPetCarryMediator:RefreshHeroLeftHead()
	local isShow = self.troopHeroList and #self.troopHeroList > 0
	self.goTableTab:SetActive(isShow)
	if isShow then
		self.tableTroopHeroes:Clear()
		for index, heroConfigId in ipairs(self.troopHeroList) do
			if heroConfigId and heroConfigId > 0 then
				---@type UITroopCellData
				local single = {}
				single.index = index
				single.leaderHeroId = heroConfigId
				single.hideText = true
				single.hideLv = true
				single.showJob = true
				single.linkedPetId = self.petLinkInfo[heroConfigId]
				single.onClick = Delegate.GetOrCreate(self, self.OnHeroSelected)
				self.tableTroopHeroes:AppendData(single)
			end
		end
		self.tableTroopHeroes:SetToggleSelectIndex(self.slotIndex - 1)
	end
end

function UIPetCarryMediator:OnHeroSelected(index)
	local curSelectdHeroId = self.troopHeroList[index]
	self.heroId = curSelectdHeroId
	local bindPet = self:GetHeroLinkPet(self.heroId, self.isPvP)
	if bindPet and bindPet > 0 then
		self.outPetId = bindPet
	else
		self.outPetId = -1
	end
	self.selectedType = -1
	self.selectedId = -1
	self:RefreshLeftHead()
	--self:RefreshHeroLeftHead()
end

function UIPetCarryMediator:RefreshLeftHead()
    self.tableviewproTableHead:Clear()
	local typeList = ModuleRefer.PetModule:GetTypeList()
	local typeSortList = {}
	local selectedData = nil
	local curHeroBattleType = ConfigRefer.Heroes:Find(self.heroId):BattleType()
	if typeList then
		for _, typeId in ipairs(typeList) do
			local count = ModuleRefer.PetModule:GetPetCountByType(typeId)
			local petTypeCfg = ConfigRefer.PetType:Find(typeId)
			local petBattleType = petTypeCfg:BattleLabel()
			if count and count > 0 then
				table.insert(typeSortList, {
					id = typeId,
					count = count,
					isCanCarry = true,--curHeroBattleType == petBattleType,
				})
			end
		end
		table.sort(typeSortList, UIPetCarryMediator.SortTypeWithCount)
		if not self.selectedType or self.selectedType <= 0 then
			if #typeSortList > 0 then
				if self.outPetId and self.outPetId > 0 then
					local pet = ModuleRefer.PetModule:GetPetByID(self.outPetId)
					local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
					self.selectedType = petCfg:Type()
				else
					self.selectedType = -1
				end
			end
		end
		for _, item in ipairs(typeSortList) do
			local petType = ModuleRefer.PetModule:GetTypeCfg(item.id)
			local heroList
			if self.troopHeroList and #self.troopHeroList > 0 then
				heroList = self:GetAllPetTypeLinkHerosByList(self.troopHeroList, item.id, self.isPvP) or {}
			end
			local selected = item.id == self.selectedType
			local data = {
				forbidCarry = false, --not item.isCanCarry,
				id = item.id,
				icon = petType:Icon(),
				hasPet = item.count and item.count > 0,
				heroList = heroList,
				onClick = Delegate.GetOrCreate(self, self.OnTypeSelected),
			}
			if selected then
                selectedData = data
            end
			self.tableviewproTableHead:AppendData(data)
		end
	end
	if selectedData then
		self.tableviewproTableHead:SetToggleSelect(selectedData)
		self.tableviewproTableHead:SetFocusData(selectedData)
	end
	self.tableviewproTableHead:RefreshAllShownItem()
    self:OnTypeSelected(self.selectedType, self.outPetId)
end

function UIPetCarryMediator:OnTypeSelected(id, outPetId)
	self.selectAll = false
	if outPetId and outPetId > 0 then
		self.selectedId = outPetId
	else
		self.selectedId = -1
	end
    self.selectedType = id
    self:RefreshPetList()
end

function UIPetCarryMediator:BindPet(isSuccess, reply, rpc)
    if not isSuccess then return end
    local request = rpc.request
	self.selectedId = request.PetId
	local heroId = request.HeroTid
	self:RefreshPetList()
	local pet = ModuleRefer.PetModule:GetPetByID(request.PetId)
	local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(ConfigRefer.Heroes:Find(heroId):Name()) .. I18N.Get("hero_pet_carried_success") .. I18N.Get(petCfg:Name()))
end

function UIPetCarryMediator:CancleBindPet(isSuccess, reply, rpc)
    if not isSuccess then return end
    local request = rpc.request
	self.selectedId = request.PetId
	local heroId = request.HeroTid
	self:RefreshPetList()
	local pet = ModuleRefer.PetModule:GetPetByID(request.PetId)
	local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(ConfigRefer.Heroes:Find(heroId):Name()) .. I18N.Get("hero_pet_carried_cancel") .. I18N.Get(petCfg:Name()))
end

function UIPetCarryMediator:RefreshPetList()
	self:ShowAllPets()
end

---@param data UIPetIconData
function UIPetCarryMediator:OnPetSelected(data)
	if (not data) then return end
    local oldData = self.petData[self.selectedId]
    if oldData then
        oldData.selected = false
    end
    self.selectedId = data.id
	self.compChildPetInfo:FeedData({petId = self.selectedId, petInfo = ModuleRefer.PetModule:GetPetByID(self.selectedId)})
    self.petData[self.selectedId].selected = true
	self.tableviewproTablePet:SetToggleSelect(self.petData[self.selectedId])
    self:RefreshSelectedPet()
end

function UIPetCarryMediator:RefreshSelectedPet()
	local heroId = self:GetPetLinkHero(self.selectedId, self.isPvP)
	if heroId and heroId > 0 then
		self.goHero:SetActive(true)

		local heroConfigCell = ConfigRefer.Heroes:Find(heroId)
		local heroResConfigCell = ConfigRefer.HeroClientRes:Find(heroConfigCell:ClientResCfg())
		---@type HeroConfigCache
		local heroData = {}
		heroData.id = heroConfigCell:Id()
		-- heroData.lv = 0
		-- heroData.starLevel = 0
		heroData.configCell = heroConfigCell
		heroData.resCell = heroResConfigCell
		self.compChildCardHeroS:FeedData({heroData = heroData})
	else
		self.goHero:SetActive(false)
	end

	-- 宠物工作状态
	local city = ModuleRefer.CityModule:GetMyCity()
	local isWorking = city.petManager:IsAssignedOnFurniture(self.selectedId)
	local workingStatusStr = I18N.GetWithParams("troop_pet_status", city.petManager:GetWorkPosition(self.selectedId))
	self.textPetStatus.text = workingStatusStr
	self.goPetStatus:SetActive(isWorking)
	self.baseStatus.gameObject:SetActive(false)
	self.imgIconPosition.gameObject:SetActive(false)

	local pet = ModuleRefer.PetModule:GetPetByID(self.selectedId)
	local bindPet = self:GetHeroLinkPet(self.heroId, self.isPvP)
	self.goHint:SetActive(false)
	if bindPet and bindPet > 0 and bindPet == self.selectedId then
		self.btnCarry.gameObject:SetActive(false)
		self.btnCancle.gameObject:SetActive(true)
	else
		self.btnCarry.gameObject:SetActive(true)
		self.btnCancle.gameObject:SetActive(false)
	end
	self.selectedType = pet.Type
end

function UIPetCarryMediator:OnBtnItemAllSelectClicked()

end

function UIPetCarryMediator:ShowAllPets()
	local curHeroBattleType = ConfigRefer.Heroes:Find(self.heroId):BattleType()
	local allPets = ModuleRefer.PetModule:GetTypedPetList()
	self.petData = {}
	self.pet = {}
	self.petSortData = {}
	for _, pets in pairs(allPets) do
		for id, pet in pairs(pets) do
			if self.selectedFilterTag and self.selectedFilterTag > 0 then
				local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
				local tagCfg = ConfigRefer.AssociatedTag:Find(petCfg:AssociatedTagInfo())
				if tagCfg:TagInfo() ~= self.selectedFilterTag then
					goto continue
				end
			end
			local heroId = self:GetPetLinkHero(id, self.isPvP)
			local petBattleType = ModuleRefer.PetModule:GetPetBattleLabel(pet.ConfigId)
			local data = {
				showMask = false,--curHeroBattleType ~= petBattleType,
				id = id,
				cfgId = pet.ConfigId,
				onClick = Delegate.GetOrCreate(self, self.OnPetSelected),
				selected = self.selectedId == id,
				level = pet.Level,
				rank = ModuleRefer.PetModule:GetStarLevel(id),
				templateIds = pet.TemplateIds,
				hp = ModuleRefer.TroopModule:GetTroopPetHp(id),
				maxHp = ModuleRefer.TroopModule:GetTroopPetHp(id),
				heroId = heroId or 0,
			}
			self.petData[id] = data
			self.pet[id] = pet
			local cfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
			table.insert(self.petSortData, {
				showMask =false, --curHeroBattleType ~= petBattleType,
				id = id,
				cfgId = pet.ConfigId,
				rarity = cfg:Quality(),
				level = ModuleRefer.PetModule:GetStarLevel(id),
				rank = pet.RankLevel,
				templateIds = pet.TemplateIds,
				heroId = heroId or 0,
				heroBind = heroId and heroId > 0,
			})
			::continue::
		end
	end
	self:ShowPets()
	self.btnItemAllSelect.gameObject:SetActive(false)
	self.btnItemAll.gameObject:SetActive(false)
end

function UIPetCarryMediator:ShowPets()
	self:SortPetData()

	if not self.selectedId or self.selectedId <= 0 then
		self.selectedId = (self.petSortData[1] or {}).id or -1
	end
    if self.petData[self.selectedId] then
        self.petData[self.selectedId].selected = true
	else
		self.selectedId = (self.petSortData[1] or {}).id or -1
    end
	self.tableviewproTablePet:Clear()
	for _, item in ipairs(self.petSortData) do
		self.tableviewproTablePet:AppendDataEx(self.petData[item.id], 0, 0, 0)
	end

	if self.petData[self.selectedId] then
		self.tableviewproTablePet:SetToggleSelect(self.petData[self.selectedId])
	end
	self.tableviewproTablePet:RefreshAllShownItem()
	if self.selectedId and self.selectedId > 0 then
    	self:OnPetSelected({id = self.selectedId})
	end
end

function UIPetCarryMediator:SortPetData()
	if (self.petSortMode == PET_SORT_MODE_RARITY) then
		table.sort(self.petSortData, UIPetCarryMediator.SortPetDataByRarity)
	elseif (self.petSortMode == PET_SORT_MODE_LEVEL) then
		table.sort(self.petSortData, UIPetCarryMediator.SortPetDataByLevel)
	elseif (self.petSortMode == PET_SORT_MODE_STAR) then
		table.sort(self.petSortData, UIPetCarryMediator.SortPetDataByRank)
	end
end

function UIPetCarryMediator.SortPetDataByRarity(a, b)
	if (a.heroBind ~= b.heroBind) then
        return a.heroId > b.heroId
    elseif (a.rarity ~= b.rarity) then
        return a.rarity > b.rarity
    elseif (a.level ~= b.level) then
        return a.level > b.level
    elseif (a.rank ~= b.rank) then
        return a.rank > b.rank
    else
        return a.cfgId < b.cfgId
    end
end

function UIPetCarryMediator.SortPetDataByLevel(a, b)
	if (a.heroBind ~= b.heroBind) then
        return a.heroId > b.heroId
    elseif (a.level ~= b.level) then
        return a.level > b.level
    elseif (a.rarity ~= b.rarity) then
        return a.rarity > b.rarity
    elseif (a.rank ~= b.rank) then
        return a.rank > b.rank
    else
        return a.cfgId  < b.cfgId
    end
end

function UIPetCarryMediator.SortPetDataByRank(a, b)
	if (a.heroBind ~= b.heroBind) then
        return a.heroId > b.heroId
    elseif (a.rank ~= b.rank) then
        return a.rank > b.rank
    elseif (a.rarity ~= b.rarity) then
        return a.rarity > b.rarity
    elseif (a.level ~= b.level) then
        return a.level > b.level
    else
        return a.cfgId < b.cfgId
    end
end

function UIPetCarryMediator:ShowHeroModel()
	local heroCfg = ConfigRefer.Heroes:Find(self.heroId)
    local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
	local modelPath = ConfigRefer.ArtResource:Find(resCell:ShowModel()):Path()
	local petScale = ConfigRefer.PetType:Find(self.petCfg:Type()):HeroScale()
	if (not petScale or petScale <= 0) then petScale = 1 end
	self.ui3dModel:SetupOtherModel(modelPath, function()
		local scale =  resCell:ModelScalePet()
		if (not scale or scale <= 0) then scale = 1 end
		self.ui3dModel.curOtherModelGo.transform.localScale = CS.UnityEngine.Vector3.one * scale * petScale
		self.ui3dModel.curOtherModelGo.transform.localPosition = CS.UnityEngine.Vector3(resCell:ModelPositionPet(1), resCell:ModelPositionPet(2), resCell:ModelPositionPet(3))
	end)
end

function UIPetCarryMediator:Play3DModelBgAnim()
	if (not self.ui3dModel) then return end
	local anim = self.ui3dModel.curEnvGo.transform:Find("vx_w_hero_main/all/vx_ui_hero_main"):GetComponent(typeof(CS.UnityEngine.Animation))
	if (anim) then
		if (not self.bgAnimOpened) then
			anim:Play("anim_vx_w_hero_main_open")
			self.bgAnimOpened = true
		else
			anim:Play("anim_vx_w_hero_main_loop")
		end
	end
end

function UIPetCarryMediator:Get3DCameraSettings()
    local cameraSetting = {}
    for i = 1, 2 do
        local setting = {}
        setting.fov = 3
        setting.nearCp = 40
        setting.farCp = 48
		setting.localPos = CS.UnityEngine.Vector3(0.065423, 3.751282, -43.87342)
        cameraSetting[i] = setting
    end
    return cameraSetting
end

function UIPetCarryMediator:OnBtnUpgradeClicked(args)
	if self.selectedId then
		g_Game.UIManager:Open(UIMediatorNames.UIPetMediator, {hideRelease = true, petId = self.selectedId})
	else
		g_Game.UIManager:Open(UIMediatorNames.UIPetMediator, {hideRelease = true})
	end
end

function UIPetCarryMediator:OnBtnCarryClicked(args)
	local herolist = self:GetAllPetTypeLinkHerosById(self.heroId, self.selectedType, self.isPvP) or {}
	if (#herolist > 1 or (#herolist > 0 and not table.ContainsValue(herolist, self.heroId))) and not self:CheckIsReplacSameTeamPet(self.heroId, self.selectedId, self.isPvP) then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("hero_pet_occupy_squad"))
		return
	end
	local callBack = function(replaceHeroId)
			if self.onPetModified then
				if replaceHeroId and replaceHeroId > 0 then
					if self.petLinkInfo then
						self.petLinkInfo[replaceHeroId] = 0
					end
					self.onPetModified(replaceHeroId, 0)
				end
				self.petLinkInfo[self.heroId] = self.selectedId
				self.onPetModified(self.heroId, self.selectedId)
			end
			self:RefreshPetList()
			self:RefreshHeroLeftHead()
		if self.troopHeroList and #self.troopHeroList > 0 then
			local canClose = true
			for _, heroCfgId in ipairs(self.troopHeroList) do
				local linkPetCompId = self.petLinkInfo[heroCfgId]
				if not linkPetCompId or linkPetCompId <= 0 then
					canClose = false
					break
				end
			end
			if canClose then
				self:CloseSelf()
			end
		end
	end

	local city = ModuleRefer.CityModule:GetMyCity()
	local selectPets = {}
	selectPets[self.selectedId] = true
	local flag, names, _ = city.petManager:ContainsOtherWorkPet(selectPets, 0)
	if flag then
		local petName = ModuleRefer.PetModule:GetPetName(self.selectedId)
		local dialogParam = {}
		dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
		dialogParam.title = I18N.Get(require("CityPetI18N").UITitle_ConfirmAssign)
		dialogParam.content = I18N.GetWithParams("mention_popup_pet_remove", petName, names)
		dialogParam.onConfirm = function()
			city.petManager:RequestRemovePet(self.selectedId, city.petManager:GetFurnitureIdByPetId(self.selectedId), self.btnCarry.transform,
			function(_, success)
				if success then
					callBack(-1)
				end
			end)
			return true
		end
		g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
		return
	end

	local heroId = self:GetPetLinkHero(self.selectedId, self.isPvP)
	if heroId and heroId > 0 then
		local preset, _, presets = ModuleRefer.TroopModule:GetPresetData(self.troopIndex)
		local status
		---@type number, wds.TroopPreset
		for _, p in ipairs(presets.Presets) do
			for _, hero in ipairs(p.Heroes) do
				if hero.HeroCfgID == heroId then
					status = p.Status
					break
				end
			end
		end
		if status and (status ~= wds.TroopPresetStatus.TroopPresetInHome and status ~= wds.TroopPresetStatus.TroopPresetIdle) then
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("troop_no_free"))
			return
		end
		local dialogParam = {}
		dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
		dialogParam.title = I18N.Get("hero_pet_carry")
		dialogParam.content = I18N.GetWithParams("hero_pet_occupy_1", I18N.Get(ConfigRefer.Heroes:Find(heroId):Name()))
		dialogParam.onConfirm = function()
			callBack(heroId)
			return true
		end
		g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
		return
	end
	callBack(-1)
end

function UIPetCarryMediator:OnBtnCancleClicked(args)
	if self.onPetModified then
		self.onPetModified(self.heroId, 0)
	end
	if self.petLinkInfo then
		self.petLinkInfo[self.heroId] = 0
	end
	self:RefreshPetList()
	self:RefreshHeroLeftHead()
end

---@param petCompId number
---@param isPvP boolean
function UIPetCarryMediator:GetPetLinkHero(petCompId, isPvP)
	if self.petLinkInfo then
		for heroCfgID, linkedPetCompId in pairs(self.petLinkInfo) do
			if linkedPetCompId == petCompId then
				return heroCfgID
			end
		end
		return nil
	end
	return ModuleRefer.PetModule:GetPetLinkHero(petCompId, isPvP)
end

---@param heroId number
---@param selectedType number @PetType
---@param isPvP boolean
function UIPetCarryMediator:GetAllPetTypeLinkHerosById(heroId, selectedType, isPvP)
	if self.petLinkInfo and self.troopHeroList then
		local retList = {}
		local index = 1
		for _, heroCfgId in ipairs(self.troopHeroList) do
			local linkPetCompId = self.petLinkInfo[heroCfgId]
			if linkPetCompId and linkPetCompId > 0 then
				local pet = ModuleRefer.PetModule:GetPetByID(linkPetCompId)
				local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
				if petCfg and petCfg:Type() == selectedType then
					retList[index] = heroCfgId
					index = index + 1
				end
			end
		end
		if index > 1 then
			return retList
		else
			return nil
		end
	end
	return ModuleRefer.PetModule:GetAllPetTypeLinkHerosById(heroId, selectedType, isPvP)
end

---@param troopHeroList number[]
---@param petType number @PetType
---@param isPvP boolean
function UIPetCarryMediator:GetAllPetTypeLinkHerosByList(troopHeroList, petType, isPvP)
	if self.petLinkInfo and troopHeroList then
		local retList = {}
		local index = 1
		for _, heroCfgId in ipairs(troopHeroList) do
			local linkPetCompId = self.petLinkInfo[heroCfgId]
			if linkPetCompId and linkPetCompId > 0 then
				local pet = ModuleRefer.PetModule:GetPetByID(linkPetCompId)
				local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
				if petCfg and petCfg:Type() == petType then
					retList[index] = heroCfgId
					index = index + 1
				end
			end
		end
		if index > 1 then
			return retList
		else
			return nil
		end
	end
	return ModuleRefer.PetModule:GetAllPetTypeLinkHerosByList(troopHeroList, petType, isPvP)
end

---@param heroCfgId number
---@param selectedPetCompId number
---@param isPvP boolean
function UIPetCarryMediator:CheckIsReplacSameTeamPet(heroCfgId, selectedPetCompId, isPvP)
	if self.petLinkInfo and self.troopHeroList then
		for _, id in ipairs(self.troopHeroList) do
			local linkPetCompId = self.petLinkInfo[id]
			if linkPetCompId == selectedPetCompId then
				return true
			end
		end
		return false
	end

	return ModuleRefer.PetModule:CheckIsReplacSameTeamPet(heroCfgId, selectedPetCompId, isPvP)
end

---@param heroCfgId number
---@param isPvP boolean
function UIPetCarryMediator:GetHeroLinkPet(heroCfgId, isPvP)
	if self.petLinkInfo then
		return self.petLinkInfo[heroCfgId]
	end
	return ModuleRefer.HeroModule:GetHeroLinkPet(heroCfgId, isPvP)
end



return UIPetCarryMediator
