local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local LeaderboardType = require('LeaderboardType')
local EventConst = require('EventConst')
local GetHonorTopListParameter = require('GetHonorTopListParameter')
local GetTopListParameter = require('GetTopListParameter')
local DBEntityPath = require("DBEntityPath")

---@class LeaderboardUIMediatorParameter
---@field leaderboardId number

---@class LeaderboardTabData
---@field isMainTab boolean
---@field type LeaderboardType
---@field leaderboardConfigCell LeaderboardConfigCell
---@field isSelect boolean
---@field canUnfold boolean
---@field isUnfold boolean

---@class LeaderboardUIMediator : BaseUIMediator
---@field new fun():LeaderboardUIMediator
---@field super BaseUIMediator
local LeaderboardUIMediator = class('LeaderboardUIMediator', BaseUIMediator)

LeaderboardUIMediator.TAB_MAIN_TOP_PLAYER = 999
local INDEX_DEFAULT = 1
local INDEX_NONE = -1

function LeaderboardUIMediator:OnCreate()
    ---@type CommonBackButtonComponent
    self.child_common_btn_back = self:LuaObject('child_common_btn_back')

    self.tabsTable = self:TableViewPro('p_table_tab_side_left')

    ---@type LeaderboardHonorListPage 名人堂
    self.pageHonorList = self:LuaObject('p_group_famous')

    ---@type LeaderboardTopListPage 其他排行榜
    self.pageTopList = self:LuaObject('p_group_leaderboard')
end

function LeaderboardUIMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.LEADERBOARD_TAB_MAIN_CLICK, Delegate.GetOrCreate(self, self.OnTabMainClick))
    g_Game.EventManager:AddListener(EventConst.LEADERBOARD_TAB_SUB_CLICK, Delegate.GetOrCreate(self, self.OnTabSubClick))

    g_Game.ServiceManager:AddResponseCallback(GetHonorTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetHonorTopListResponse))
    g_Game.ServiceManager:AddResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))

    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerTopList.DailyReward.MsgPath, Delegate.GetOrCreate(self, self.OnDailyRewardChanged))
end

function LeaderboardUIMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.LEADERBOARD_TAB_MAIN_CLICK, Delegate.GetOrCreate(self, self.OnTabMainClick))
    g_Game.EventManager:RemoveListener(EventConst.LEADERBOARD_TAB_SUB_CLICK, Delegate.GetOrCreate(self, self.OnTabSubClick))

    g_Game.ServiceManager:RemoveResponseCallback(GetHonorTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetHonorTopListResponse))
    g_Game.ServiceManager:RemoveResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))

    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerTopList.DailyReward.MsgPath, Delegate.GetOrCreate(self, self.OnDailyRewardChanged))
end

---@param param LeaderboardUIMediatorParameter
function LeaderboardUIMediator:OnOpened(param)
    self:InitTabsData()

    self.pageHonorList:SetVisible(false)
    self.pageTopList:SetVisible(false)

    ---@type CommonBackButtonData
    local btnData = {
        title = I18N.Get('leaderboard_title')
    }
    self.child_common_btn_back:FeedData(btnData)

    self.selectTabIndex = INDEX_NONE
    local targetTabIndex = INDEX_DEFAULT
    if param and param.leaderboardId then
        targetTabIndex = self:GetTabIndexById(param.leaderboardId)
    end

    -- 如果名人堂未解锁，跳转到个人排行
    if targetTabIndex == INDEX_DEFAULT and not ModuleRefer.LeaderboardModule:IsHonorPageUnlock() then
        targetTabIndex = self:GetTabIndexById(1)
    end

    self:OnTabClickByIndex(targetTabIndex)
end

function LeaderboardUIMediator:OnClose(param)

end

