--- scene:scene_league_popup_transform

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local VillageSubType = require("VillageSubType")
local DBEntityType = require("DBEntityType")
local MapBuildingSubType = require("MapBuildingSubType")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local UIMediatorNames = require("UIMediatorNames")
local UIHelper = require("UIHelper")
local NumberFormatter = require("NumberFormatter")
local TimeFormatter = require("TimeFormatter")
local KingdomMapUtils = require("KingdomMapUtils")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceCenterTransformMediatorParameter
---@field trySelectVillageId number

---@class AllianceCenterTransformMediator:BaseUIMediator
---@field new fun():AllianceCenterTransformMediator
---@field super BaseUIMediator
local AllianceCenterTransformMediator = class('AllianceCenterTransformMediator', BaseUIMediator)

function AllianceCenterTransformMediator:ctor()
    AllianceCenterTransformMediator.super.ctor(self)
    ---@type AllianceCenterTransformListCityCellData
    self._selected = nil
	---@type CS.DragonReborn.UI.LuaBaseComponent[]
	self._costCells = {}
	---@type CS.DragonReborn.UI.LuaBaseComponent[]
	self._conditionCells = {}
	self._noTransformReason = 0
	self._entrySelectVillageId = nil
end

function AllianceCenterTransformMediator:OnCreate(param)
    ---@see CommonPopupBackLargeComponent
    self._child_popup_base_l = self:LuaBaseComponent("child_popup_base_l")
    
    self._p_right_group = self:GameObject("p_right_group")
    self._p_left_group = self:GameObject("p_left_group")
    
    self._p_text_title_addtion = self:Text("p_text_title_addtion", "")
    
    self._p_table_addtion = self:TableViewPro("p_table_addtion")
    self._p_icon_territory = self:Image("p_icon_territory")
    self._p_btn_click_go = self:Button("p_btn_click_go", Delegate.GetOrCreate(self, self.OnClickGoTo))
    self._p_text_position = self:Text("p_text_position")
    self._p_table_city = self:TableViewPro("p_table_city")
    self._p_group_nomal = self:GameObject("p_group_nomal")
	self._p_title_cost = self:Text("p_text_cost", "alliance_center_siteselection_cost")
	
	---@see AllianceCenterTransformCostCell
	self._p_item_cost = self:LuaBaseComponent("p_item_cost")
	self._p_item_cost:SetVisible(false)
	
	self._p_text_condition = self:Text("p_text_condition", "alliance_center_siteselection_condition")
	---@see AllianceCenterTransformConditionCell
	self._p_condition = self:LuaBaseComponent("p_condition")
	self._p_condition:SetVisible(false)
	---@type CommonTimer
	self._child_time = self:LuaObject("child_time")

	---@type BistateButtonSmall
    self._child_comp_btn_b_s = self:LuaObject("child_comp_btn_b_s")
    self._p_group_now = self:GameObject("p_group_now")
    self._p_text_title_addtion_1 = self:Text("p_text_title_addtion_1", "alliance_center_siteselection_current_tips")
end

---@param param AllianceCenterTransformMediatorParameter|nil
function AllianceCenterTransformMediator:OnOpened(param)
	---@type CommonBackButtonData
	local data = {}
	data.title = I18N.Get("alliance_center_siteselection_title")
	self._child_popup_base_l:FeedData(data)
    self._p_table_city:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelected))
	self._entrySelectVillageId = param and param.trySelectVillageId
    self:GenerateTable()
end

function AllianceCenterTransformMediator:OnClose(data)
    self._p_table_city:SetSelectedDataChanged(nil)
end

function AllianceCenterTransformMediator:OnClickGoTo()
    if not self._selected then return end
    AllianceWarTabHelper.GoToCoord(self._selected.building.Pos.X, self._selected.building.Pos.Y)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.AllianceTerritoryMainMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.AllianceMainMediator)
    self:CloseSelf()
end

function AllianceCenterTransformMediator:SetGatherPoint(pos)
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(pos)
    ModuleRefer.AllianceModule:SetAllianceGatherPoint({X = tileX, Z = tileZ})
end

