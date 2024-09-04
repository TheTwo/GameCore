--- scene:scene_league_territory

local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local MapBuildingType = require("MapBuildingType")
local MapBuildingSubType = require("MapBuildingSubType")
local DBEntityType = require("DBEntityType")
local EventConst = require("EventConst")
local ActivityCenterConst = require("ActivityCenterConst")
local AllianceModuleDefine = require('AllianceModuleDefine')
local NotificationType = require('NotificationType')
local BaseUIMediator = require("BaseUIMediator")

---@alias militaryBuildingData {configId:number,serverData:wds.MapBuildingBrief[], isLocked:boolean}

---@class AllianceTerritoryMainMediatorDataContext
---@field sortedCities {data:wds.MapBuildingBrief,config:FixedMapBuildingConfigCell,territoryConfig:TerritoryConfigCell,isRebuilding:boolean,progress:number}[]
---@field defenceTowerMax number
---@field crystalTowerMax number
---@field militaryBuildings table<number, militaryBuildingData[]>
---@field militaryBuildingsCount table<number, number>
---@field maxFaction number
---@field faction number
---@field entryFactionTypes number[] @FlexibleMapBuildingType

---@class AllianceTerritoryMainMediatorParameter
---@field backNoAni boolean
---@field entryTab number
---@field entryFactionTypes number[] @FlexibleMapBuildingType

---@class AllianceTerritoryMainMediator:BaseUIMediator
---@field new fun():AllianceTerritoryMainMediator
---@field super BaseUIMediator
local AllianceTerritoryMainMediator = class('AllianceTerritoryMainMediator', BaseUIMediator)

function AllianceTerritoryMainMediator:ctor()
    AllianceTerritoryMainMediator.super.ctor(self)
    ---@type AllianceTerritoryMainMediatorDataContext
    self.contextData = nil
    self._backNoAni = false
end

function AllianceTerritoryMainMediator:OnCreate(param)
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn_summary = self:LuaObject("child_tab_left_btn_summary")
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn_cities = self:LuaObject("child_tab_left_btn_cities")
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn_facility = self:LuaObject("child_tab_left_btn_facility")

    ---@type AllianceTerritoryMainSummaryTab
    self._p_group_summary = self:LuaObject("p_group_summary")
    ---@type AllianceTerritoryMainCityTab
    self._p_group_cities = self:LuaObject("p_group_cities")
    ---@type AllianceTerritoryMainFacilityTab
    self._p_group_facility = self:LuaObject("p_group_facility")
    ---@type AllianceTerritoryActivityGoto
    self._p_group_activity_goto = self:LuaObject("p_group_activity_goto")

    self._p_group_empty = self:GameObject("p_group_empty")
    self._p_text_application_empty = self:Text("p_text_application_empty", "alliance_territory_11")
    ---@type BistateButton
    self._p_btn_jump_village = self:LuaObject("p_btn_jump_village")

    ---@see CommonBackButtonComponent
    self._child_common_btn_back = self:LuaBaseComponent("child_common_btn_back")
end

---@param param AllianceTerritoryMainMediatorParameter
function AllianceTerritoryMainMediator:OnOpened(param)
    self._backNoAni = param and param.backNoAni or false
    self:FeedTabBtnData()
    self:GenerateContextData()
    local openTab = 1
    if param then
        if type(param) == 'string' then
            openTab = tonumber(param)
        elseif param.entryTab then
            openTab = param.entryTab
        end
    end
    self.contextData.entryFactionTypes = param and param.entryFactionTypes or {FlexibleMapBuildingType.DefenseTower}
    self._p_group_activity_goto:SetVisible(ModuleRefer.ActivityCenterModule:IsActivityTabOpenByTabId(ActivityCenterConst.VillageEvent))
    self._p_group_activity_goto:FeedData({activityTabId = ActivityCenterConst.VillageEvent})
    self:OnChangeTabIndex(openTab or 1)
end

function AllianceTerritoryMainMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_TERRITORY_DAILY_GIFT_REDDOT, Delegate.GetOrCreate(self, self.UpdateDailyGiftRedDot))
end

function AllianceTerritoryMainMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_TERRITORY_DAILY_GIFT_REDDOT, Delegate.GetOrCreate(self, self.UpdateDailyGiftRedDot))
end

function AllianceTerritoryMainMediator:OnChangeTabIndex(index)
    self:SetShowNoContentTip(false)
    self._p_group_summary:SetVisible(index == 1)
    self._p_group_cities:SetVisible(index == 2)
    self._p_group_facility:SetVisible(index == 3)
    self._child_tab_left_btn_summary:SetStatus(index == 1 and 0 or 1)
    self._child_tab_left_btn_cities:SetStatus(index == 2 and 0 or 1)
    -- self._child_tab_left_btn_facility:SetStatus(index == 3 and 0 or 1)
    self._child_tab_left_btn_facility:SetVisible(false)
