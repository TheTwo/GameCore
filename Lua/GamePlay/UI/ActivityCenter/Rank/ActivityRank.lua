local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local TimeFormatter = require('TimeFormatter')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require("UIMediatorNames")
local ActivityRankRewardState = require('ActivityRankRewardState')
local ConfigTimeUtility = require('ConfigTimeUtility')

local GetTopListCurRankParameter = require('GetTopListCurRankParameter')
local GetTopListActivityRewardParameter = require('GetTopListActivityRewardParameter')

---@class ActivityRankData
---@field leaderboardActivityCfgId number
---@field activityData wds.PlayerTopListActivity
---@field activityStartTimestamp number
---@field activityEndTimestamp number
---@field activityRewardTimestamp number
---@field isInRewardTime boolean

---@class ActivityRank : BaseUIComponent
local ActivityRank = class('ActivityRank', BaseUIComponent)

function ActivityRank:OnCreate()
    self.txtTitle = self:Text('p_text_title')
    self.txtDesc = self:Text('p_text_describe')
    self.txtPeriod = self:Text('p_text_time_1')

    self.txtTimeDesc = self:Text('p_text_time')
    ---@type CommonTimer
    self.childTime = self:LuaObject('child_time')
    self.txtReward = self:Text('p_text_reward', 'leaderboard_info_9')
    self.table = self:TableViewPro('p_table_aim')

    self.goMyReward = self:GameObject('p_group_my_reward')
    self.txtMyRewardNone = self:Text('p_text_empty')
    self.txtMyRankTitle = self:Text('p_text_myrank', '')
    self.txtMyRankValue = self:Text('p_text_myrank_value')
    self.txtMyRewardTitle = self:Text('p_text_my_reward', 'leaderActivity_info_5')
    self.tableMyRewards = self:TableViewPro('p_table_my_rewards')
    ---@type BistateButton
    self.bibtnMyReward = self:LuaObject('child_comp_btn_myreward')
    self.imgMyRewardCliamed = self:Image('p_icon_claimed')
    ---@type NotificationNode
    self.reddotMyReward = self:LuaObject('child_reddot_myreward')

    self.txtHeroName = self:Text('p_text_name')
    self.txtHeroQuality = self:Text('p_text_quality')
    self.btnTips = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnTipsClick))
    self.btnRankDetail = self:Button('p_btn_ranking', Delegate.GetOrCreate(self, self.OnRankDetailClick))
    self.txtRankDetail = self:Text('p_text_ranking_1', 'leaderActivity_info_4')

    ---@type CommonResourceBtn
    self.child_resource = self:LuaObject('child_resource')

    self.isFirstOpen = true
    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

function ActivityRank:OnShow(param)
    if self.isFirstOpen then
        self.isFirstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
    g_Game.ServiceManager:AddResponseCallback(GetTopListCurRankParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetTopListCurRankReply))
    g_Game.ServiceManager:AddResponseCallback(GetTopListActivityRewardParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetTopListActivityRewardReply))
end

function ActivityRank:OnHide(param)
    g_Game.ServiceManager:RemoveResponseCallback(GetTopListCurRankParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetTopListCurRankReply))
    g_Game.ServiceManager:RemoveResponseCallback(GetTopListActivityRewardParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetTopListActivityRewardReply))
end