function LeaderboardUIMediator:InitTabsData()
    ---@type table <number, LeaderboardTabData>
    self.tabsData = {}

    ---@type LeaderboardTabData
    local tabData = {}
    ---@type table <number, LeaderboardConfigCell>
    local cells

    -- 名人堂，只有一级目录
    tabData.isMainTab = true
    tabData.isSelect = false
    tabData.canUnfold = false
    tabData.isUnfold = false
    tabData.type = LeaderboardUIMediator.TAB_MAIN_TOP_PLAYER
    table.insert(self.tabsData, tabData)

    -- 个人排行
    tabData = {}
    tabData.isMainTab = true
    tabData.isSelect = false
    tabData.canUnfold = true
    tabData.isUnfold = false
    tabData.type = LeaderboardType.Personal
    table.insert(self.tabsData, tabData)
    -- 二级目录
    cells = ModuleRefer.LeaderboardModule:GetLeaderboardCellsByType(LeaderboardType.Personal)
    for _, cell in ipairs(cells) do
        tabData = {}
        tabData.isMainTab = false
        tabData.leaderboardConfigCell = cell
        tabData.isSelect = false
        tabData.canUnfold = true
        tabData.isUnfold = false
        tabData.type = LeaderboardType.Personal
        table.insert(self.tabsData, tabData)
    end

    -- 联盟排行
    tabData = {}
    tabData.isMainTab = true
    tabData.isSelect = false
    tabData.canUnfold = true
    tabData.isUnfold = false
    tabData.type = LeaderboardType.Alliance
    table.insert(self.tabsData, tabData)
    -- 二级目录
    cells = ModuleRefer.LeaderboardModule:GetLeaderboardCellsByType(LeaderboardType.Alliance)
    for _, cell in ipairs(cells) do
        tabData = {}
        tabData.isMainTab = false
        tabData.leaderboardConfigCell = cell
        tabData.isSelect = false
        tabData.canUnfold = true
        tabData.isUnfold = false
        tabData.type = LeaderboardType.Alliance
        table.insert(self.tabsData, tabData)
    end

    -- 活动排行
    cells = ModuleRefer.LeaderboardModule:GetLeaderboardCellsByType(LeaderboardType.Activity)
    if #cells > 0 then
        tabData = {}
        tabData.isMainTab = true
        tabData.isSelect = false
        tabData.canUnfold = true
        tabData.isUnfold = false
        tabData.type = LeaderboardType.Activity
        table.insert(self.tabsData, tabData)

        -- 二级目录
        for _, cell in ipairs(cells) do
            tabData = {}
            tabData.isMainTab = false
            tabData.leaderboardConfigCell = cell
            tabData.isSelect = false
            tabData.canUnfold = true
            tabData.isUnfold = false
            tabData.type = LeaderboardType.Activity
            table.insert(self.tabsData, tabData)
        end
    end
end

function LeaderboardUIMediator:RefreshTabs()
    self.tabsTable:Clear()

    ---@type LeaderboardTabsMainCellData
    local mainCellData
    ---@type LeaderboardTabsSubCellData
    local subCellData

    for _, tabData in ipairs(self.tabsData) do
        -- 被折叠的子节点不显示
        if not tabData.isMainTab and tabData.canUnfold and not tabData.isUnfold then
            goto continue
        end

        if tabData.isMainTab then
            mainCellData = {}
            mainCellData.type = tabData.type
            mainCellData.isSelect = tabData.isSelect
            mainCellData.canFold = tabData.canUnfold
            mainCellData.isUnfold = tabData.isUnfold
            mainCellData.isUnlock = true
            if tabData.type == LeaderboardUIMediator.TAB_MAIN_TOP_PLAYER and not ModuleRefer.LeaderboardModule:IsHonorPageUnlock() then
                mainCellData.isUnlock = false
            end
            self.tabsTable:AppendData(mainCellData, 0)
        else
            subCellData = {}
            subCellData.type = tabData.type
            subCellData.isSelect = tabData.isSelect
            subCellData.leaderboardConfigCell = tabData.leaderboardConfigCell
            self.tabsTable:AppendData(subCellData, 1)
        end

        ::continue::
    end
end

---@param leaderboardId Leaderboard.csv的ID
function LeaderboardUIMediator:GetTabIndexById(leaderboardId)
    for index, tabData in ipairs(self.tabsData) do
        if not tabData.isMainTab and tabData.leaderboardConfigCell:Id() == leaderboardId then
            return index
        end
    end

    return INDEX_DEFAULT
end

---@param leaderboardType wds.enum.LeaderboardType
function LeaderboardUIMediator:GetMainTabIndexByType(leaderboardType)
    for index, tabData in ipairs(self.tabsData) do
        if tabData.type == leaderboardType and tabData.isMainTab then
            return index
        end
    end

    return INDEX_DEFAULT
end

---@param leaderboardType wds.enum.LeaderboardType
function LeaderboardUIMediator:OnTabMainClick(leaderboardType)
    local index = self:GetMainTabIndexByType(leaderboardType)
    self:OnTabClickByIndex(index)
