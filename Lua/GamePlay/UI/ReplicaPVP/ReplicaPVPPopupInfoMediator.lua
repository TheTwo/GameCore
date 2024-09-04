---scene: scene_se_pvp_popup_info
local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local TimeFormatter = require("TimeFormatter")

---@class ReplicaPVPPopupInfoMediatorParameter

---@class ReplicaPVPPopupInfoMediator:BaseUIMediator
---@field new fun():ReplicaPVPPopupInfoMediator
---@field super BaseUIMediator
local ReplicaPVPPopupInfoMediator = class('ReplicaPVPPopupInfoMediator', BaseUIMediator)

function ReplicaPVPPopupInfoMediator:OnCreate(param)
    self.tableTabs = self:TableViewPro('p_table_tab')

    -- 规则说明界面
    self.panelRule = self:GameObject('p_group_rule')
    self.textTitle = self:Text('p_text_title', 'se_pvp_backgroundstory_title')
    self.textContent = self:Text('p_text_rule', 'se_pvp_backgroundstory_desc')

    -- 段位说明页面
    self.panelInfo = self:GameObject('p_lv_info')
    self.txtInfo = self:Text('p_text_info', 'se_pvp_levelmessage_message')
    ---table的标题
    self.txtHeadType = self:Text('p_text_type', 'se_pvp_levelmessage_level')
    self.txtHeadReward = self:Text('p_text_award', 'se_pvp_levelmessage_reward2')
    self.txtHeadState = self:Text('p_text_state', 'se_pvp_levelmessage_state')
    ---@type table<number, Text>
    self.txtRanks = {}
    self.txtRanks[1] = self:Text('p_text_level_1')
    self.txtRanks[2] = self:Text('p_text_level_2')
    self.txtRanks[3] = self:Text('p_text_level_3')
    self.txtRanks[4] = self:Text('p_text_level_4')
    self.txtRanks[5] = self:Text('p_text_level_5')
    self.txtRanks[6] = self:Text('p_text_level_6')
    self.txtRanks[7] = self:Text('p_text_level_7')
    ---@type table<number, Text>
    self.txtPoints = {}
    self.txtPoints[1] = self:Text('p_text_integer_1')
    self.txtPoints[2] = self:Text('p_text_integer_2')
    self.txtPoints[3] = self:Text('p_text_integer_3')
    self.txtPoints[4] = self:Text('p_text_integer_4')
    self.txtPoints[5] = self:Text('p_text_integer_5')
    self.txtPoints[6] = self:Text('p_text_integer_6')
    self.txtPoints[7] = self:Text('p_text_integer_7')
    self.txtMyPoints = self:Text('p_text_integer')
    self.txtMyRank = self:Text('p_text_level')
    self.imageMyLevelIcon = self:Image('p_icon_level')

    -- 段位直接奖励页面
    self.panelSettleReward = self:GameObject('p_lv_reward')
    self.txtReward = self:Text('p_text_reward', 'se_pvp_levelmessage_levelup')
    self.textTitleView = self:Text('p_text_type_view', 'se_pvp_levelmessage_level')
    self.textRewardView = self:Text('p_text_award_view', 'se_pvp_levelmessage_reward2')
    self.tableRewardsView = self:TableViewPro('p_table_reward_view')

    -- 段位结算奖励界面
    self.panelReward = self:GameObject('p_view_reward')
    self.textChallenge = self:Text('p_text_challenge')
    self.tableRewards = self:TableViewPro('p_table_reward')
end

---@param data ReplicaPVPPopupInfoMediatorParameter
function ReplicaPVPPopupInfoMediator:OnOpened(param)
    -- 规则
    ---@type CommonButtonTab
    local tabRuleParam = {}
    tabRuleParam.text = I18N.Get('se_pvp_main_name')
    tabRuleParam.callback = Delegate.GetOrCreate(self, self.OnTabRuleClicked)
    self.tableTabs:AppendData(tabRuleParam)

    -- 段位说明
    ---@type CommonButtonTabParameter
    local tabInfoParam = {}
    tabInfoParam.text = I18N.Get('se_pvp_levelmessage_name')
    tabInfoParam.callback = Delegate.GetOrCreate(self, self.OnTabInfoClicked)
    self.tableTabs:AppendData(tabInfoParam)

    -- 段位提升奖励
    ---@type CommonButtonTabParameter
    local tabRewardParam = {}
    tabRewardParam.text = I18N.Get('se_pvp_levelmessage_reward')
    tabRewardParam.callback = Delegate.GetOrCreate(self, self.OnTabRewardClicked)
    self.tableTabs:AppendData(tabRewardParam)

    -- 段位每日结算奖励
    ---@type CommonButtonTabParameter
    local tabDailyParam = {}
    tabDailyParam.text = I18N.Get('se_pvp_reward_day')
    tabDailyParam.callback = Delegate.GetOrCreate(self, self.OnTabDailyClicked)
    self.tableTabs:AppendData(tabDailyParam)

    -- 段位赛季结算奖励
    ---@type CommonButtonTabParameter
    local tabSeasonParam = {}
    tabSeasonParam.text = I18N.Get('se_pvp_reward_season')
    tabSeasonParam.callback = Delegate.GetOrCreate(self, self.OnTabSeasonClicked)
    self.tableTabs:AppendData(tabSeasonParam)

    self.tableTabs:SetToggleSelectIndex(0)
    self:OnTabRuleClicked()