function ActivityRank:UpdateActivityRankData()
    local tabId = self.tabId
    local actId = ConfigRefer.ActivityCenterTabs:Find(tabId):RefActivityReward()
    local configId = ConfigRefer.ActivityRewardTable:Find(actId):RefConfig()
    local player = ModuleRefer.PlayerModule:GetPlayer()

    ---@type ActivityRankData
    self.data = {}
    self.data.leaderboardActivityCfgId = configId
    self.data.activityData = player.PlayerWrapper3.PlayerTopList.ActivityInfo[configId]

    self.leaderboardActivityCfgCell = ConfigRefer.LeaderboardActivity:Find(configId)
    local activityRewardTableCfgId = self.leaderboardActivityCfgCell:ControlActivityTable()
    local activityTempId = ConfigRefer.ActivityRewardTable:Find(activityRewardTableCfgId):OpenActivity()
    local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
    local activityEntry = kingdom.ActivityInfo.Activities[activityTempId]
    self.data.activityStartTimestamp = activityEntry.StartTime.Seconds
    self.data.activityEndTimestamp = activityEntry.EndTime.Seconds

    local duration = ConfigTimeUtility.NsToSeconds(self.leaderboardActivityCfgCell:EarlyRankDuration())
    self.data.activityRewardTimestamp = self.data.activityEndTimestamp - duration

    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    self.data.isInRewardTime = now >= self.data.activityRewardTimestamp and now <= self.data.activityEndTimestamp
    self.data.isInActivity = now < self.data.activityRewardTimestamp

    if self.data.isInRewardTime then
        self.data.myRank = self.data.activityData.Rank
    else
        self.data.myRank = 9999
    end
end

function ActivityRank:OnFeedData(param)
    self.tabId = param.tabId
    self:UpdateActivityRankData()
    self:UpdateUI()

    if self.data.isInActivity then
        local req = GetTopListCurRankParameter.new()
        req.args.Tid = self.leaderboardActivityCfgCell:RelateLeaderboard()
        req:Send()
    end
end

---@param reply wrpc.GetTopListCurRankReply
function ActivityRank:OnGetTopListCurRankReply(isSucess, reply, rpc)
    self.data.myRank = reply.Rank
    self:UpdateUI()
end

---@param reply wrpc.GetTopListActivityRewardReply
function ActivityRank:OnGetTopListActivityRewardReply(isSucess, reply, rpc)
    if isSucess then
        self:UpdateUI()
    end
end

function ActivityRank:GetRewardIndex(rank)
    local length = self.leaderboardActivityCfgCell:RewardRankLength()
    for i = 1, length do
        local min, max = self:GetRankSection(i)
        if max < 0 then
            return i
        end

        if rank >= min and rank <= max then
            return i
        end
    end

    return 1
end

function ActivityRank:UpdateUI()
    local myRank = self.data.myRank

    -- 玩家没有参与此活动
    local notTakeIn = not self.data.activityData.Active

    if myRank == -1 then
        -- 未上榜
        self.txtMyRewardNone.text = I18N.Get('leaderboard_info_4')
    elseif notTakeIn then
        -- 没参加过活动，显示活动已结束
        self.txtMyRewardNone.text = I18N.Get('leaderActivity_notice_end')
    end

    local myRewardIndex = self:GetRewardIndex(myRank)
    self.txtMyRankValue.text = I18N.Get(string.format('%s: %s', I18N.Get('leaderboard_showTitle_3'), myRank))
    self.txtTitle.text = I18N.Get(self.leaderboardActivityCfgCell:Title())
    self.txtDesc.text = I18N.Get(self.leaderboardActivityCfgCell:Content())

    -- TODO 取配置表时间区间
    local activityStart = TimeFormatter.TimeToDateTimeString(self.data.activityStartTimestamp)
    local activityEnd = TimeFormatter.TimeToDateTimeString(self.data.activityEndTimestamp)
    self.txtPeriod.text = string.format('UTC %s-%s', activityStart, activityEnd)

    if not self.data.isInRewardTime then
        ---@type CommonTimerData
        local timerData = {}
        timerData.endTime = self.data.activityRewardTimestamp
        timerData.needTimer = true
        timerData.overrideTimeFormat = TimeFormatter.SimpleFormatTimeWithDayHourSeconds
        timerData.callBack = Delegate.GetOrCreate(self, self.OnTimerEnd)
        self.childTime:FeedData(timerData)
        self.childTime:SetVisible(true)
    else
        self.childTime:SetVisible(false)
    end

    self.table:Clear()
    local length = self.leaderboardActivityCfgCell:RewardRankLength()
    for i = 1, length do
        local targetRank = self.leaderboardActivityCfgCell:RewardRank(i)
        local itemGroupId = self.leaderboardActivityCfgCell:RewardItemGroup(i)
        ---@type ActivityRankCellData
        local cellData = {}
        cellData.itemGroupId = itemGroupId
        cellData.targetRankMin, cellData.targetRankMax = self:GetRankSection(i)
        self.table:AppendData(cellData)
    end

    if myRewardIndex <= 0 or notTakeIn then
        self.txtMyRewardNone:SetVisible(true)
        self.goMyReward:SetVisible(false)
    else
        self.txtMyRewardNone:SetVisible(false)
        self.goMyReward:SetVisible(true)

        -- 奖励预览
        local myItemGroupId = self.leaderboardActivityCfgCell:RewardItemGroup(myRewardIndex)
        local itemIconDataList = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(myItemGroupId)
        self.tableMyRewards:Clear()
        for i, iconData in ipairs(itemIconDataList) do
            self.tableMyRewards:AppendData(iconData)
        end

        local myRewardState = self:GetMyRewardState()
        self.bibtnMyReward:SetVisible(myRewardState ~= ActivityRankRewardState.HasClaimed)
        self.imgMyRewardCliamed:SetVisible(myRewardState == ActivityRankRewardState.HasClaimed)
        self.reddotMyReward:SetVisible(myRewardState == ActivityRankRewardState.CanClaim)

        ---@type BistateButtonParameter
        local bistateButtonParameter = {}
        bistateButtonParameter.onClick = Delegate.GetOrCreate(self, self.OnRewardBtnClick)
        bistateButtonParameter.buttonText = I18N.Get('task_btn_claim')
        bistateButtonParameter.disableButtonText = I18N.Get('task_btn_claim')
        self.bibtnMyReward:FeedData(bistateButtonParameter)
        self.bibtnMyReward:SetEnabled(myRewardState == ActivityRankRewardState.CanClaim)
    end
