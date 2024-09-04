---scene: scene_common_popup_activity_board
local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local CommonLeaderboardPopupDefine = require("CommonLeaderboardPopupDefine")
local GetTopListParameter = require("GetTopListParameter")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
---@class CommonLeaderboardPopupMediator : BaseUIMediator
local CommonLeaderboardPopupMediator = class("CommonLeaderboardPopupMediator", BaseUIMediator)

---@class StagedLeaderboardData
---@field cfgIds number[] @LeaderboardActivity cfgId[]
---@field stageName string @阶段名称

---@class CommonLeaderboardPopupMediatorParam
---@field style number @CommonLeaderboardPopupDefine.STYLE_MASK
---@field title string @标题
---@field curStage number @当前阶段, default 1
---@field leaderboardDatas StagedLeaderboardData[] @排行榜数据
---@field leaderboardTitles string[] @排行榜标题
---@field rewardsTitles string[] @奖励预览标题
---@field rewardsTitleHint string
---@field timerEndTime number @倒计时结束时间


function CommonLeaderboardPopupMediator:OnCreate()
    ---@see CommonLeaderboardPopupBoard
    self.luaGroupBoard = self:LuaObject("p_group_board")

    ---@see CommonLeaderboardPopupReward
    self.luaGroupRewards = self:LuaObject("p_group_rewards")

    ---@see CommonLeaderboardPopupContribution
    self.luaGroupContribution = self:LuaObject("p_group_contribution")

    ---@see CommonPopupBackLargeComponent
    self.luaBackground = self:LuaObject("child_popup_base_l")

    self.goTabBoard = self:GameObject("p_tab_board")
    self.btnTabBoard = self:Button("p_tab_board", Delegate.GetOrCreate(self, self.OnBtnTabBoardClicked))
    self.statusCtrlerTabBoard = self:StatusRecordParent("p_tab_board")
    self.textTabBoard = self:Text("p_text_board", "*排行榜")
    self.textTabBoardSelected = self:Text("p_text_select_board", "*排行榜")

    self.goTabRewards = self:GameObject("p_tab_rewards")
    self.btnTabRewards = self:Button("p_tab_rewards", Delegate.GetOrCreate(self, self.OnBtnTabRewardsClicked))
    self.statusCtrlerTabRewards = self:StatusRecordParent("p_tab_rewards")
    self.textTabRewards = self:Text("p_text_rewards", "*奖励预览")
    self.textTabRewardsSelected = self:Text("p_text_select_rewards", "*奖励预览")

    self.goTabContribution = self:GameObject("p_tab_contribution")
    self.btnTabContribution = self:Button("p_tab_contribution", Delegate.GetOrCreate(self, self.OnBtnTabContributionClicked))
    self.statusCtrlerTabContribution = self:StatusRecordParent("p_tab_contribution")
    self.textTabContribution = self:Text("p_text_contribution", "*贡献值获取")
    self.textTabContributionSelected = self:Text("p_text_select_contribution", "*贡献值获取")

    self.textTimer = self:Text("p_text_hint_time")

    self.tabCtrler = {
        [CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_BOARD] = {
            tab = self.statusCtrlerTabBoard,
            comp = self.luaGroupBoard,
        },
        [CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_REWARD] ={
            tab = self.statusCtrlerTabRewards,
            comp = self.luaGroupRewards,
        },
        [CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_CONTRIBUTION] = {
            tab = self.statusCtrlerTabContribution,
            comp = self.luaGroupContribution,
        },
    }
end

function CommonLeaderboardPopupMediator:OnShow()
    g_Game.ServiceManager:AddResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTimerTick))
end

function CommonLeaderboardPopupMediator:OnHide()
    g_Game.ServiceManager:RemoveResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTimerTick))
end
---@param param CommonLeaderboardPopupMediatorParam[]
function CommonLeaderboardPopupMediator:OnOpened(param)
    self.param = param
    self.curStage = param.curStage or 1
    self.styleMask = param.style
    ---@type CommonBackButtonData
    local data = {}
    data.title = I18N.Get(param.title)
    self.luaBackground:FeedData(data)
    self.textTimer.gameObject:SetActive(param.timerEndTime ~= nil)
    self:InitUI()
    self:InitData()
    self:InitComps()
    self:OnTimerTick()
end

