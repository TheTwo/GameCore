local BaseUIComponent = require("BaseUIComponent")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local ActivityCategory = require("ActivityCategory")
local I18N = require("I18N")
local ActivityClass = require("ActivityClass")
---@class EarthRevivalNewsAndActivity : BaseUIComponent
local EarthRevivalNewsAndActivity = class("EarthRevivalNewsAndActivity", BaseUIComponent)

---@class EarthRevivalNewsAndActivityParameter
---@field tabId number @ActivityCenterTabs id

local TableCellType = {
    News = 0,
    Activity = 1,
    Title = 2,
}

local ActivityCategoryName = {
    [ActivityCategory.Regular] = I18N.Get("worldstage_tjhd"),
    [ActivityCategory.Preview] = I18N.Get("worldstage_jqqd"),
    [ActivityCategory.Hot] = I18N.Get("worldstage_rmhd"),
}

function EarthRevivalNewsAndActivity:ctor()
    ---@type table<number, number[]> @Category: Ids
    self.activityTabIds = {}
    self.categoryKeys = {}
    for _, category in pairs(ActivityCategory) do
        table.insert(self.categoryKeys, category)
        self.activityTabIds[category] = {}
    end
    table.sort(self.categoryKeys)
    ---@type table<number, BaseUIComponent>
    self.id2LuaActivityComps = {}
    ---@type table<string, BaseUIComponent>
    self.luaActivityCompsDict = {}

    self.cells = {}
    self.id2Index = {}

    self.selectedTabId = nil
end

function EarthRevivalNewsAndActivity:OnCreate()
    self.goGroupActivity = self:GameObject("p_group_activity")
    self.luaGroupNews = self:LuaObject("p_news")
    self.tableNews = self:TableViewPro("p_table_news")
end

function EarthRevivalNewsAndActivity:OnShow()
    g_Game.EventManager:AddListener(EventConst.ON_EARTH_REVIVAL_NEWS_CELL_CLICK, Delegate.GetOrCreate(self, self.OnNewsCellClick))
    g_Game.EventManager:AddListener(EventConst.ON_EARTH_REVIVAL_ACTIVITY_CELL_CLICK, Delegate.GetOrCreate(self, self.OnActivityCellClick))
end

function EarthRevivalNewsAndActivity:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_EARTH_REVIVAL_NEWS_CELL_CLICK, Delegate.GetOrCreate(self, self.OnNewsCellClick))
    g_Game.EventManager:RemoveListener(EventConst.ON_EARTH_REVIVAL_ACTIVITY_CELL_CLICK, Delegate.GetOrCreate(self, self.OnActivityCellClick))
end

---@param param EarthRevivalNewsAndActivityParameter
function EarthRevivalNewsAndActivity:OnFeedData(param)
    self.tabId = (param or {}).tabId or self.selectedTabId
    self:UpdateOpenActivityTabIds()
    self:FillTable()
    if self.tabId and self.tabId > 0 and ModuleRefer.ActivityCenterModule:IsActivityTabOpenByTabId(self.tabId) then
        self.tableNews:SetDataFocus(self.id2Index[self.tabId], 0, CS.TableViewPro.MoveSpeed.Fast)
        self.tableNews:SetToggleSelect(self.cells[self.tabId])
    else
        self.tableNews:SetToggleSelect(self.cells[0])
    end
end

function EarthRevivalNewsAndActivity:FillTable()
    table.clear(self.cells)
    self.cells[0] = {}
    self.tableNews:Clear()
    self.tableNews:AppendData(self.cells[0], TableCellType.News)
    local index = 0
    self.id2Index[0] = index
    for _, category in ipairs(self.categoryKeys) do
        local ids = self.activityTabIds[category]
        if #ids > 0 then
            self.tableNews:AppendData(ActivityCategoryName[category], TableCellType.Title)
            index = index + 1
            for _, id in ipairs(ids) do
                index = index + 1
                ---@type EarthRevivalActivityData
                local cellData = {}
                cellData.id = id
                self.cells[id] = cellData
                self.tableNews:AppendData(self.cells[id], TableCellType.Activity)
                self.id2Index[id] = index
            end
        end
    end
end

function EarthRevivalNewsAndActivity:SwitchToNews()
    self.goGroupActivity:SetActive(false)
    self.luaGroupNews:SetVisible(true)
    self.luaGroupNews:FeedData(ModuleRefer.EarthRevivalModule:GetNewsData())
    self.selectedTabId = 0
end

function EarthRevivalNewsAndActivity:SwitchToActivity(tabId)
    if self.selectedTabId == tabId then return end
    self.goGroupActivity:SetActive(true)
    self.luaGroupNews:SetVisible(false)
    for id, comp in pairs(self.id2LuaActivityComps) do
        if id ~= tabId then
            comp:SetVisible(false)
        end
    end
    local childPrefabName = ConfigRefer.ActivityCenterTabs:Find(tabId):PrefabName()
    if self.id2LuaActivityComps[tabId] then
        self.id2LuaActivityComps[tabId]:SetVisible(true)
        self.id2LuaActivityComps[tabId]:FeedData({ tabId = tabId })
    else
        CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self:GetCSUIMediator(), childPrefabName, "content", function(go)
            self.luaActivityCompsDict[childPrefabName] = self:LuaObject(childPrefabName)
            self.id2LuaActivityComps[tabId] = self.luaActivityCompsDict[childPrefabName]
            self.id2LuaActivityComps[tabId]:SetVisible(true)
            self.id2LuaActivityComps[tabId]:FeedData({ tabId = tabId })
        end, true)
    end
    self.selectedTabId = tabId
end

function EarthRevivalNewsAndActivity:OnNewsCellClick()
    self:SwitchToNews()
end

function EarthRevivalNewsAndActivity:OnActivityCellClick(tabId)
    self:SwitchToActivity(tabId)
end

function EarthRevivalNewsAndActivity:UpdateOpenActivityTabIds()
    ---@type _, ActivityCenterTabsConfigCell
    for _, ids in pairs(self.activityTabIds) do
        table.clear(ids)
    end
    for _, tab in ConfigRefer.ActivityCenterTabs:ipairs() do
        if ModuleRefer.ActivityCenterModule:IsActivityTabOpen(tab) and self:IsGamePlayActivity(tab:Id()) then
            local category = ModuleRefer.ActivityCenterModule:GetActivityCategory(tab:Id())
            if not category or category == 0 then
                category = ActivityCategory.Regular
            end
            table.insert(self.activityTabIds[category], tab:Id())
        end
    end
    for _, ids in pairs(self.activityTabIds) do
        table.sort(ids, self.ActivitySorter)
    end
end

function EarthRevivalNewsAndActivity.ActivitySorter(a, b)
    return ModuleRefer.ActivityCenterModule.ActivitySorter(a, b)
end

function EarthRevivalNewsAndActivity:IsGamePlayActivity(tabId)
    return ModuleRefer.ActivityCenterModule:GetActivityClass(tabId) == ActivityClass.GamePlay
end

return EarthRevivalNewsAndActivity