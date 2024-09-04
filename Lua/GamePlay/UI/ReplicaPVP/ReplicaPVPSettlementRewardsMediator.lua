local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")

---@class ReplicaPVPSettlementRewardsMediatorParameter

---@class ReplicaPVPSettlementRewardsMediator:BaseUIMediator
---@field new fun():ReplicaPVPSettlementRewardsMediator
---@field super BaseUIMediator
local ReplicaPVPSettlementRewardsMediator = class('ReplicaPVPSettlementRewardsMediator', BaseUIMediator)

function ReplicaPVPSettlementRewardsMediator:ctor()
    BaseUIMediator.ctor(self)

    self.isTimerStart = false
end

function ReplicaPVPSettlementRewardsMediator:OnCreate(param)
    ---@type CommonButtonTab
    self.tabDaily = self:LuaObject('p_btn_daily')

    ---@type CommonButtonTab
    self.tabSeason = self:LuaObject('p_btn_season')

    self.txtInfo = self:Text('p_text_challenge')
    self.tableRewards = self:TableViewPro('p_table_reward')

    ---table的标题
    self.txtHeadType = self:Text('p_text_type', 'se_pvp_levelmessage_level')
    self.txtHeadReward = self:Text('p_text_award', 'se_pvp_levelmessage_reward2')
end

---@param data ReplicaPVPSettlementRewardsMediatorParameter
function ReplicaPVPSettlementRewardsMediator:OnOpened(param)
    self.myTitleStageTid = ModuleRefer.ReplicaPVPModule:GetMyTitleStageTid()

    ---@type CommonButtonTabParameter
    local tabDailyParam = {}
    tabDailyParam.text = I18N.Get('se_pvp_reward_day')
    tabDailyParam.callback = Delegate.GetOrCreate(self, self.OnTabDailyClicked)
    self.tabDaily:FeedData(tabDailyParam)

    ---@type CommonButtonTabParameter
    local tabSeasonParam = {}
    tabSeasonParam.text = I18N.Get('se_pvp_reward_season')
    tabSeasonParam.callback = Delegate.GetOrCreate(self, self.OnTabSeasonClicked)
    self.tabSeason:FeedData(tabSeasonParam)

    self:OnTabDailyClicked()
end

function ReplicaPVPSettlementRewardsMediator:OnClose(param)
    self:StopDailySettleCountdown()
end

function ReplicaPVPSettlementRewardsMediator:OnShow(param)

end

function ReplicaPVPSettlementRewardsMediator:OnHide(param)

end

function ReplicaPVPSettlementRewardsMediator:OnSecondTicker()
    self:RefreshDailyTimer()
end

function ReplicaPVPSettlementRewardsMediator:StartDailySettleCountdown()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
    self.isTimerStart = true
end

function ReplicaPVPSettlementRewardsMediator:StopDailySettleCountdown()
    if not self.isTimerStart then
        return
    end

    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
    self.isTimerStart = false
end

function ReplicaPVPSettlementRewardsMediator:RefreshDailyTimer()
    local refreshCfgId = ConfigRefer.ReplicaPvpConst:DailyRewardRefresh()
    local refreshCfgCell = ConfigRefer.Refresh:Find(refreshCfgId)
    local nextTimestamp = TimeFormatter.GetRefreshTime(refreshCfgCell, true)
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local leftSeconds = math.max(0, nextTimestamp - now)
    self.txtInfo.text = string.format('%s\n%s', I18N.Get('se_pvp_reward_daymessage'), I18N.GetWithParams('se_pvp_reward_daily_countdown', TimeFormatter.SimpleFormatTime(leftSeconds)))
end

function ReplicaPVPSettlementRewardsMediator:OnTabDailyClicked()
    self:StartDailySettleCountdown()

    self.tabDaily:ChangeSelectTab(true)
    self.tabSeason:ChangeSelectTab(false)
    self:UpdateDailyRewards()
end

function ReplicaPVPSettlementRewardsMediator:OnTabSeasonClicked()
    self:StopDailySettleCountdown()

    self.tabDaily:ChangeSelectTab(false)
    self.tabSeason:ChangeSelectTab(true)
    self:UpdateSeasonRewards()
end

function ReplicaPVPSettlementRewardsMediator:UpdateDailyRewards()
    self:RefreshDailyTimer()

    self.tableRewards:Clear()
    for index, cell in ConfigRefer.PvpTitleStage:inverse_ipairs() do
        ---@type ReplicaPVPSettlementRewardsCellData
        local data = {}
        data.pvpTitleStageConfigCell = cell
        data.itemGroupId = cell:DailySettleReward()
        data.isCurrentRank = cell:Id() == self.myTitleStageTid
        self.tableRewards:AppendData(data)

        if cell:Id() == self.myTitleStageTid then
            self.tableRewards:SetFocusData(data)
        end
    end
end

function ReplicaPVPSettlementRewardsMediator:UpdateSeasonRewards()
    self.txtInfo.text = I18N.Get('se_pvp_reward_seasonmessage')

    self.tableRewards:Clear()
    for index, cell in ConfigRefer.PvpTitleStage:inverse_ipairs() do
        ---@type ReplicaPVPSettlementRewardsCellData
        local data = {}
        data.pvpTitleStageConfigCell = cell
        data.itemGroupId = cell:SettleReward()
        data.isCurrentRank = cell:Id() == self.myTitleStageTid
        self.tableRewards:AppendData(data)

        if cell:Id() == self.myTitleStageTid then
            self.tableRewards:SetFocusData(data)
        end
    end
end

return ReplicaPVPSettlementRewardsMediator