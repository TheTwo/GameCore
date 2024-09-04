local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')
local TimeFormatter = require('TimeFormatter')

---@class AllianceTechRankMediator : BaseUIMediator
local AllianceTechRankMediator = class('AllianceTechRankMediator', BaseUIMediator)

function AllianceTechRankMediator:ctor()
    self.module = ModuleRefer.GveModule
end

function AllianceTechRankMediator:OnCreate()
    self.p_tab_board = self:Button('p_tab_board', Delegate.GetOrCreate(self, self.OnClickTab1))
    self.p_tab_rewards = self:Button('p_tab_rewards', Delegate.GetOrCreate(self, self.OnClickTab2))
    self.p_base_a = self:Button('p_base_a', Delegate.GetOrCreate(self, self.OnClickWeeklyRank))
    self.p_base_b = self:Button('p_base_b', Delegate.GetOrCreate(self, self.OnClickTotalRank))

    self.tabBoardStatus = self:StatusRecordParent("p_tab_board")
    self.tabRewardStatus = self:StatusRecordParent("p_tab_rewards")
    self.tabWeekStatus = self:StatusRecordParent("p_base_a")
    self.tabTotalStatus = self:StatusRecordParent("p_base_b")

    -- 每周/总捐献排行榜
    self.p_group_board = self:GameObject('p_group_board')
    self.p_text_a = self:Text('p_text_a', "alliance_technology_rank2")
    self.p_text_b = self:Text('p_text_b', "alliance_technology_rank3")
    self.p_text_title_rank = self:Text('p_text_title_rank', "gverating_rank")
    self.p_text_title_player = self:Text('p_text_title_player', "se_pvp_main_player")
    self.p_text_title_number = self:Text('p_text_title_number', "alliance_technology_rank4")
    self.p_text_title_value = self:Text('p_text_title_value', "alliance_technology_rank6")
    self.p_table_ranking = self:TableViewPro('p_table_ranking')
    self.p_content_mine = self:LuaObject('p_content_mine')

    -- 奖励
    self.p_group_rewards = self:GameObject('p_group_rewards')
    self.p_text_hint_reward = self:Text('p_text_hint_reward', "alliance_technology_rank7")
    self.p_text_hint_time = self:Text('p_text_hint_time', "Next settlement: 4d20:00:00")
    self.p_text_title_reward_rank = self:Text('p_text_title_reward_rank', "gverating_rank")
    self.p_text_title_reward_player = self:Text('p_text_title_reward_player', "leaderboard_info_9")
    self.p_table_rewards = self:TableViewPro('p_table_rewards')
    self.p_my_reward = self:LuaObject('p_my_reward')

    self.child_popup_base_l = self:LuaObject('child_popup_base_l')
end

function AllianceTechRankMediator:OnShow(param)
    ModuleRefer.AllianceTechModule:SetDonateRank()
    self.timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnTimerTick), 1, -1)
    self.weeklyRank = ModuleRefer.AllianceTechModule.weeklyRank
    self.totalRank = ModuleRefer.AllianceTechModule.totalRank
    self:SwitchTab(1)
    self:RefreshRank(true)
end

function AllianceTechRankMediator:SwitchTab(index)
    if index == 1 then
        self.tabBoardStatus:SetState(1)
        self.tabRewardStatus:SetState(0)
        self.p_group_board:SetVisible(true)
        self.p_group_rewards:SetVisible(false)
        self:RefreshRank(true)
    elseif index == 2 then
        self.tabBoardStatus:SetState(0)
        self.tabRewardStatus:SetState(1)
        self.p_group_board:SetVisible(false)
        self.p_group_rewards:SetVisible(true)
        self:RefreshReward()
    end

    ---@type CommonBackButtonData
    local title = index == 1 and "playerinfo_rank" or "leaderboard_info_9"
    self.backButtonData = {}
    self.backButtonData.title = I18N.Get(title)
    self.child_popup_base_l:FeedData(self.backButtonData)
end

function AllianceTechRankMediator:RefreshRank(isWeek)
    local targetRank = isWeek and self.weeklyRank or self.totalRank

    self.p_table_ranking:Clear()

    if isWeek then
        self.tabWeekStatus:SetState(1)
        self.tabTotalStatus:SetState(0)
    else
        self.tabWeekStatus:SetState(0)
        self.tabTotalStatus:SetState(1)
    end

    for i = 1, #targetRank do
        if targetRank[i].DonateValues > 0 then
            targetRank[i].rank = i
        end

        if targetRank[i].DonateValues > 0 then
            if targetRank[i].isMine then
                self.p_content_mine:FeedData(targetRank[i])
                self.myRankIndex = i
            end

            self.p_table_ranking:AppendData(targetRank[i])
        end
    end

    if ModuleRefer.AllianceTechModule.myWeekRank == 0 then
        self.p_content_mine.go:SetVisible(false)
    else
        self.p_content_mine.go:SetVisible(true)
    end
end

function AllianceTechRankMediator:RefreshReward()
    local from = 1
    self.p_table_rewards:Clear()
    local myRankData
    for i = 1, ConfigRefer.AllianceConsts:AllianceDonateSettleRankLength() do
        local data = {}
        data.from = from
        data.to = ConfigRefer.AllianceConsts:AllianceDonateSettleRank(i)
        from = data.to + 1
        data.isMyReward = false
        local itemGroup = ConfigRefer.ItemGroup:Find(ConfigRefer.AllianceConsts:AllianceDonateSettleReward(i))

        local rewards = {}
        for i = 1, itemGroup:ItemGroupInfoListLength() do
            local iconData = {}
            local itemGroupInfo = itemGroup:ItemGroupInfoList(i)
            iconData.configCell = ConfigRefer.Item:Find(itemGroupInfo:Items())
            iconData.count = itemGroupInfo:Nums()
            table.insert(rewards, iconData)
        end
        data.rewards = rewards
        self.p_table_rewards:AppendData(data)

        if self.myRankIndex and self.myRankIndex >= data.from and self.myRankIndex <= data.to then
            myRankData = data
            myRankData.isMyReward = true
            myRankData.hasRank = true
        end
    end
    if myRankData then
        self.p_my_reward:FeedData(myRankData)
        self.p_my_reward.go:SetVisible(true)
    else
        self.p_my_reward.go:SetVisible(false)
    end
end

function AllianceTechRankMediator:OnHide(param)
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function AllianceTechRankMediator:OnClickTab1()
    self:SwitchTab(1)
end

function AllianceTechRankMediator:OnClickTab2()
    self:SwitchTab(2)
end

function AllianceTechRankMediator:OnClickWeeklyRank()
    self:RefreshRank(true)
end

function AllianceTechRankMediator:OnClickTotalRank()
    self:RefreshRank(false)
end

function AllianceTechRankMediator:OnTimerTick()
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    local endTime = allianceInfo.AllianceTechnology.DonateSettleTime
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local remainTime = math.max(0, endTime - nowTime)
    self.p_text_hint_time.text = I18N.GetWithParams("alliance_technology_rank_tips1", TimeFormatter.SimpleFormatTimeWithDayHourSeconds(remainTime))
end

return AllianceTechRankMediator
