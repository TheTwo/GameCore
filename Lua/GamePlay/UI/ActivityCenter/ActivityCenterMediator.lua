---scene: sence_activity_center
local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require('I18N')
local EventConst = require('EventConst')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require('ConfigRefer')
local DBEntityPath = require('DBEntityPath')
local PlayerAutoRewardOpParameter = require('PlayerAutoRewardOpParameter')
local ActivityClass = require('ActivityClass')

---@class ActivityCenterOpenParam
---@field tabId number

---@class ActivityCenterMediator : BaseUIMediator
local ActivityCenterMediator = class('ActivityCenterMediator', BaseUIMediator)

function ActivityCenterMediator:ctor()
    self.selectId = 1
    ---@type ActivityCenterTabCellData[]
    self.cellDatas = {}
    ---@type table<number, ActivityCenterTabCellData>
    self.tabId2CellData = {}
    self.createdComps = {}
    self.ids = {}
    self.luaActivityCompsDict = {}
end

function ActivityCenterMediator:OnCreate()
    self.tableTabs = self:TableViewPro('p_table_tab')
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.compChildResource = self:LuaObject('child_resource')
    self.goLoadMask = self:GameObject('p_content')
    self.generatorNodeName = 'content'
    self.goLoadMask:SetActive(false)
end

---@param params ActivityCenterOpenParam | string
function ActivityCenterMediator:OnOpened(params)
    g_Game.EventManager:AddListener(EventConst.ON_SELECT_ACTIVITY_CENTER_TAB,  Delegate.GetOrCreate(self, self.OnSelectTab))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath,Delegate.GetOrCreate(self,self.RefreshCoins))
    g_Game.ServiceManager:AddResponseCallback(PlayerAutoRewardOpParameter.GetMsgId(), Delegate.GetOrCreate(self, self.RefreshCoins))
    if type(params) == 'string' then
        self.selectId = tonumber(params)
    else
        self.selectId = (params or {}).tabId
    end
    self:Init()
    self.compChildResource:SetVisible(false)
    self.compChildCommonBack:FeedData({title = I18N.Get("activity_center_name")})
end

function ActivityCenterMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_ACTIVITY_CENTER_TAB,  Delegate.GetOrCreate(self, self.OnSelectTab))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath,Delegate.GetOrCreate(self,self.RefreshCoins))
    g_Game.ServiceManager:RemoveResponseCallback(PlayerAutoRewardOpParameter.GetMsgId(), Delegate.GetOrCreate(self, self.RefreshCoins))

    if self.selectId then
        ModuleRefer.ActivityCenterModule:ClearTabNewlyUnlockStatus(self.selectId)
    end
end

function ActivityCenterMediator:Init()
    self:UpdateTabs()
    if self.selectId and self.tabId2CellData[self.selectId] then
        self.tableTabs:SetToggleSelect(self.tabId2CellData[self.selectId])
    else
        self.tableTabs:SetToggleSelectIndex(0)
    end
end

function ActivityCenterMediator:UpdateTabs()
    self.tableTabs:Clear()
    self.cellDatas = {}
    self.tabId2CellData = {}
    for _, tab in ConfigRefer.ActivityCenterTabs:ipairs() do
        if self:IsTabOpen(tab) and self:IsCommercialActivity(tab:Id()) then
            table.insert(self.ids, tab:Id())
        end
    end
    table.sort(self.ids, ModuleRefer.ActivityCenterModule.ActivitySorter)
    for _, id in ipairs(self.ids) do
        ---@type ActivityCenterTabCellData
        local cellData = {}
        cellData.id = id
        cellData.tabId = id
        table.insert(self.cellDatas, cellData)
        self.tabId2CellData[id] = cellData
        self.tableTabs:AppendData(cellData)
    end
end

function ActivityCenterMediator:OnSelectTab(tabId, force)
    self.selectId = tabId
    self:RefreshCoins()
    if self.createdComps[tabId] then
        self:ShowComp(tabId)
    else
        self:ShowCompAsync(tabId)
    end
    ModuleRefer.ActivityCenterModule:ClearTabNewlyUnlockStatus(tabId)
    ModuleRefer.ActivityCenterModule:UpdateRedDotByTabId(tabId)
end

function ActivityCenterMediator:ShowComp(tabId)
    for id, comp in pairs(self.createdComps) do
        comp:SetVisible(id == tabId)
    end
    self.createdComps[tabId]:FeedData(self.tabId2CellData[tabId])
end

function ActivityCenterMediator:ShowCompAsync(tabId)
    local childPrefabName = ConfigRefer.ActivityCenterTabs:Find(tabId):PrefabName()
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self:GetCSUIMediator(), childPrefabName, self.generatorNodeName, function(go)
        self.luaActivityCompsDict[childPrefabName] = self:LuaObject(childPrefabName)
        self.createdComps[tabId] = self.luaActivityCompsDict[childPrefabName]
        self:ShowComp(tabId)
    end, true)
end

---@param tab ActivityCenterTabsConfigCell
function ActivityCenterMediator:IsTabOpen(tab)
    if not tab then return true end
    return ModuleRefer.ActivityCenterModule:IsActivityTabOpen(tab)
end

function ActivityCenterMediator:IsCommercialActivity(tabId)
    return ModuleRefer.ActivityCenterModule:GetActivityClass(tabId) == ActivityClass.Commercial
end

function ActivityCenterMediator:RefreshCoins()
    local tab = ConfigRefer.ActivityCenterTabs:Find(self.selectId)
    if not tab then return end
    local resourceId = tab:ResourceType()
    if resourceId == 0 then
        self.compChildResource:SetVisible(false)
        return
    end
    self.compChildResource:SetVisible(true)
    local coinCfg = ConfigRefer.Item:Find(resourceId)
    if resourceId == ModuleRefer.ActivityCenterModule:GetTurntableCostItemId() then
        local amount = ModuleRefer.ActivityCenterModule:GetTurntableCostItemCurAmount()
        local iconData = {
            iconName = coinCfg:Icon(),
            content = amount,
            isShowPlus = false,
        }
        self.compChildResource:FeedData(iconData)
        return
    end
    local iconData2 = {
        iconName = coinCfg:Icon(),
        content = ModuleRefer.InventoryModule:GetAmountByConfigId(resourceId),
        isShowPlus = false,
    }
    self.compChildResource:FeedData(iconData2)
end

return ActivityCenterMediator