function AllianceCenterTransformMediator:GenerateTable()
    self._p_table_city:UnSelectAll()
    self._p_table_city:Clear()
    ---@type AllianceCenterTransformListCityCellData[]
    local cities = {}
    ---@type AllianceCenterTransformListCityCellData[]
    local others = {}
    local mapBuilding = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    for _, v in pairs(mapBuilding) do
        if v.EntityTypeHash == DBEntityType.Village then
            local config = ConfigRefer.FixedMapBuilding:Find(v.ConfigId)
            if config:SubType() == MapBuildingSubType.Stronghold then
                ---@type AllianceCenterTransformListCityCellData
                local data = {}
                data.buildingConfig = config
                data.building = v
                table.insert(others, data)
            elseif config:SubType() == MapBuildingSubType.City then
                ---@type AllianceCenterTransformListCityCellData
                local data = {}
                data.buildingConfig = config
                data.building = v
                table.insert(cities, data)
            end
        end
    end
    table.sort(cities, AllianceCenterTransformMediator.SortCity)
    table.sort(others, AllianceCenterTransformMediator.SortCity)
    self._p_table_city:AppendData(I18N.Get("alliance_bj_town"), 0)
    local selectedFirst = nil
	local entrySelected = nil
    if #cities > 0 then
        for i, v in ipairs(cities) do
			if self._entrySelectVillageId and v.building.EntityID == self._entrySelectVillageId then
				entrySelected = v
			end
            if not selectedFirst then
                selectedFirst = v
            end
            self._p_table_city:AppendData(v, 1)
        end
    else
        self._p_table_city:AppendData(I18N.Get("alliance_center_siteselection_nonecity"), 2)
    end
    self._p_table_city:AppendData(I18N.Get("alliance_bj_judian"), 0)
    if #others > 0 then
        for i, v in ipairs(others) do
			if self._entrySelectVillageId and v.building.EntityID == self._entrySelectVillageId then
				entrySelected = v
			end
            if not selectedFirst then
                selectedFirst = v
            end
            self._p_table_city:AppendData(v, 1)
        end
    else
        self._p_table_city:AppendData(I18N.Get("alliance_center_siteselection_nonesettlement"), 2)
    end
	if entrySelected then
		self._p_table_city:SetToggleSelect(entrySelected)
		self._p_table_city:SetDataFocus(entrySelected, 0,0, CS.TableViewPro.MoveSpeed.Fast)
	elseif selectedFirst then
        self._p_table_city:SetToggleSelect(selectedFirst)
    end
end

function AllianceCenterTransformMediator:RefreshRightGroupBySelected()
    if not self._selected then
        self._p_right_group:SetVisible(false)
        return
    end
    self._p_right_group:SetVisible(true)
    self._p_table_addtion:Clear()
    g_Game.SpriteManager:LoadSprite(self._selected.buildingConfig:Image(), self._p_icon_territory)
    self._p_text_position.text = ("X:%d,Y:%d"):format(math.floor(self._selected.building.Pos.X + 0.5), math.floor(self._selected.building.Pos.Y + 0.5))
    if self._selected.building.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
        self._p_group_now:SetVisible(true)
        self._p_group_nomal:SetVisible(false)
		self:RefreshUpgradeAddition()
    elseif self._selected.building.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusNone then
        self._p_group_now:SetVisible(false)
        self._p_group_nomal:SetVisible(true)
		self:RefreshUpgradeAddition()
		self:RefreshToTransform()
    else
        self._p_group_now:SetVisible(false)
        self._p_group_nomal:SetVisible(false)
    end
end

function AllianceCenterTransformMediator:RefreshUpgradeAddition()
	self._p_table_addtion:Clear()
	local allianceAttr = nil
	local currentCenter = ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillageId()
	if currentCenter then
		local mapBuilding = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
		local oldBuilding = mapBuilding[currentCenter]
		local oldConfig = ConfigRefer.FixedMapBuilding:Find(oldBuilding.ConfigId)
		allianceAttr = ConfigRefer.AttrGroup:Find(ConfigRefer.AllianceCenter:Find(oldConfig:BuildAllianceCenter()):AllianceAttrGroup())
	end
	local centerConfig = ConfigRefer.AllianceCenter:Find(self._selected.buildingConfig:BuildAllianceCenter())
	--local allianceAttr = ConfigRefer.AttrGroup:Find(self._selected.buildingConfig:AllianceAttrGroup())
	local addAttrGroup = ConfigRefer.AttrGroup:Find(centerConfig:AllianceAttrGroup())
	if not addAttrGroup or addAttrGroup:AttrListLength() <= 0 then return end
	local attrMap = {}
	---@type {prefabIdx:number, cellData:{strLeft:string,strRight:string,icon:string,strRightOrigin:string}}[]
	local allianceGainAttr = {}
	if allianceAttr then
		for i = 1,  allianceAttr:AttrListLength() do
			local attrTypeAndValue = allianceAttr:AttrList(i)
			attrMap[attrTypeAndValue:TypeId()] = attrTypeAndValue:Value()
		end
	end
	for i = 1,  addAttrGroup:AttrListLength() do
		local attrTypeAndValue = addAttrGroup:AttrList(i)
		local oldValue = attrMap[attrTypeAndValue:TypeId()] or 0
		ModuleRefer.VillageModule.ParseChangeAttrInfo(oldValue, attrTypeAndValue, allianceGainAttr, true)
		local v = allianceGainAttr[1]
		allianceGainAttr[1] = nil
		self._p_table_addtion:AppendData(v)
	end