end

function ActivityRank:OnTimerEnd()
    self:UpdateActivityRankData()
    self:UpdateUI()
end

-- 获得3种区间
-- 1，[1, 1] 显示1
-- 2，[2, 4] 显示2-4
-- 3，[5, 99999] 显示参与奖 
function ActivityRank:GetRankSection(index)
    local length = self.leaderboardActivityCfgCell:RewardRankLength()
    if index < length then
        local rank = self.leaderboardActivityCfgCell:RewardRank(index)
        local rankNext = self.leaderboardActivityCfgCell:RewardRank(index + 1)
        if rank + 1 == rankNext then
            return rank, rank
        end

        return rank, rankNext - 1
    elseif index == length then
        local rank = self.leaderboardActivityCfgCell:RewardRank(index)
        return rank, -1
    end
end

function ActivityRank:GetMyRewardState()
    local myRewardState = ActivityRankRewardState.TimeInvalid
    if self.data.isInRewardTime then
        if self.data.activityData.RewardReceived then
            myRewardState = ActivityRankRewardState.Claimed
        else
            myRewardState = ActivityRankRewardState.CanClaim
        end
    else
        myRewardState = ActivityRankRewardState.TimeInvalid
    end
    return myRewardState
end

-- 跳转到排行榜页面
function ActivityRank:OnRankDetailClick()
    local leaderboardId = self.leaderboardActivityCfgCell:RelateLeaderboard()
    ---@type LeaderboardUIMediatorParameter
    local param = {}
    param.leaderboardId = leaderboardId
    g_Game.UIManager:Open(UIMediatorNames.LeaderboardUIMediator, param)
end

-- 显示tips
function ActivityRank:OnTipsClick()
    ---@type TextToastMediatorParameter
    local toastParameter = {}
    toastParameter.clickTransform = self.btnTips.transform
    toastParameter.content = I18N.Get(self.leaderboardActivityCfgCell:Content())
    ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end

function ActivityRank:OnRewardBtnClick()
    local myRewardState = self:GetMyRewardState()
    if myRewardState == ActivityRankRewardState.TimeInvalid then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('leaderboard_info_10'))
        return
    end

    if myRewardState == ActivityRankRewardState.HasClaimed then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('activity_signin_btn_nagetive'))
        return
    end

    local req = GetTopListActivityRewardParameter.new()
    req.args.Tid = self.data.leaderboardActivityCfgId
    req:Send()
end

return ActivityRank
