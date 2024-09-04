local ModuleRefer = require('ModuleRefer')
local BaseModule = require('BaseModule')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require("UIMediatorNames")
local I18N = require('I18N')
local NotificationType = require('NotificationType')
local CommonDailyGiftState = require('CommonDailyGiftState')

local LeaderboardType = require('LeaderboardType')
local LeaderboardHeadType = require('LeaderboardHeadType')
local LeaderElementTextType = require('LeaderElementTextType')
local LeaderElementIconType = require('LeaderElementIconType')

---@class LeaderboardModule : BaseModule
local LeaderboardModule = class('LeaderboardModule', BaseModule)

function LeaderboardModule:ctor()
    ---@type CS.Notification.NotificationDynamicNode
	self._redDotHonorTab = nil
	---@type CS.Notification.NotificationDynamicNode
	self._redDotHonorDailyReward = nil
end

function LeaderboardModule:OnRegister()
    -- 刷新红点
    self:BuildRedDotTree()
    -- UI和配置的映射
    self:Prepare()
end

function LeaderboardModule:OnRemove()
    -- 重载此函数
end

function LeaderboardModule:Prepare()
    ---UI驱动配置，配置驱动程序!!!
    ---@type table<number, number> @LeaderElementTextType, LeaderboardHeadType
    self.config_ui_mapping = {}
    for k, v in pairs(LeaderElementIconType) do
        self.config_ui_mapping[v] = {}
    end

    for _, cell in ConfigRefer.LeaderElement:ipairs() do
        local iconType = cell:IconType()
        local textType = cell:TextType()
        self.config_ui_mapping[iconType][textType] = cell:HeadType()
    end
end

-- 刷新红点
function LeaderboardModule:BuildRedDotTree()
    -- 名人堂每日奖励
    if (not self._redDotHonorDailyReward) then
        self._redDotHonorDailyReward = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("leaderboard_honor_daily_reward", NotificationType.LEADERBOARD_HONOR_DAILY_REWARD)
    end

    -- 名人堂Tab
    if (not self._redDotHonorTab) then
        self._redDotHonorTab = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("leaderboard_honor_tab", NotificationType.LEADERBOARD_HONOR_TAB)
        ModuleRefer.NotificationModule:AddToParent(self._redDotHonorDailyReward, self._redDotHonorTab)
    end

    -- 设置界面排行榜入口红点
	if (not self._redDotLeaderboardEntry) then
        self._redDotLeaderboardEntry = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("leaderboard_entry", NotificationType.LEADERBOARD_ENTRY)
        ModuleRefer.NotificationModule:AddToParent(self._redDotHonorTab, self._redDotLeaderboardEntry)
    end

    -- 主界面Hud，玩家头像红点
	if (not self._redDotHudPlayerHead) then
        self._redDotHudPlayerHead = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("city_hud_player_head", NotificationType.CITY_HUD_PLAYER_HEAD)
        ModuleRefer.NotificationModule:AddToParent(self._redDotLeaderboardEntry, self._redDotHudPlayerHead)
    end
end

function LeaderboardModule:AttachHonorDailyRewardRedDot(go)
    ModuleRefer.NotificationModule:AttachToGameObject(self._redDotHonorDailyReward, go)
end

-- 将UI和红点逻辑节点绑定
function LeaderboardModule:AttachLeaderboardHonorTabRedDot(go)
    ModuleRefer.NotificationModule:AttachToGameObject(self._redDotHonorTab, go)
end

function LeaderboardModule:AttachLeaderboardEntryRedDot(go)
    ModuleRefer.NotificationModule:AttachToGameObject(self._redDotLeaderboardEntry, go)
end

function LeaderboardModule:AttachHudPlayerHeadRedDot(go)
    ModuleRefer.NotificationModule:AttachToGameObject(self._redDotHudPlayerHead, go)
end

function LeaderboardModule:SetHonorDailyRewardRedDot(number)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self._redDotHonorDailyReward, number)
end

function LeaderboardModule:IsLeaderboardActivityOpened(leaderboardId)
    local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
    for _, cell in ConfigRefer.LeaderboardActivity:ipairs() do
        if cell:RelateLeaderboard() == leaderboardId then
            local tempId = cell:ControlActivity()
            local activityEntry = kingdom.ActivityInfo.Activities[tempId]
            return activityEntry and activityEntry.Open
        end
    end

    return false
end

-- 筛选二级目录
---@param type LeaderboardType
function LeaderboardModule:GetLeaderboardCellsByType(type)
    local list = {}
    for _, cell in ConfigRefer.Leaderboard:ipairs() do
        if cell:Type() == type then
            if cell:Type() == LeaderboardType.Activity and not self:IsLeaderboardActivityOpened(cell:Id()) then
                goto continue
            end
            if cell:IndependentDisplay() then
                goto continue
            end

            table.insert(list, cell)
        end

        ::continue::
    end

    return list
end

---@param type LeaderboardType
function LeaderboardModule:GetMainTabTitle(type)
    if type == LeaderboardType.Personal then
        return I18N.Get('leaderboard_typeName_2')
    elseif type == LeaderboardType.Alliance then
        return I18N.Get('leaderboard_typeName_3')
    elseif type == LeaderboardType.Activity then
        return I18N.Get('leaderboard_typeName_4')
    end

    return I18N.Get('leaderboard_typeName_1')
end