end

function AllianceCenterTransformMediator:RefreshCost()
	local centerConfig = ConfigRefer.AllianceCenter:Find(self._selected.buildingConfig:BuildAllianceCenter())
	local costAllianceCurrencyCount = centerConfig:BuildCostItemLength()
	local cellsCount = #self._costCells
	for i = cellsCount, costAllianceCurrencyCount + 1, -1 do
		self._costCells[i]:SetVisible(false)
	end
	self._p_item_cost:SetVisible(true)
	for i = cellsCount + 1, costAllianceCurrencyCount do
		local cell = UIHelper.DuplicateUIComponent(self._p_item_cost, self._p_item_cost.transform.parent)
		self._costCells[i] = cell
	end
	self._p_item_cost:SetVisible(false)
	local lake = false
	for i = 1, costAllianceCurrencyCount do
		self._costCells[i]:SetVisible(true)
		---@type AllianceCenterTransformCostCellData
		local cellData = {}
		local info = centerConfig:BuildCostItem(i)
		local has = ModuleRefer.AllianceModule:GetAllianceCurrencyByType(info:Type())
		local config = ModuleRefer.AllianceModule:GetAllianceCurrencyConfigByType(info:Type())
		cellData.icon = config and config:Icon() or string.Empty
		local need = info:Count()
		if has < need then
			lake = true
			cellData.numbStr = ("<color=red>%s</color>/%s"):format(NumberFormatter.NumberAbbr(has, true), NumberFormatter.NumberAbbr(need, true))
		else
			cellData.numbStr = ("<color=green>%s</color>/%s"):format(NumberFormatter.NumberAbbr(has, true), NumberFormatter.NumberAbbr(need, true))
		end
		self._costCells[i]:FeedData(cellData)
	end
	---@type CommonTimerData
	local timeData = {}
	timeData.fixTime = centerConfig:BuildValue() / centerConfig:BuildSpeedValue() * centerConfig:BuildSpeedTime()
	self._child_time:FeedData(timeData)
	if lake then
		self._noTransformReason = self._noTransformReason | (1 << 2)
	else
		self._noTransformReason = self._noTransformReason & (~(1 << 2))
	end
end

function AllianceCenterTransformMediator:RefreshCondition()
	local cellsCount = #self._conditionCells
	for i = cellsCount, 3, -1 do
		self._conditionCells[i]:SetVisible(false)
	end
	self._p_condition:SetVisible(true)
	for i = cellsCount + 1, 2 do
		local cell = UIHelper.DuplicateUIComponent(self._p_condition, self._p_condition.transform.parent)
		self._conditionCells[i] = cell
	end
	self._p_condition:SetVisible(false)

	self._conditionCells[1]:SetVisible(true)
	---@type AllianceCenterTransformConditionCellData
	local condition1 = {}
	condition1.conditionText = I18N.Get("alliance_center_siteselection_condition1")
	condition1.isFinished = true
	self._conditionCells[1]:FeedData(condition1)
	if not condition1.isFinished then
		self._noTransformReason = self._noTransformReason | (1 << 0)
	end
	
	self._conditionCells[2]:SetVisible(true)
	local ownWar = ModuleRefer.AllianceModule:GetMyAllianceOwnVillageWar()
	---@type AllianceCenterTransformConditionCellData
	local condition2 = {}
	condition2.conditionText = I18N.Get("alliance_center_siteselection_condition2")
	condition2.isFinished = table.isNilOrZeroNums(ownWar[self._selected.building.EntityID] and ownWar[self._selected.building.EntityID].WarInfo)
	self._conditionCells[2]:FeedData(condition2)
	if not condition2.isFinished then
		self._noTransformReason = self._noTransformReason | (1 << 1)
	end