end

---@param leaderboardId number LeaderboardConfigCell的Id
function LeaderboardUIMediator:OnTabSubClick(leaderboardId)
    local index = self:GetTabIndexById(leaderboardId)
    self:OnTabClickByIndex(index)
end

function LeaderboardUIMediator:CanSelect(index)
    local tabData = self.tabsData[index]
    if tabData.isMainTab and tabData.canUnfold then
        return false
    end

    return true
end

function LeaderboardUIMediator:OnTabClickByIndex(index)
    local changed = false
    if self:CanSelect(index) then
        -- 点击选中
        changed = index ~= self.selectTabIndex
        if self.selectTabIndex ~= INDEX_NONE then
            self.tabsData[self.selectTabIndex].isSelect = false
        end
        self.selectTabIndex = index
        self.tabsData[index].isSelect = true

        -- 一级tab，没有二级tab时，折叠其他的一级tab
        if self.tabsData[index].isSelect and self.tabsData[index].isMainTab then
            for _, tabData in ipairs(self.tabsData) do
                if tabData.type ~= self.tabsData[index].type then
                    tabData.isUnfold = false
                    tabData.isSelect = false
                end
            end
        end

        -- 展开当前选中的
        local tabType = self.tabsData[index].type
        for _, tabData in ipairs(self.tabsData) do
            if tabData.type == tabType then
                tabData.isUnfold = true
                if tabData.isMainTab then
                    tabData.isSelect = true
                end
            end
        end
    else
        -- 点击折叠
        local tabType = self.tabsData[index].type
        local isUnfold = not self.tabsData[index].isUnfold

        -- 折叠之前展开的
        for _, tabData in ipairs(self.tabsData) do
            tabData.isUnfold = false
            tabData.isSelect = false
        end

        -- 展开当前选中的
        for _, tabData in ipairs(self.tabsData) do
            if tabData.type == tabType then
                tabData.isUnfold = isUnfold
                if tabData.isMainTab then
                    tabData.isSelect = true
                end
            end
        end

        -- 并选中第一个子tab
        for index, tabData in ipairs(self.tabsData) do
            if tabData.type == tabType and not tabData.isMainTab then
                tabData.isSelect = true
                changed = index ~= self.selectTabIndex
                if self.selectTabIndex ~= INDEX_NONE then
                    self.tabsData[self.selectTabIndex].isSelect = false
                end
                self.selectTabIndex = index
                self.tabsData[index].isSelect = true
                break
            end
        end
    end

    -- 有切换tab
    if changed then
        if self.tabsData[self.selectTabIndex].type == LeaderboardUIMediator.TAB_MAIN_TOP_PLAYER then
            ModuleRefer.LeaderboardModule:SendGetHonorTopList()
        else
            local leaderboardId = self.tabsData[self.selectTabIndex].leaderboardConfigCell:Id()
            ModuleRefer.LeaderboardModule:SendGetTopList(leaderboardId, 1, 100)
        end
    end

    self:RefreshTabs()
end

function LeaderboardUIMediator:OnDailyRewardChanged()
    self:RefreshTabs()
end

---@param isSuccess boolean
---@param reply wrpc.GetHonorTopListReply
function LeaderboardUIMediator:OnGetHonorTopListResponse(isSuccess, reply, req)
    if not isSuccess then return end

    self.pageHonorList:SetVisible(true)
    self.pageTopList:SetVisible(false)

    -- local rapidjson = require('rapidjson')
    -- g_Logger.Error(rapidjson.encode(reply))

    ---@type LeaderboardHonorListPageData
    local data = {}
    data.reply = reply
    self.pageHonorList:FeedData(data)
end

---@param isSuccess boolean
---@param reply wrpc.GetTopListReply
---@param req AbstractRpc
function LeaderboardUIMediator:OnGetTopListResponse(isSuccess, reply, req)
    if not isSuccess then return end

    -- local rapidjson = require('rapidjson')
    -- g_Logger.Error(rapidjson.encode(reply))

    self.pageHonorList:SetVisible(false)
    self.pageTopList:SetVisible(true)

    ---@type LeaderboardTopListPageData
    local data = {}
    data.reply = reply
    data.req = req.request
    self.pageTopList:FeedData(data)
end

return LeaderboardUIMediator
