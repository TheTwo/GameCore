local BaseUIMediator = require("BaseUIMediator")
local ModuleRefer = require("ModuleRefer")
local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local RewardHelper = require("RewardHelper")
local RewardShowType = require("RewardShowType")
---@class ActivityAllianceBossRegisterRewardPreviewMediator : BaseUIMediator
local ActivityAllianceBossRegisterRewardPreviewMediator = class("ActivityAllianceBossRegisterRewardPreviewMediator", BaseUIMediator)

---@class ActivityAllianceBossRegisterRewardPreviewMediatorParam
---@field

local TABLE_CELL_TYPE = {
    NORMAL_REWARD = 0,
    TITLE = 1,
    RANK_REWARD = 2
}

function ActivityAllianceBossRegisterRewardPreviewMediator:OnCreate()
    self.stextDesc = self:Text("p_text_detail", "alliance_challengeactivity_rule_reward")
    self.tableReward = self:TableViewPro("p_table_reward")
    self.tableBehemoth = self:TableViewPro("p_table_head")
    ---@see CommonPopupBackLargeComponent
    self.luaBackGround = self:LuaObject("child_popup_base_l")
end

function ActivityAllianceBossRegisterRewardPreviewMediator:OnOpened(param)
    self:UpdateBehemothList()
    self.luaBackGround:FeedData({title = I18N.Get('alliance_behemoth_challenge_gift1')})
    g_Game.EventManager:AddListener(EventConst.ON_ACTIVITY_ALLIANCE_BOSS_REGISTER_BEHEMOTH_CELL_SELECT, Delegate.GetOrCreate(self, self.OnBehemothCellSelect))
end

function ActivityAllianceBossRegisterRewardPreviewMediator:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.ON_ACTIVITY_ALLIANCE_BOSS_REGISTER_BEHEMOTH_CELL_SELECT, Delegate.GetOrCreate(self, self.OnBehemothCellSelect))
end

---@param kMonsterCfg KmonsterDataConfigCell
function ActivityAllianceBossRegisterRewardPreviewMediator:OnBehemothCellSelect(kMonsterCfg)
    self.selectedBehemothCfg = kMonsterCfg
    self:UpdateRewardList()
end

function ActivityAllianceBossRegisterRewardPreviewMediator:UpdateBehemothList()
    self.tableBehemoth:Clear()
    local isBehemothOwn = {}
    local lv = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel()
    ---@type number, AllianceBehemoth
    for _, v in ModuleRefer.AllianceModule.Behemoth:PairsOfBehemoths() do
        isBehemothOwn[v:GetBehemothGroupId()] = true
        ---@type ActivityAllianceBossRegisterRewardPreviewBehemothCellParam
        local data = {}
        data.isSelect = v == ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
        data.kMonsterCfg = v:GetRefKMonsterDataConfig(lv)
        data.isOwn = true
        self.tableBehemoth:AppendData(data)
    end
    for i, v in pairs(ModuleRefer.AllianceModule.Behemoth.BehemothDummyAllList) do
        if not isBehemothOwn[v:GetBehemothGroupId()] then
            ---@type ActivityAllianceBossRegisterRewardPreviewBehemothCellParam
            local data = {}
            data.isSelect = false
            data.kMonsterCfg = v:GetRefKMonsterDataConfig(1)
            data.isOwn = false
            self.tableBehemoth:AppendData(data)
        end
    end
end

function ActivityAllianceBossRegisterRewardPreviewMediator:UpdateRewardList()
    self.tableReward:Clear()
    for _, type in ipairs(ActivityAllianceBossConst.REWARD_TYPE_ORDER) do
        self:FillRewardListByType(type)
    end
end

function ActivityAllianceBossRegisterRewardPreviewMediator:FillRewardListByType(type)
    if type == ActivityAllianceBossConst.REWARD_TYPE.OBSERVE then return end -- 2023.12 观战奖励不显示
    self.tableReward:AppendData({title = ActivityAllianceBossConst.REWARD_TYPE_NAME[type]}, TABLE_CELL_TYPE.TITLE)
    if type == ActivityAllianceBossConst.REWARD_TYPE.VICTORY then
        self:FillVictoryRewardList()
    elseif type == ActivityAllianceBossConst.REWARD_TYPE.RANK then
        self:FillRankRewardList()
    elseif type == ActivityAllianceBossConst.REWARD_TYPE.PARTICIPATE then
        self:FillParticipationRewardList()
    elseif type == ActivityAllianceBossConst.REWARD_TYPE.OBSERVE then
        self:FillObservationRewardList()
    elseif type == ActivityAllianceBossConst.REWARD_TYPE.UPGRADE then
        self:FillUpgradeRewardList()
    end
end