---@param leaderElementConfigCell LeaderElementConfigCell
function LeaderboardModule:GetLeaderboardHeadTypeIndex(leaderElementConfigCell)
    local iconType = leaderElementConfigCell:IconType()
    local textType = leaderElementConfigCell:TextType()
    if table.ContainsKey(self.config_ui_mapping, iconType) then
        local textTypeMapping = self.config_ui_mapping[iconType]
        if table.ContainsKey(textTypeMapping, textType) then
            return textTypeMapping[textType]
        end
    end

    g_Logger.Error('icontype %s texttype %s not found', iconType, textType)
    return LeaderboardHeadType.Rank
end

function LeaderboardModule:GetRankIcon(rank)
    if rank == 1 then return 'sp_activity_ranking_icon_top_1' end
    if rank == 2 then return 'sp_activity_ranking_icon_top_2' end
    if rank == 3 then return 'sp_activity_ranking_icon_top_3' end
    return 'sp_activity_ranking_icon_top_4'
end

function LeaderboardModule:GetRankItemBackgroundImagePath(rank, isMine)
    if isMine then return 'sp_activity_ranking_base_mine' end
    if rank == 1 then return 'sp_activity_ranking_base_1' end
    if rank == 2 then return 'sp_activity_ranking_base_2' end
    if rank == 3 then return 'sp_activity_ranking_base_3' end
    return 'sp_activity_ranking_base_4'
end

function LeaderboardModule:UpdateDailyRewardState()
    local state = self:GetDailyRewardState()
    if state == CommonDailyGiftState.CanCliam then
        ModuleRefer.LeaderboardModule:SetHonorDailyRewardRedDot(1)
    else
        ModuleRefer.LeaderboardModule:SetHonorDailyRewardRedDot(0)
    end
end

function LeaderboardModule:GetDailyRewardState()
    if not self:IsHonorPageUnlock() or not self:IsLeadboardUnlock() then
        return CommonDailyGiftState.NotReach
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    if player.PlayerWrapper3.PlayerTopList.DailyReward.DailyRewardReceived then
        return CommonDailyGiftState.HasCliamed
    end

    return CommonDailyGiftState.CanCliam
end

---@param isOpen boolean 是否是开启状态
function LeaderboardModule:GetDailyRewardBoxIcon(isOpen)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local index = player.PlayerWrapper3.PlayerTopList.DailyReward.DailyRewardIndex
    if isOpen then
        local length = ConfigRefer.LeaderBoardConst:DailyRankRewardOpenedIconLength()
        if index > 0 and index <= length then
            return ConfigRefer.LeaderBoardConst:DailyRankRewardOpenedIcon(index)
        end
    else
        local length = ConfigRefer.LeaderBoardConst:DailyRankRewardIconLength()
        if index > 0 and index <= length then
            return ConfigRefer.LeaderBoardConst:DailyRankRewardIcon(index)
        end
    end
end

function LeaderboardModule:GetDailyRewardItemGroupId()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local index = player.PlayerWrapper3.PlayerTopList.DailyReward.DailyRewardIndex
    local itemGroupId = 0
    if index > 0 and index <= ConfigRefer.LeaderBoardConst:DailyRankRewardLength() then
        itemGroupId = ConfigRefer.LeaderBoardConst:DailyRankReward(index)
    end

    return itemGroupId
end

---@return number 刷新时间，秒
function LeaderboardModule:GetDailyRewardRefreshTimestamp()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    return player.PlayerWrapper3.PlayerTopList.DailyReward.DailyRewardRefreshTimestamp
end

function LeaderboardModule:IsLeadboardUnlock()
    local systemEntryId = ConfigRefer.LeaderBoardConst:UnlockSystemEntry()
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemEntryId)
end

function LeaderboardModule:IsHonorPageUnlock()
    local systemEntryId = ConfigRefer.LeaderBoardConst:HonorUnlockSystemEntry()
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemEntryId)
end

function LeaderboardModule:SendGetHonorTopList()
    local req = require('GetHonorTopListParameter').new()
    req:SendWithFullScreenLock()
end

---@param leaderboardId number LeaderboardConfigCell的Id
---@param beginIndex number 开始的index从1开始
---@param count number 请求的数量
function LeaderboardModule:SendGetTopList(leaderboardId, beginIndex, count, callback)
    local req = require('GetTopListParameter').new()
    req.args.TopListTid = leaderboardId
    req.args.Start = beginIndex
    req.args.Num = count
    req:SendWithFullScreenLockAndOnceCallback(nil, nil, callback)
end

---@class LeaderboardActivityRankRewardInfo
---@field from number
---@field to number
---@field reward ItemIconData[]

---@param cfgId number @LeaderboardActivity id
---@return LeaderboardActivityRankRewardInfo[]
function LeaderboardModule:GetActivityLeaderboardRankReward(cfgId, excludeLeft)
    local ret = {}
    local cfg = ConfigRefer.LeaderboardActivity:Find(cfgId)
    if not cfg then
        return ret
    end
    local length = excludeLeft and cfg:RewardRankLength() - 1 or cfg:RewardRankLength()
    for i = 1, length do
        ---@type LeaderboardActivityRankRewardInfo
        local info = {}
        info.from = cfg:RewardRank(i)
        if i < cfg:RewardRankLength() then
            info.to = cfg:RewardRank(i + 1) - 1
        else
            info.to = -1
        end
        if excludeLeft and i == length then
            info.to = info.to + 1
        end
        info.reward = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(cfg:RewardItemGroup(i))
        table.insert(ret, info)
    end
    return ret
end

---@param config LeaderboardActivityConfigCell
---@return number @ItemGroup
function LeaderboardModule:GetActivityLeaderboardRankRewardByRank(config, myRank)
    local rankLength = config:RewardRankLength()
    for i = 1, rankLength do
        local rank = config:RewardRank(i)
        if myRank >= rank then
            return config:RewardItemGroup(i)
        end
    end
    return 0
end

return LeaderboardModule