end

function ReplicaPVPPopupInfoMediator:OnClose(param)

end

function ReplicaPVPPopupInfoMediator:OnShow(param)

end

function ReplicaPVPPopupInfoMediator:OnHide(param)

end

function ReplicaPVPPopupInfoMediator:OnTabInfoClicked()
    self.panelInfo:SetActive(true)
    self.panelSettleReward:SetActive(false)
    self.panelRule:SetActive(false)
    self:UpdateTabInfo()
end

function ReplicaPVPPopupInfoMediator:OnTabRewardClicked()
    self.panelInfo:SetActive(false)
    self.panelSettleReward:SetActive(true)
    self.panelReward:SetActive(false)
    self.panelRule:SetActive(false)
    self:UpdateTabReward()
end

function ReplicaPVPPopupInfoMediator:OnTabRuleClicked()
    self.panelInfo:SetActive(false)
    self.panelSettleReward:SetActive(false)
    self.panelReward:SetActive(false)
    self.panelRule:SetActive(true)
    self:UpdateTabRule()
end

function ReplicaPVPPopupInfoMediator:OnTabSeasonClicked()
    self.panelInfo:SetActive(false)
    self.panelSettleReward:SetActive(false)
    self.panelReward:SetActive(true)
    self.panelRule:SetActive(false)
    self:UpdateSeasonReward()
end

function ReplicaPVPPopupInfoMediator:OnTabDailyClicked()
    self.panelInfo:SetActive(false)
    self.panelSettleReward:SetActive(false)
    self.panelReward:SetActive(true)
    self.panelRule:SetActive(false)
    self:UpdateDailyReward()
end

function ReplicaPVPPopupInfoMediator:UpdateTabInfo()
    for index, cell in ConfigRefer.PvpTitle:ipairs() do
        self.txtRanks[index].text = I18N.Get(cell:Name())
        self.txtPoints[index].text = I18N.Get(cell:Info())
    end

    local myPoints = ModuleRefer.ReplicaPVPModule:GetMyPoints()
    self.txtMyPoints.text = I18N.GetWithParams('se_pvp_levelmessage_selfscore', myPoints)

    local myTitleStageConfigCell = ModuleRefer.ReplicaPVPModule:GetMyPVPTitleStageConfigCell()
    self.txtMyRank.text = I18N.GetWithParams('se_pvp_levelmessage_selflevel', I18N.Get(myTitleStageConfigCell:Name()))
    self:LoadSprite(myTitleStageConfigCell:Icon(), self.imageMyLevelIcon)
end

function ReplicaPVPPopupInfoMediator:UpdateTabReward()
    local myPvpData = ModuleRefer.ReplicaPVPModule:GetMyPvpData()
    local maxTitle = myPvpData.SeasonMaxTitle

    self.tableRewardsView:Clear()
    for index, cell in ConfigRefer.PvpTitleStage:inverse_ipairs() do
        if cell:IMMDReward() == 0 then
            goto continue
        end

        ---@type ReplicaPVPRankRewardCellData
        local data = {}
        data.pvpTitleStageConfigCell = cell
        data.isReached = cell:Id() <= maxTitle
        self.tableRewardsView:AppendData(data)

        ::continue::
    end
end

function ReplicaPVPPopupInfoMediator:UpdateSeasonReward()
    self.textChallenge.text = I18N.Get('se_pvp_reward_seasonmessage')

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

function ReplicaPVPPopupInfoMediator:UpdateDailyReward()
    local refreshCfgId = ConfigRefer.ReplicaPvpConst:DailyRewardRefresh()
    local refreshCfgCell = ConfigRefer.Refresh:Find(refreshCfgId)
    local nextTimestamp = TimeFormatter.GetRefreshTime(refreshCfgCell, true)
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local leftSeconds = math.max(0, nextTimestamp - now)
    self.textChallenge.text = string.format('%s\n%s', I18N.Get('se_pvp_reward_daymessage'), I18N.GetWithParams('se_pvp_reward_daily_countdown', TimeFormatter.SimpleFormatTime(leftSeconds)))
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

function ReplicaPVPPopupInfoMediator:UpdateTabRule()
    -- do nothing
end

return ReplicaPVPPopupInfoMediator