function ActivityAllianceBossRegisterRewardPreviewMediator:FillVictoryRewardList()
    local defeatReward = self.selectedBehemothCfg:DropShow()
    local itemGroup = ConfigRefer.ItemGroup:Find(defeatReward)
    local data = {}
    if itemGroup then
        for i = 1, itemGroup:ItemGroupInfoListLength() do
            local itemInfo = itemGroup:ItemGroupInfoList(i)
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = ConfigRefer.Item:Find(itemInfo:Items())
            iconData.count = itemInfo:Nums()
            iconData.useNoneMask = false
            table.insert(data, iconData)
        end
    end
    self.tableReward:AppendData({rewards = data}, TABLE_CELL_TYPE.NORMAL_REWARD)
end

function ActivityAllianceBossRegisterRewardPreviewMediator:FillRankRewardList()
    local config = ConfigRefer.MapInstanceReward:Find(self.selectedBehemothCfg:InstanceRankReward())
    if not config then return end
    local rankStageCount = config:RewardsLength()
    for i = 1, rankStageCount - 1 do
        local rewardRankInfo = config:Rewards(i)
        ---@type AllianceBehemothAwardTipCellLevelRewardData
        local cellData = {}
        cellData.rank = rewardRankInfo:UnitRewardParam1()
        cellData.lvEnd = rewardRankInfo:UnitRewardParam2()
        cellData.rewards = {}
        if rewardRankInfo:UnitRewardShowType() == RewardShowType.ShowWithNum then
            local groupItem = ConfigRefer.ItemGroup:Find(rewardRankInfo:UnitRewardConf2())
            for j = 1, groupItem:ItemGroupInfoListLength() do
                local itemI = groupItem:ItemGroupInfoList(j)
                ---@type ItemIconData
                local iconData = {}
                iconData.configCell = ConfigRefer.Item:Find(itemI:Items())
                iconData.count = itemI:Nums()
                iconData.useNoneMask = false
                table.insert(cellData.rewards, iconData)
            end
        else
            for j = 1, rewardRankInfo:UnitRewardConfLength() do
                ---@type ItemIconData
                local iconData = {}
                iconData.configCell = ConfigRefer.Item:Find(rewardRankInfo:UnitRewardConf(j))
                iconData.count = 0
                iconData.showCount = false
                iconData.useNoneMask = false
                table.insert(cellData.rewards, iconData)
            end
        end
        self.tableReward:AppendData(cellData, TABLE_CELL_TYPE.RANK_REWARD)
    end
end

function ActivityAllianceBossRegisterRewardPreviewMediator:FillParticipationRewardList()
    local config = ConfigRefer.MapInstanceReward:Find(self.selectedBehemothCfg:InstanceRankReward())
    if not config then return end
    local rankStageCount = config:RewardsLength()
    local rewardRankInfo = config:Rewards(rankStageCount)
    ---@type ItemIconData[]
    local cells = {}
    if rewardRankInfo:UnitRewardShowType() == RewardShowType.ShowWithNum then
        local groupItem = ConfigRefer.ItemGroup:Find(rewardRankInfo:UnitRewardConf2())
        for j = 1, groupItem:ItemGroupInfoListLength()do
            local itemI = groupItem:ItemGroupInfoList(j)
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = ConfigRefer.Item:Find(itemI:Items())
            iconData.count = itemI:Nums()
            iconData.useNoneMask = false
            table.insert(cells, iconData)
        end
    else
        for j = 1, rewardRankInfo:UnitRewardConfLength() do
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = ConfigRefer.Item:Find(rewardRankInfo:UnitRewardConf(j))
            iconData.count = 0
            iconData.showCount = false
            iconData.useNoneMask = false
            table.insert(cells, iconData)
        end
    end
    self.tableReward:AppendData({rewards = cells}, TABLE_CELL_TYPE.NORMAL_REWARD)
end

function ActivityAllianceBossRegisterRewardPreviewMediator:FillObservationRewardList()
    local _, _, observeRewards = SlgTouchMenuHelper.GetMobPreviewRewards(self.selectedBehemothCfg, true)
    if table.isNilOrZeroNums(observeRewards) then return end
    local data = {}
    data.rewards = observeRewards
    self.tableReward:AppendData(data, TABLE_CELL_TYPE.NORMAL_REWARD)
end

function ActivityAllianceBossRegisterRewardPreviewMediator:FillUpgradeRewardList()
    local behemothInfo = ConfigRefer.BehemothData:Find(self.selectedBehemothCfg:BehemothInfo())
    if not behemothInfo then return end
    local mailCfgId = behemothInfo:LevelUpRewardMail()
    local rewardList = RewardHelper.GetMailRewardInItemIconDatas(mailCfgId)
    local data = {}
    data.rewards = rewardList
    self.tableReward:AppendData(data, TABLE_CELL_TYPE.NORMAL_REWARD)
end

return ActivityAllianceBossRegisterRewardPreviewMediator