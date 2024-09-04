local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceTerritoryMainSummaryTitleCellData = require("AllianceTerritoryMainSummaryTitleCellData")
local AllianceTerritoryMainSummaryFacilityCell = require("AllianceTerritoryMainSummaryFacilityCell")

local ConfigRefer = require("ConfigRefer")
local NumberFormatter = require("NumberFormatter")
local MapBuildingSubType = require("MapBuildingSubType")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local AllianceBehemoth = require("AllianceBehemoth")
local MapBuildingType = require("MapBuildingType")
local VillageSubType = require("VillageSubType")
local DBEntityType = require("DBEntityType")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceTerritoryMainSummaryTab:BaseUIComponent
---@field new fun():AllianceTerritoryMainSummaryTab
---@field super BaseUIComponent
local AllianceTerritoryMainSummaryTab = class('AllianceTerritoryMainSummaryTab', BaseUIComponent)

function AllianceTerritoryMainSummaryTab:ctor()
    AllianceTerritoryMainSummaryTab.super.ctor(self)
    self._tableCellsData = {}
    ---@type AllianceTerritoryMainMediatorDataContext
    self._data = nil
end

function AllianceTerritoryMainSummaryTab:OnCreate(param)
    self._p_table_summary = self:TableViewPro("p_table_summary")
end

---@param data AllianceTerritoryMainMediatorDataContext
function AllianceTerritoryMainSummaryTab:OnFeedData(data)
    self._data = data
    if self._isShow then
        self:GenerateTableData()
    end
end

function AllianceTerritoryMainSummaryTab:OnShow(param)
    self:GenerateTableData()
    self._isShow = true
end

function AllianceTerritoryMainSummaryTab:OnHide(param)
    self._isShow = false
    self._p_table_summary:Clear()
end

function AllianceTerritoryMainSummaryTab:GenerateTableData()
    self._p_table_summary:Clear()

    self._p_table_summary:AppendData(self._data.faction, 4)
    self._p_table_summary:AppendData({}, 7)
    self:BuildResBuffCells()
    self:BuildBehemothCells()
    self:BuildCitiesCells()
    self:BuildSettlementCells()
    ---@type AllianceTerritoryMainSummaryFacilityCell
    local facilityCell = AllianceTerritoryMainSummaryFacilityCell.new()
    facilityCell.defenceTowerCount = self._data.militaryBuildingsCount[FlexibleMapBuildingType.DefenseTower] or 0
    facilityCell.crystalTowerCount = self._data.militaryBuildingsCount[FlexibleMapBuildingType.EnergyTower] or 0
    facilityCell.defenceTowerCountMax = self._data.defenceTowerMax
    facilityCell.crystalTowerCountMax = self._data.crystalTowerMax
    facilityCell.__prefabIndex = 3
    local facilityData = AllianceTerritoryMainSummaryTitleCellData.new({allowShowExpandBtn = true}, true, nil)
    facilityData.titleContent = I18N.GetWithParams("alliance_territory_5", tostring(facilityCell.defenceTowerCount + facilityCell.crystalTowerCount))
    local cellData = {facilityCell}
    table.addrange(facilityData.__childCellsData, cellData)
    self._p_table_summary:AppendData(facilityData, 0)
    self._p_table_summary:AppendData(facilityCell, 3)
    self._p_table_summary.ScrollRect.scrollRect.vertical = true
end

function AllianceTerritoryMainSummaryTab:BuildResBuffCells()
    local bufferTitle = AllianceTerritoryMainSummaryTitleCellData.new({}, true, nil, true)
    bufferTitle.titleContent = I18N.Get("alliance_bj_jiacheng")
    self._p_table_summary:AppendData(bufferTitle, 0)
    self._p_table_summary:AppendData({}, 6)
end

---@param a AllianceBehemoth
---@param b AllianceBehemoth
function AllianceTerritoryMainSummaryTab.SortCells(a, b)
	local configA = a:GetRefKMonsterDataConfig(1)
	local configB = b:GetRefKMonsterDataConfig(1)
	local ret = configA:Level() - configB:Level()
	if ret == 0 then
		return configA:Id() < configB:Id()
	end
	return ret < 0
end