end

-- 设置红点
function AllianceTerritoryMainMediator:UpdateDailyGiftRedDot()
    local redNode = self._child_tab_left_btn_summary:GetNotificationNode()
    local node = ModuleRefer.NotificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.TerritoryDailyGift, NotificationType.ALLIANCE_TERRITORY_DAILY_GIFT)
    ModuleRefer.NotificationModule:AttachToGameObject(node, redNode.go, redNode.redDot)
end

function AllianceTerritoryMainMediator:FeedTabBtnData()

    ---@type CommonBackButtonData
    local backBtnData = {}
    backBtnData.title = I18N.Get("league_hud_territory")
    backBtnData.onClose = Delegate.GetOrCreate(self, self.OnClickBackBtn)
    self._child_common_btn_back:FeedData(backBtnData)

    ---@type CommonChildTabLeftBtnParameter
    local tabData = {}
    tabData.index = 1
    tabData.onClick = Delegate.GetOrCreate(self, self.OnChangeTabIndex)
    tabData.onClickLocked = nil
    tabData.btnName = I18N.Get("alliance_territory_1")
    tabData.isLocked = false
    self._child_tab_left_btn_summary:FeedData(tabData)
    self._child_tab_left_btn_summary:ShowNotificationNode()

    self:UpdateDailyGiftRedDot()

    tabData = {}
    tabData.index = 2
    tabData.onClick = Delegate.GetOrCreate(self, self.OnChangeTabIndex)
    tabData.onClickLocked = nil
    tabData.btnName = I18N.Get("alliance_territory_2")
    tabData.isLocked = false
    self._child_tab_left_btn_cities:FeedData(tabData)

    tabData = {}
    tabData.index = 3
    tabData.onClick = Delegate.GetOrCreate(self, self.OnChangeTabIndex)
    tabData.onClickLocked = nil
    tabData.btnName = I18N.Get("alliance_territory_3")
    tabData.isLocked = false
    self._child_tab_left_btn_facility:FeedData(tabData)
end

