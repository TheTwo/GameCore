local BaseUIComponent = require('BaseUIComponent')
local UIHelper = require('UIHelper')
local RewardHelper = require('RewardHelper')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
---@class CommonLeaderboardPopupReward : BaseUIComponent
local CommonLeaderboardPopupReward = class('CommonLeaderboardPopupReward', BaseUIComponent)

---@class CommonLeaderboardPopupRewardParam
---@field rewardsTitles string[]
---@field topListDatas LeaderboardTopListPageData[]
---@field leaderboardIds number[]
---@field cfgIds number[]
---@field rewardsTitleHint string

function CommonLeaderboardPopupReward:OnCreate()
    ---@type CommonLeaderboardPopupBoardTab
    self.tabTemplate = self:LuaBaseComponent('p_btn_tab')
    self.textHint = self:Text('p_text_hint_reward')
    self.textHeaderRank = self:Text('p_text_title_rank', 'worldstage_phb_pm')
    self.textHeaderReward = self:Text('p_text_title_reward', 'worldstage_phb_jl')
    self.tableRewards = self:TableViewPro('p_table_rewards')
    self.luaMyReward = self:LuaObject('p_my_reward')
    ---@type CommonLeaderboardPopupBoardTab
    self.tabTemplate = self:LuaBaseComponent('p_btn_tab')
end

---@param param CommonLeaderboardPopupRewardParam
function CommonLeaderboardPopupReward:OnFeedData(param)
    self.titles = param.rewardsTitles
    self.topListDatas = param.topListDatas
    self.leaderboardIds = param.leaderboardIds
    self.cfgIds = param.cfgIds
    self.textHint.text = param.rewardsTitleHint
    self.myRanks = {}
    ---@type number, LeaderboardTopListPageData
    for cfgId, topListData in pairs(self.topListDatas) do
        self.myRanks[cfgId] = topListData.reply.PlayerInfo.Rank
    end
    self.rewardLists = {}
    self.rankRanges = {}
    for i, cfgId in ipairs(self.cfgIds) do
        self.rewardLists[i] = {}
        self.rankRanges[i] = {}
        local cfg = ConfigRefer.LeaderboardActivity:Find(cfgId)
        local rewardLength = cfg:RewardItemGroupLength()
        for j = 1, rewardLength do
            self.rewardLists[i][j] = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(cfg:RewardItemGroup(j))
        end
        local rankLength = cfg:RewardRankLength()
        for j = 1, rankLength do
            self.rankRanges[i][j] = cfg:RewardRank(j)
        end
    end
    self:ReleaseTabs()
    self:InitTabs()
    self:OnTabClicked(1)
end

function CommonLeaderboardPopupReward:OnHide()
    -- self:ReleaseTabs()
end

function CommonLeaderboardPopupReward:InitTabs()
    self.tabs = {}
    self.tabTemplate:SetVisible(true)
    for i, title in ipairs(self.titles) do
        local tab = UIHelper.DuplicateUIComponent(self.tabTemplate)
        tab:FeedData({
            title = title,
            isSelcted = i == 1,
            onClick = function()
                self:OnTabClicked(i)
            end,
        })
        table.insert(self.tabs, tab)
    end
    self.tabTemplate:SetVisible(false)
end

function CommonLeaderboardPopupReward:ReleaseTabs()
    if not self.tabs then self.tabs = {} end
    for _, tab in ipairs(self.tabs) do
        UIHelper.DeleteUIComponent(tab)
    end
    self.tabs = {}
end

function CommonLeaderboardPopupReward:InitRewardByRankRewardId(cfgId)
    self.tableRewards:Clear()
    local rewardsList = RewardHelper.GetRankRewardInItemIconDatas(cfgId)
    local ranks = {}
    for rank, _ in pairs(rewardsList) do
        table.insert(ranks, rank)
    end
    table.sort(ranks)
    local lastRank = 1
    for _, rank in ipairs(ranks) do
        ---@type CommonLeaderboardPopupRewardCellParam
        local cell = {}
        cell.fromRank = lastRank
        cell.toRank = rank
        cell.rewards = rewardsList[rank]
        self.tableRewards:AppendData(cell)
        lastRank = rank + 1
    end
end

function CommonLeaderboardPopupReward:InitRewardByRewardList(rewardLists, rankRanges)
    self.tableRewards:Clear()
    local lastRank = 1
    for i, rewards in ipairs(rewardLists) do
        ---@type CommonLeaderboardPopupRewardCellParam
        local cell = {}
        cell.fromRank = lastRank
        cell.toRank = rankRanges[i]
        cell.rewards = rewards
        self.tableRewards:AppendData(cell)
        lastRank = rankRanges[i] + 1
    end
end

function CommonLeaderboardPopupReward:OnTabClicked(index)
    for i, tab in ipairs(self.tabs) do
        tab.Lua:SetSelect(i == index)
    end
    self:InitRewardByRewardList(self.rewardLists[index], self.rankRanges[index])
    self.luaMyReward:SetVisible(true)
    self:InitMyReward(index)
end

function CommonLeaderboardPopupReward:InitMyReward(index)
    local myRank = self.myRanks[self.leaderboardIds[index]]
    local rewards = {}
    local hasRank = false
    if myRank and myRank > 0 then
        for i, rankRange in ipairs(self.rankRanges[index]) do
            if myRank <= rankRange then
                rewards = self.rewardLists[index][i]
                break
            end
        end
        hasRank = true
    end
    ---@type CommonLeaderboardPopupRewardCellParam
    local data = {}
    data.fromRank = myRank
    data.toRank = myRank
    data.rewards = rewards
    data.isMyReward = true
    data.hasRank = hasRank
    self.luaMyReward:FeedData(data)
end

return CommonLeaderboardPopupReward