end

function AllianceCenterTransformMediator:RefreshToTransform()
	self._noTransformReason = 0
	self:RefreshCost()
	self:RefreshCondition()
	---@type BistateButtonSmallParam
	local data = {}
	data.buttonText = I18N.Get("alliance_center_siteselection_buildbtn")
	data.onClick = Delegate.GetOrCreate(self, self.OnClickTransformBtn)
	data.disableClick = function()
		if (self._noTransformReason & (1 << 0)) ~= 0 then
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_center_siteselection_cantbuild_tips1"))
		elseif (self._noTransformReason & (1 << 1)) ~= 0 then
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_center_siteselection_cantbuild_tips2"))
		elseif (self._noTransformReason & (1 << 2)) ~= 0 then
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_build_ziyuanbuzu"))
		end
	end
	self._child_comp_btn_b_s:FeedData(data)
	self._child_comp_btn_b_s:SetEnabled(self._noTransformReason == 0)
end

function AllianceCenterTransformMediator:OnClickTransformBtn()
	if not self._selected then return end
	local cdLeftTIme = ModuleRefer.VillageModule:GetTransformAllianceCenterCdEndTime() - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
	if cdLeftTIme > 0 then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_center_cooldown_countdown", TimeFormatter.SimpleFormatTime(cdLeftTIme)))
		return
	end
    
    local setGatherPoint
	---@type CommonConfirmPopupMediatorParameter
	local param = {}
	param.title = I18N.Get("alliance_center_siteselection_makesure_title")
    param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.Toggle
	param.content = I18N.GetWithParams("alliance_center_siteselection_makesure_content", ("Lv.%s %s"):format(self._selected.buildingConfig:Level(), I18N.Get(self._selected.buildingConfig:Name())))
	param.confirmLabel = I18N.Get("confirm")
	param.cancelLabel = I18N.Get("cancle")
	param.onConfirm = function()
        local village = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
		if not village then
			ModuleRefer.AllianceModule:TransformAllianceCenter(nil, self._selected.building.EntityID, function(cmd, isSuccess, rsp)
				if isSuccess then
                    if setGatherPoint then
                        self:SetGatherPoint(self._selected.building.Pos)
                    end
					self:OnClickGoTo()
				end
			end)
		elseif village.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
			ModuleRefer.AllianceModule:ChangeAllianceCenter(nil, self._selected.building.EntityID, function(cmd, isSuccess, rsp)
				if isSuccess then
                    if setGatherPoint then
                        self:SetGatherPoint(self._selected.building.Pos)
                    end
                    self:OnClickGoTo()
				end
			end)
		end
		return true
	end
    param.toggle = true
    param.toggleDescribe = I18N.Get("alliance_gathering_point_3")
    param.toggleClick = function(context, check)
        setGatherPoint = check
        return check
    end
	g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
end

---@param current AllianceCenterTransformListCityCellData
function AllianceCenterTransformMediator:OnSelected(old, current)
   if self._selected == current then return end
    self._selected = current
    self:RefreshRightGroupBySelected()
end

---@param subType number @VillageSubType
---@return number
function AllianceCenterTransformMediator.GetSubTypeOrder(subType)
    if subType == VillageSubType.Military then
        return 0
    elseif subType == VillageSubType.PetZoo then
        return 1
    elseif subType == VillageSubType.Economy then
        return 2
    end
    return 999
end

---@param a AllianceCenterTransformListCityCellData
---@param b AllianceCenterTransformListCityCellData
---@return boolean
function AllianceCenterTransformMediator.SortCity(a, b)
    local typeA = a.buildingConfig:VillageSub()
    local typeB = b.buildingConfig:VillageSub()
    local ret = AllianceCenterTransformMediator.GetSubTypeOrder(typeA) - AllianceCenterTransformMediator.GetSubTypeOrder(typeB)
	if ret == 0 then
		return a.buildingConfig:Level() > b.buildingConfig:Level()
	end
	return ret < 0
end

return AllianceCenterTransformMediator