function AllianceTerritoryMainMediator:GenerateContextData()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local t
    self.contextData = {}
    t,self.contextData.defenceTowerMax = ModuleRefer.KingdomConstructionModule:GetBuildingTypeCountAndLimitCount(FlexibleMapBuildingType.DefenseTower)
    t,self.contextData.crystalTowerMax = ModuleRefer.KingdomConstructionModule:GetBuildingTypeCountAndLimitCount(FlexibleMapBuildingType.EnergyTower)
    self.contextData.sortedCities = {}
    self.contextData.militaryBuildings = {}
    self.contextData.militaryBuildingsCount = {}
    self.contextData.maxFaction = allianceData.MapBuildingBriefs.MaxFaction
    self.contextData.faction = allianceData.MapBuildingBriefs.Faction
    ---@type table<number, table<number, wds.MapBuildingBrief[]>>
    local flexibleMapBuildingMap = {}
    flexibleMapBuildingMap[FlexibleMapBuildingType.DefenseTower] = {}
    flexibleMapBuildingMap[FlexibleMapBuildingType.EnergyTower] = {}
    flexibleMapBuildingMap[FlexibleMapBuildingType.BehemothDevice] = {}
    flexibleMapBuildingMap[FlexibleMapBuildingType.BehemothSummoner] = {}
    for _, v in ConfigRefer.FlexibleMapBuilding:ipairs() do
        if v:Type() == FlexibleMapBuildingType.DefenseTower then
            flexibleMapBuildingMap[FlexibleMapBuildingType.DefenseTower][v:Id()] = {}
        elseif v:Type() == FlexibleMapBuildingType.EnergyTower then
            flexibleMapBuildingMap[FlexibleMapBuildingType.EnergyTower][v:Id()] = {}
        elseif v:Type() == FlexibleMapBuildingType.BehemothDevice then
            flexibleMapBuildingMap[FlexibleMapBuildingType.BehemothDevice][v:Id()] = {}
        elseif v:Type() == FlexibleMapBuildingType.BehemothSummoner then
            flexibleMapBuildingMap[FlexibleMapBuildingType.BehemothSummoner][v:Id()] = {}
        end
    end
    local buildings = allianceData.MapBuildingBriefs.MapBuildingBriefs
    for _, v in pairs(buildings) do
        if v.EntityTypeHash == DBEntityType.Village then
            local buildingConfig = ConfigRefer.FixedMapBuilding:Find(v.ConfigId)
            if buildingConfig then
                local villageBuildingType = buildingConfig:Type()
                local subType = buildingConfig:SubType()
                if villageBuildingType == MapBuildingType.Town and (subType == MapBuildingSubType.City or subType == MapBuildingSubType.Stronghold)  then
                    table.insert(self.contextData.sortedCities, {data = v, config = buildingConfig, territoryConfig = ConfigRefer.Territory:Find(v.VID), issRebuilding=false})
                end
            end
        else
            if v.Status == wds.BuildingStatus.BuildingStatus_Constructing
                    or v.Status == wds.BuildingStatus.BuildingStatus_Constructed
                    or v.Status == wds.BuildingStatus.BuildingStatus_GiveUping
                    or v.Status == wds.BuildingStatus.BuildingStatus_WaitReBuild
            then
                local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(v.ConfigId)
                if buildingConfig then
                    local flexiBuildingType = buildingConfig:Type()
                    if flexiBuildingType == FlexibleMapBuildingType.DefenseTower then
                        table.insert(flexibleMapBuildingMap[FlexibleMapBuildingType.DefenseTower][buildingConfig:Id()], v)
                    elseif flexiBuildingType == FlexibleMapBuildingType.EnergyTower then
                        table.insert(flexibleMapBuildingMap[FlexibleMapBuildingType.EnergyTower][buildingConfig:Id()], v)
                    elseif flexiBuildingType == FlexibleMapBuildingType.BehemothDevice then
                        table.insert(flexibleMapBuildingMap[FlexibleMapBuildingType.BehemothDevice][buildingConfig:Id()], v)
                    elseif flexiBuildingType == FlexibleMapBuildingType.BehemothSummoner then
                        table.insert(flexibleMapBuildingMap[FlexibleMapBuildingType.BehemothSummoner][buildingConfig:Id()], v)
                    end
                end
            end
        end
    end
    
    local rebuildVillages = allianceData.AllianceWrapper.BuilderRuinRebuild.Buildings
    for _, rebuild in pairs(rebuildVillages) do
        local config = ConfigRefer.FixedMapBuilding:Find(rebuild.BuildingCfgId)
        local territoryConfig = ConfigRefer.Territory:Find(rebuild.TerritoryId)
        local data = {
            data = rebuild,
            config = config,
            territoryConfig = territoryConfig,
            isRebuilding = true
        }
        table.insert(self.contextData.sortedCities, data)
    end
    
    table.sort(self.contextData.sortedCities, function(a, b)
        if a.isRebuilding ~= b.isRebuilding then
            return a.isRebuilding and not b.isRebuilding
        end
        local villageA = ConfigRefer.FixedMapBuilding:Find(a.territoryConfig:VillageId())
        local villageB = ConfigRefer.FixedMapBuilding:Find(b.territoryConfig:VillageId())
        local lvA,lvB = villageA:Level(), villageB:Level()
        if lvA > lvB then
            return true
        end
        if lvB > lvA then
            return false
        end
        return a.data.StartTime.Seconds > b.data.StartTime.Seconds
    end) 

    for i, v in pairs(flexibleMapBuildingMap) do
        ---@type militaryBuildingData[]
        local configCell = {}
        self.contextData.militaryBuildings[i] = configCell
        local count = 0
        for configId, serverDataArray in pairs(v) do
            local c = ConfigRefer.FlexibleMapBuilding:Find(configId)
            ---@type militaryBuildingData
            local addCell = {}
            addCell.configId = configId
            addCell.serverData = serverDataArray
            addCell.isLocked = not ModuleRefer.AllianceTechModule:IsBuildingTechSatisfy(c) or not ModuleRefer.AllianceTechModule:IsBuildingAllianceCenterSatisfy(c) or ModuleRefer.KingdomConstructionModule:GetBuildingLimitCount(c) <= 0
            count = count + #serverDataArray
            table.insert(configCell, addCell)
        end
        self.contextData.militaryBuildingsCount[i] = count
    end
    self._p_group_summary:FeedData(self.contextData)
    self._p_group_cities:FeedData(self.contextData)
    self._p_group_facility:FeedData(self.contextData)
end

function AllianceTerritoryMainMediator:SetShowNoContentTip(isShow, showJumpVillage)
    self._p_group_empty:SetVisible(isShow)
    self._p_btn_jump_village:SetVisible(showJumpVillage or false)
    if showJumpVillage then
        ---@type BistateButtonParameter
        local btnData = {}
        btnData.buttonText = I18N.Get("alliance_territory_city_none_gotobtn")
        btnData.onClick = function()
            self:CloseSelf()
            ModuleRefer.VillageModule:GoToNeareastLv1Village()
        end
        self._p_btn_jump_village:FeedData(btnData)
        self._p_btn_jump_village:SetEnabled(true)
    end
end

function AllianceTerritoryMainMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

function AllianceTerritoryMainMediator:OnClickBackBtn()
    self:BackToPrevious(nil, self._backNoAni, self._backNoAni)
end

return AllianceTerritoryMainMediator