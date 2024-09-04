local I18N = require("I18N")
local AllianceTerritoryMainFacilityCategoryCellData = require("AllianceTerritoryMainFacilityCategoryCellData")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceTerritoryMainFacilityTab:BaseUIComponent
---@field new fun():AllianceTerritoryMainFacilityTab
---@field super BaseUIComponent
local AllianceTerritoryMainFacilityTab = class('AllianceTerritoryMainFacilityTab', BaseUIComponent)

function AllianceTerritoryMainFacilityTab:ctor()
    AllianceTerritoryMainFacilityTab.super.ctor(self)
    ---@type AllianceTerritoryMainMediatorDataContext
    self._data = nil
    ---@type table<number, boolean>
    self._entryFacilityExpandMap = {}
end

function AllianceTerritoryMainFacilityTab:OnCreate(param)
    self._p_table_facility = self:TableViewPro("p_table_facility")
end

---@param data AllianceTerritoryMainMediatorDataContext
function AllianceTerritoryMainFacilityTab:OnFeedData(data)
    self._data = data
    if self._isShow then
        self:Refresh()
    end
end

function AllianceTerritoryMainFacilityTab:OnShow(param)
    self:Refresh()
    self._isShow = true
end

function AllianceTerritoryMainFacilityTab:Refresh()
    self._p_table_facility:Clear()
    local defData = self._data.militaryBuildings[FlexibleMapBuildingType.DefenseTower]
    local crystalData =  self._data.militaryBuildings[FlexibleMapBuildingType.EnergyTower]
    local deviceData = self._data.militaryBuildings[FlexibleMapBuildingType.BehemothDevice]
    local summonerData = self._data.militaryBuildings[FlexibleMapBuildingType.BehemothSummoner]

    for _, v in ipairs(self._data.entryFactionTypes) do
        self._entryFacilityExpandMap[v] = true
    end

    local defenceTowerCount = 0
    ---@type AllianceTerritoryMainFacilityCellData[]
    local allFacilityCells = {}
    for _, v in ipairs(defData) do
        ---@type AllianceTerritoryMainFacilityCellData
        local oneData = {}
        oneData.serverData = (not v.isLocked) and v.serverData or nil
        oneData.config = ConfigRefer.FlexibleMapBuilding:Find(v.configId)
        table.insert(allFacilityCells, oneData)
        if v.serverData then
            defenceTowerCount = defenceTowerCount + #v.serverData
        end
    end
    ---@type AllianceTerritoryMainFacilityCategoryCellData
    local data = AllianceTerritoryMainFacilityCategoryCellData.new(allFacilityCells, self._entryFacilityExpandMap[FlexibleMapBuildingType.DefenseTower])
    data.titleContent = I18N.GetWithParams("alliance_territory_12", tostring(defenceTowerCount), tostring(self._data.defenceTowerMax))
    self._p_table_facility:AppendData(data)

    local crystalTowerCount = 0
    ---@type AllianceTerritoryMainFacilityCellData[]
    local allFacilityCells2 = {}
    for _, v in ipairs(crystalData) do
        ---@type AllianceTerritoryMainFacilityCellData
        local oneData = {}
        oneData.serverData = (not v.isLocked) and v.serverData or nil
        oneData.config = ConfigRefer.FlexibleMapBuilding:Find(v.configId)
        table.insert(allFacilityCells2, oneData)
        if v.serverData then
            crystalTowerCount = crystalTowerCount + #v.serverData
        end
    end
    ---@type AllianceTerritoryMainFacilityCategoryCellData
    local data2 = AllianceTerritoryMainFacilityCategoryCellData.new(allFacilityCells2, self._entryFacilityExpandMap[FlexibleMapBuildingType.EnergyTower])
    data2.titleContent =I18N.GetWithParams("alliance_territory_13", tostring(crystalTowerCount), tostring(self._data.crystalTowerMax))
    self._p_table_facility:AppendData(data2)
    
    --080版本临时屏蔽--
    --local behemothBuildingCount = 0
    -----@type AllianceTerritoryMainFacilityCellData[]
    --local allBehemothBuildingCells = {}
    --local totalCountLimit = 0
    --for _, v in ipairs(deviceData) do
    --    ---@type AllianceTerritoryMainFacilityCellData
    --    local oneData = {}
    --    oneData.serverData = (not v.isLocked) and v.serverData or nil
    --    oneData.config = ConfigRefer.FlexibleMapBuilding:Find(v.configId)
    --    table.insert(allBehemothBuildingCells, oneData)
    --    totalCountLimit = totalCountLimit + oneData.config:BuildCountMax()
    --    if v.serverData then
    --        behemothBuildingCount = behemothBuildingCount + #v.serverData
    --    end
    --end
    --for _, v in ipairs(summonerData) do
    --    ---@type AllianceTerritoryMainFacilityCellData
    --    local oneData = {}
    --    oneData.serverData = (not v.isLocked) and v.serverData or nil
    --    oneData.config = ConfigRefer.FlexibleMapBuilding:Find(v.configId)
    --    totalCountLimit = totalCountLimit + oneData.config:BuildCountMax()
    --    table.insert(allBehemothBuildingCells, oneData)
    --    if v.serverData then
    --        behemothBuildingCount = behemothBuildingCount + #v.serverData
    --    end
    --end
    -----@type AllianceTerritoryMainFacilityCategoryCellData
    --local shouldExpand = self._entryFacilityExpandMap[FlexibleMapBuildingType.BehemothDevice] or self._entryFacilityExpandMap[FlexibleMapBuildingType.BehemothSummoner]
    --local data3 = AllianceTerritoryMainFacilityCategoryCellData.new(allBehemothBuildingCells, shouldExpand, 3)
    --data3.titleContent =I18N.GetWithParams("alliance_behemoth_territory_title2", tostring(behemothBuildingCount), tostring(totalCountLimit))
    --data3.childPrefabIndex = 2
    --self._p_table_facility:AppendData(data3)
end

function AllianceTerritoryMainFacilityTab:OnHide(param)
    self._isShow = false
    self._p_table_facility:Clear()
end

return AllianceTerritoryMainFacilityTab