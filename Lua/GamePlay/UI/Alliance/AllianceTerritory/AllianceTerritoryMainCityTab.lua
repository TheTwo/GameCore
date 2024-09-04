local I18N = require("I18N")
local AllianceTerritoryMainCityCategoryCellData = require("AllianceTerritoryMainCityCategoryCellData")
local AllianceTerritoryBehemothCategoryCellData = require("AllianceTerritoryBehemothCategoryCellData")
local MapBuildingSubType = require("MapBuildingSubType")
local ModuleRefer = require("ModuleRefer")
local AllianceAuthorityItem = require("AllianceAuthorityItem")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceTerritoryMainCityTab:BaseUIComponent
---@field new fun():AllianceTerritoryMainCityTab
---@field super BaseUIComponent
local AllianceTerritoryMainCityTab = class('AllianceTerritoryMainCityTab', BaseUIComponent)

function AllianceTerritoryMainCityTab:ctor()
    AllianceTerritoryMainCityTab.super.ctor(self)
    ---@type AllianceTerritoryMainMediatorDataContext
    self._data = nil
end

function AllianceTerritoryMainCityTab:OnCreate(param)
    self._p_table_cities = self:TableViewPro("p_table_cities")
end

---@param data AllianceTerritoryMainMediatorDataContext
function AllianceTerritoryMainCityTab:OnFeedData(data)
    self._data = data
    if self._isShow then
        self:Refresh()
    end
end

function AllianceTerritoryMainCityTab:OnShow(param)
    self:Refresh()
    self._isShow = true
end

function AllianceTerritoryMainCityTab:Refresh()
    self._p_table_cities:Clear()
	---@type AllianceBehemoth[]
	local cages = {}
	for _, behemoth in ModuleRefer.AllianceModule.Behemoth:PairsOfBehemoths() do
		if not behemoth:IsDeviceDefault() then
			table.insert(cages, behemoth)
		end
	end
    if #self._data.sortedCities <= 0 and #cages <= 0 then
        ---@type AllianceTerritoryMainMediator
        local mediator = self:GetParentBaseUIMediator()
        if mediator.SetShowNoContentTip then
            mediator:SetShowNoContentTip(true,  ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareWarOnVillage))
        end
        return
    else
        ---@type AllianceTerritoryMainMediator
        local mediator = self:GetParentBaseUIMediator()
        if mediator.SetShowNoContentTip then
            mediator:SetShowNoContentTip(false)
        end
    end
	if #cages > 0 then
		---@type AllianceBehemoth[][]
		local childrenCell = {}
		local rowCount = math.ceil(#cages / 2)
		for i = 0, rowCount - 1 do
			---@type AllianceBehemoth[]
			local rowData = {}
			for j = 1, 2 do
				rowData[j] = cages[i*2+j]
			end
			table.insert(childrenCell, rowData)
		end
		local categoryData = AllianceTerritoryBehemothCategoryCellData.new(childrenCell, true)
		categoryData.titleContent = I18N.Get("alliance_territory_overview_behemothcave_title")
        categoryData.tipContent = I18N.Get("alliance_territory_overview_behemothcave_tips")
		self._p_table_cities:AppendData(categoryData)
	end
    ---@type table<number, AllianceTerritoryMainCityTabCellData[]>
    local subTypeCategoryMap = {}
    for _, v in ipairs(self._data.sortedCities) do
        local subType = v.config:SubType()
        local subTypeArray = table.getOrCreate(subTypeCategoryMap, subType)
        ---@type AllianceTerritoryMainCityTabCellData
        local cellData = {}
        cellData.serverData = v.data
        cellData.config = v.config
        cellData.territoryConfig = v.territoryConfig
        cellData.isRebuilding = v.isRebuilding
        table.insert(subTypeArray, cellData)
    end
    local list = table.mapToList(subTypeCategoryMap)
    table.sort(list, function(a, b)
        return a.key > b.key
    end)

    for i = 1, 2 do
        local data = list[i]
        local subType = i
        local childrenCell
        if data then
            subType = data.key
            childrenCell = data.value
        else
            childrenCell = {}
        end
        local categoryData = AllianceTerritoryMainCityCategoryCellData.new(childrenCell, true)
        -- 1:定居点 2:城镇 3:关隘(未加)
        if subType == 1 then
            categoryData.titleContent = I18N.Get("alliance_bj_judian") .. (" (%d)"):format(#childrenCell)
        elseif subType == 2 then
            categoryData.titleContent = I18N.Get("alliance_bj_town") .. (" (%d)"):format(#childrenCell)
        elseif subType == 3 then
            categoryData.titleContent = I18N.Get("bw_city_name_pass") .. (" (%d)"):format(#childrenCell)
        end
        self._p_table_cities:AppendData(categoryData)
    end
end

function AllianceTerritoryMainCityTab:OnHide(param)
    self._isShow = false
end

return AllianceTerritoryMainCityTab