function AllianceTerritoryMainSummaryTab:BuildBehemothCells()
	---@type AllianceBehemoth[]
	local toAddCells = {}
	local ownBehemoths = {}
	local has = 0
    local deviceDefaultGroupId = {}
    for _, value in ConfigRefer.FlexibleMapBuilding:ipairs() do
        if value:Type() == FlexibleMapBuildingType.BehemothDevice then
            local deviceConfig = ConfigRefer.BehemothDevice:Find(value:BehemothDeviceConfig())
            if deviceConfig and deviceConfig:InstanceMonsterLength() > 0 then
                local id = ModuleRefer.AllianceModule.Behemoth:GetBehemothGroupId(deviceConfig:InstanceMonster(1))
                deviceDefaultGroupId[id] = true
            end
        end
    end
	for _, v in ModuleRefer.AllianceModule.Behemoth:PairsOfBehemoths() do
		ownBehemoths[v:GetBehemothGroupId()] = true
		if not v:IsDeviceDefault() then
			table.insert(toAddCells, v)
			has = has + 1
		end
	end
	for _, v in ConfigRefer.FixedMapBuilding:ipairs() do
		if v:Type() == MapBuildingType.BehemothCage then
			local cageConfig = ConfigRefer.BehemothCage:Find(v:BehemothCageConfig())
            if cageConfig then
                local behemoth = AllianceBehemoth.FromCageBuildingConfig(cageConfig, v)
                if not ownBehemoths[behemoth:GetBehemothGroupId()] and not deviceDefaultGroupId[behemoth:GetBehemothGroupId()] then
                    table.insert(toAddCells, behemoth)
                end
            end
		end
	end
	table.sort(toAddCells, AllianceTerritoryMainSummaryTab.SortCells)
    local behemothData = AllianceTerritoryMainSummaryTitleCellData.new({}, true, nil)
    behemothData.titleContent = I18N.GetWithParams("alliance_behemoth_territory_title1", has, #toAddCells)
    behemothData.detailBtn = function(transform)
        ---@type TextToastMediatorParameter
        local param = {}
        param.clickTransform = transform
        param.content = I18N.Get("alliance_territory_overview_behemothcave_tips")
        ModuleRefer.ToastModule:ShowTextToast(param)
    end
    self._p_table_summary:AppendData(behemothData, 0)
	local rowCount = math.ceil(#toAddCells / 3)
	for i = 0, rowCount - 1 do
		local data = {}
		for j = 1, 3 do
			data[j] = toAddCells[i*3+j]
		end
		self._p_table_summary:AppendData(data, 8)
	end
end

function AllianceTerritoryMainSummaryTab:BuildCitiesCells()
    local cityCount = 0
    ---@type AllianceTerritoryMainSummaryCityTitleCellData
    local titleRowData = {}
    titleRowData.subType = {}
    titleRowData.hasCount = {}
    titleRowData.subType[1] = VillageSubType.Economy
    titleRowData.subType[2] = VillageSubType.PetZoo
    titleRowData.subType[3] = VillageSubType.Military
    titleRowData.subType[4] = VillageSubType.Gate
    titleRowData.hasCount[1] = 0
    titleRowData.hasCount[2] = 0
    titleRowData.hasCount[3] = 0
    titleRowData.hasCount[4] = 0
    titleRowData.__prefabIndex = 9
    local hasMap = {}
    local gridConfig = ConfigRefer.VillageCityDisplayGrid
    local buildings = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    for i, v in pairs(buildings) do
        if v.EntityTypeHash == DBEntityType.Village then
            local config = ConfigRefer.FixedMapBuilding:Find(v.ConfigId)
            if config:SubType() == MapBuildingSubType.City then
                cityCount = cityCount + 1
                for j = 1, #titleRowData.subType do
                    if config:VillageSub() == titleRowData.subType[j] then
                        titleRowData.hasCount[j] = titleRowData.hasCount[j] + 1
                        hasMap[j] = hasMap[j] or {}
                        hasMap[j][config:Level()] = true
                    end
                end
            end
        end
    end
    local childRows = {titleRowData}
    for _, v in gridConfig:ipairs() do
        ---@type AllianceTerritoryMainSummaryCityCellData
        local rowData = {}
        rowData.__prefabIndex = 10
        local unlockId = v:AttackSystemSwitch()
        if unlockId ~= 0 then
            if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockId) then
                local unlockConfig = ConfigRefer.SystemEntry:Find(unlockId)
                rowData.unlockIndex = unlockConfig:UnlockWorldStageIndex()
            end
        end
        rowData.lvs = {}
        rowData.has = {}
        rowData.mapBuildingSubType = {MapBuildingSubType.City,MapBuildingSubType.City,MapBuildingSubType.City,MapBuildingSubType.City}
        rowData.villageSubType = {VillageSubType.Economy,VillageSubType.PetZoo,VillageSubType.Military,VillageSubType.Gate}
        rowData.lvs[1] = v:EconomyTypeLevel()
        rowData.lvs[2] = v:PetZooTypeLevel()
        rowData.lvs[3] = v:MilitaryTypeLevel()
        rowData.lvs[4] = v:GateTypeLevel()
        for j = 1, 4 do
            if rowData.lvs[j] > 0 then
                if hasMap[j] and hasMap[j][rowData.lvs[j]] then
                    rowData.has[j] = true
                end
            end
        end
        table.insert(childRows, rowData)
    end
    local cityData = AllianceTerritoryMainSummaryTitleCellData.new({}, true, nil)
    cityData.titleContent = I18N.GetWithParams("alliance_territory_4", cityCount)
    cityData.detailBtn = function(trans)
        ---@type TextToastMediatorParameter
        local param = {}
        param.clickTransform = trans
        param.content = I18N.Get("alliance_territory_overview_city_tips")
        ModuleRefer.ToastModule:ShowTextToast(param)
    end
    self._p_table_summary:AppendData(cityData, 0)
    for i, cellData in ipairs(childRows) do
        self._p_table_summary:AppendData(cellData, cellData.__prefabIndex)
    end
end

function AllianceTerritoryMainSummaryTab:BuildSettlementCells()
    local strongHoldCount = 0
    local hasCount = {}
    local unlockLvMap = {}
    local buildings = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    for _, v in pairs(buildings) do
        if v.EntityTypeHash == DBEntityType.Village then
            local config = ConfigRefer.FixedMapBuilding:Find(v.ConfigId)
            if config:SubType() == MapBuildingSubType.Stronghold then
                strongHoldCount = strongHoldCount + 1
                local level = config:Level()
                hasCount[level] = (hasCount[level] or 0) + 1
                local unlockId = config:AttackSystemSwitch()
                if unlockId ~= 0 then
                    unlockLvMap[level] = unlockId
                end
            end
        end
    end
    local strongholdCell = {}
    for i = 0, 2 do
        ---@type AllianceTerritoryMainSummarySettlementCellData
        local rowData = {}
        rowData.lvs = {}
        rowData.hasCount = {}
        rowData.__prefabIndex = 11
        for j = 1, 4 do
            local lv = i*4 + j
            rowData.lvs[j] = lv
            rowData.hasCount[j] = hasCount[lv] or 0
        end
        if unlockLvMap[rowData.lvs[1]] then
            if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockLvMap[rowData.lvs[1]]) then
                rowData.unlockIndex = ConfigRefer.SystemEntry:Find(unlockLvMap[rowData.lvs[1]]):UnlockWorldStageIndex()
            end
        end
        table.insert(strongholdCell, rowData)
    end
    local strongHoldData = AllianceTerritoryMainSummaryTitleCellData.new({}, true, nil)
    strongHoldData.titleContent = I18N.GetWithParams("alliance_overview_settlement_1", strongHoldCount)
    strongHoldData.detailBtn = function(trans)
        ---@type TextToastMediatorParameter
        local param = {}
        param.clickTransform = trans
        param.content = I18N.Get("alliance_territory_overview_settlement_tips")
        ModuleRefer.ToastModule:ShowTextToast(param)
    end
    self._p_table_summary:AppendData(strongHoldData, 0)
    for i, v in ipairs(strongholdCell) do
        self._p_table_summary:AppendData(v, v.__prefabIndex)
    end
end

return AllianceTerritoryMainSummaryTab