function CommonLeaderboardPopupMediator:InitData()
    self.topListDatas = {}
    self.leaderBoardIds = {}
    ---@type number, StagedLeaderboardData
    for stage, data in ipairs(self.param.leaderboardDatas) do
        self.leaderBoardIds[stage] = {}
        for _, cfgId in ipairs(data.cfgIds) do
            local leaderBoardId = ConfigRefer.LeaderboardActivity:Find(cfgId):RelateLeaderboard()
            -- ModuleRefer.LeaderboardModule:SendGetTopList(leaderBoardId, 1, 100)
            table.insert(self.leaderBoardIds[stage], leaderBoardId)
        end
    end
end

function CommonLeaderboardPopupMediator:InitUI()
    self.showBoard = self.styleMask & CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_BOARD ~= 0
    self.showRewards = self.styleMask & CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_REWARD ~= 0
    self.showContribution = self.styleMask & CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_CONTRIBUTION ~= 0
    self.goTabBoard:SetActive(self.showBoard)
    self.goTabRewards:SetActive(self.showRewards)
    self.goTabContribution:SetActive(self.showContribution)
end

function CommonLeaderboardPopupMediator:InitComps()
    if self.showBoard then
        ---@type CommonLeaderboardPopupBoardParam
        local data = {}
        data.leaderboardIds = self.leaderBoardIds
        data.leaderboardTitles = self.param.leaderboardTitles
        data.stageNames = {}
        for _, ldbData in ipairs(self.param.leaderboardDatas) do
            table.insert(data.stageNames, ldbData.stageName)
        end
        data.curStage = self.param.curStage or 1
        self.luaGroupBoard:FeedData(data)
    end

    if self.showRewards then
    end

    if self.showBoard then
        self:SwitchToTab(CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_BOARD)
    elseif self.showRewards then
        self:SwitchToTab(CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_REWARD)
    elseif self.showContribution then
        self:SwitchToTab(CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_CONTRIBUTION)
    end
end

function CommonLeaderboardPopupMediator:SwitchToTab(styleMask)
    for k, v in pairs(self.tabCtrler) do
        if k == styleMask then
            v.tab:ApplyStatusRecord(1)
            v.comp:SetVisible(true)
            if styleMask == CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_REWARD then
                ---@type CommonLeaderboardPopupRewardParam
                local data = {}
                data.leaderboardIds = self.leaderBoardIds[self.curStage]
                data.rewardsTitles = self.param.rewardsTitles
                data.cfgIds = self.param.leaderboardDatas[self.curStage].cfgIds
                data.rewardsTitleHint = self.param.rewardsTitleHint
                data.topListDatas = self.topListDatas[self.curStage]
                v.comp:FeedData(data)
            end
        else
            v.tab:ApplyStatusRecord(0)
            v.comp:SetVisible(false)
        end
    end
end

function CommonLeaderboardPopupMediator:OnBtnTabBoardClicked()
    self:SwitchToTab(CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_BOARD)
end

function CommonLeaderboardPopupMediator:OnBtnTabRewardsClicked()
    self:SwitchToTab(CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_REWARD)
end

function CommonLeaderboardPopupMediator:OnBtnTabContributionClicked()
    self:SwitchToTab(CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_CONTRIBUTION)
end

function CommonLeaderboardPopupMediator:OnTimerTick()
    if not self.param.timerEndTime then
        return
    end
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local time = math.clamp(self.param.timerEndTime - now, 0, math.huge)
    self.textTimer.text = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(time)
end

function CommonLeaderboardPopupMediator:OnGetTopListResponse(isSuccess, reply, req)
    if not isSuccess then
        return
    end
    ---@type LeaderboardTopListPageData
    local data = {}
    data.reply = reply
    data.req = req.request
    local stage = self:GetLeaderboardStage(data.req.TopListTid)
    self.curStage = stage
    if not self.topListDatas[stage] then
        self.topListDatas[stage] = {}
    end
    self.topListDatas[stage][data.req.TopListTid] = data
end

function CommonLeaderboardPopupMediator:GetLeaderboardStage(leaderboardCfgId)
    for stage, data in ipairs(self.param.leaderboardDatas) do
        for _, cfgId in ipairs(data.cfgIds) do
            if ConfigRefer.LeaderboardActivity:Find(cfgId):RelateLeaderboard() == leaderboardCfgId then
                return stage
            end
        end
    end
    return nil
end

function CommonLeaderboardPopupMediator:GetTotalLeaderboardCount()
    local count = 0
    for _, data in ipairs(self.param.leaderboardDatas) do
        count = count + #(data.cfgIds)
    end
    return count
end

return CommonLeaderboardPopupMediator