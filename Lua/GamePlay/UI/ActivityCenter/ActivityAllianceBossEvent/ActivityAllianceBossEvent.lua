---@scene scene_child_activity_world_events_big
local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityType = require('DBEntityType')
local AllianceBossEventState = require("AllianceBossEventState")
local TimeFormatter = require("TimeFormatter")
local TimerUtility = require("TimerUtility")
local GetTopListParameter = require("GetTopListParameter")
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local ReceiveScoreRewardParameter = require("ReceiveScoreRewardParameter")
local UIHelper = require("UIHelper")
local ObjectType = require("ObjectType")
local KingdomMapUtils = require("KingdomMapUtils")

---@class ActivityAllianceBossEvent : BaseUIComponent
---@field tabID number
---@field activityExpeditionConfig AllianceActivityExpeditionConfigCell
---@field expeditionConfig WorldExpeditionTemplateConfigCell
---@field expeditionNode wds.AllianceExpeditionNode
---@field timer Timer
---@field currentAllianceRank number
local ActivityAllianceBossEvent = class("ActivityAllianceBossEvent", BaseUIComponent)

function ActivityAllianceBossEvent:OnCreate()
    self.p_text_title = self:Text("p_text_title", "alliance_activity_big1")
    self.p_text_time = self:Text("p_text_time")
    self.p_text_describe = self:Text("p_text_describe", "alliance_activity_big2")
    self.p_status_content = self:StatusRecordParent("p_status_content")

    self.p_text_start = self:Text("p_text_start", "alliance_worldevent_end1")
    self.p_text_wait = self:Text("p_text_wait", "alliance_behemoth_activity_tips1")
    self.p_text_count_down = self:Text("p_text_count_down")
    self.p_text_reward = self:Text("p_text_reward", "leaderboard_info_8")
    self.p_table_award = self:TableViewPro("p_table_award")
    self.p_text_goto = self:Text("p_text_goto", "city_competition_join")
    self.p_text_reward_wait = self:Text("p_text_reward_wait", "guide_allnotjoin_desc")
    self.p_goto = self:GameObject("p_goto")
    self.p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGoToAllianceClick))
    self.p_btn_reward = self:Button("p_btn_reward", Delegate.GetOrCreate(self, self.OnInfoClicked))

    ---@type PlayerInfoComponent
    self.child_ui_head_player = self:LuaObject("child_ui_head_player")
    self.p_btn_player_score_list = self:Button("p_btn_player_score_list", Delegate.GetOrCreate(self, self.OnPlayerInfoClicked))
    self.p_progress_player = self:Slider("p_progress_player")
    self.p_table_reward_player = self:TableViewPro("p_table_reward_player")
    self.p_reward_player_rect = self:RectTransform("p_progress_player")
    self.p_text_rank_player = self:Text("p_text_rank_player")
    self.p_text_score_player = self:Text("p_text_score_player")
    self.p_text_score_player_1 = self:Text("p_text_score_player_1", "alliance_activity_big31")
    ---@type CommonAllianceLogoComponent
    self.child_league_logo = self:LuaObject("child_league_logo")
    self.p_btn_league_score_list = self:Button("p_btn_league_score_list", Delegate.GetOrCreate(self, self.OnAllianceInfoClicked))
    self.p_progress_league = self:Slider("p_progress_league")
    self.p_table_reward_league = self:TableViewPro("p_table_reward_league")
    self.p_reward_league_rect = self:RectTransform("p_progress_league")
    self.p_text_rank_league = self:Text("p_text_rank_league")
    self.p_text_score_league = self:Text("p_text_score_league")
    self.p_text_score_league_1 = self:Text("p_text_score_league_1", "alliance_activity_big32")
    self.p_text_hint = self:Text("p_text_hint", "alliance_activity_big6")
    self.p_text_league_score_limit = self:Text("p_text_league_score_limit")
    ---@type CommonPairsQuantity
    self.child_common_quantity = self:LuaObject("child_common_quantity")
    self.p_btn_n = self:Button("p_btn_n", Delegate.GetOrCreate(self, self.OnGoToBossClicked))
    self.p_text_n = self:Text("p_text_n", "alliance_activity_big7")
    self.p_text_count_down_activity = self:Text("p_text_count_down_activity", "alliance_worldevent_end1")
    self.p_text_time_activity = self:Text("p_text_time_activity")
    self.p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnInfoClicked))

end

---@param data ActivityCenterOpenParam
function ActivityAllianceBossEvent:OnFeedData(data)
    self.tabID = data.tabId
    self.activityExpeditionConfig = ModuleRefer.AllianceBossEventModule:GetActivityExpeditionConfigByTab(data.tabId)
    if not self.activityExpeditionConfig then
        g_Logger.Error("can't find activityExpeditionConfig.")
        return
    end

    local startTime, endTime = ModuleRefer.AllianceBossEventModule:GetStartEndTime(self.activityExpeditionConfig)
    local startTimeStr = TimeFormatter.TimeToLocalTimeZoneDateTimeStringUseFormat(startTime, "yyyy/MM/dd HH:mm:ss")
    local endTimeStr = TimeFormatter.TimeToLocalTimeZoneDateTimeStringUseFormat(endTime, "yyyy/MM/dd HH:mm:ss")
    self.p_text_time.text = I18N.GetWithParams("alliance_activity_pet_02", startTimeStr .. "~" .. endTimeStr)

    self:RefreshState()
    self:Tick()
end

function ActivityAllianceBossEvent:OnShow()
    g_Game.ServiceManager:AddResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
    g_Game.ServiceManager:AddResponseCallback(ReceiveScoreRewardParameter.GetMsgId(), Delegate.GetOrCreate(self,self.RefreshStageRewards))
end

function ActivityAllianceBossEvent:OnHide()
    g_Game.ServiceManager:RemoveResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
    g_Game.ServiceManager:RemoveResponseCallback(ReceiveScoreRewardParameter.GetMsgId(), Delegate.GetOrCreate(self,self.RefreshStageRewards))
    if self.timer then
        self.timer:Reset()
        self.timer = nil
    end
end

function ActivityAllianceBossEvent:Tick()
    local state, remainingTime = ModuleRefer.AllianceBossEventModule:GetEventStateAndRemainTime(self.activityExpeditionConfig)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        self.p_text_count_down.text = TimeFormatter.SimpleFormatTime(remainingTime)
        return
    end
    
    if state == AllianceBossEventState.Active then
        self.p_text_time_activity.text = TimeFormatter.SimpleFormatTime(remainingTime)
    else
        self.p_text_count_down.text = TimeFormatter.SimpleFormatTime(remainingTime)
    end
    if remainingTime <= 0 then
        self:RefreshState()
    end
end

function ActivityAllianceBossEvent:RefreshState()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        self:RefreshPreview()
        self:RefreshTimer()
        return
    end

    local state, remainingTime = ModuleRefer.AllianceBossEventModule:GetEventStateAndRemainTime(self.activityExpeditionConfig)
    if state == AllianceBossEventState.Active then
        self:RefreshActive()
    else
        self:RefreshPreview()
    end
    self:RefreshTimer()
end

function ActivityAllianceBossEvent:RefreshPreview()
    self.p_status_content:SetState(1)

    local isInAlliance = ModuleRefer.AllianceModule:IsInAlliance()
    self.p_text_reward_wait:SetVisible(false)
    self.p_text_wait:SetVisible(not isInAlliance)
    self.p_goto:SetVisible(not isInAlliance)

    local rewards = ModuleRefer.AllianceBossEventModule:GetPreviewRewards(self.activityExpeditionConfig)
    self.p_table_award:Clear()
    for _, itemID in ipairs(rewards) do
        ---@type ItemIconData
        local itemIcon = {}
        itemIcon.configCell = ConfigRefer.Item:Find(itemID)
        itemIcon.showCount = false
        self.p_table_award:AppendData(itemIcon)
    end
    self.p_table_award:RefreshAllShownItem()
end

function ActivityAllianceBossEvent:RefreshActive()
    self.p_status_content:SetState(0)
    --player & alliance
    local player = ModuleRefer.PlayerModule:GetPlayer()
    self.child_ui_head_player:FeedData(player.Owner)
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    self.child_league_logo:FeedData(allianceData.AllianceBasicInfo.Flag)

    self:RefreshRankData()
    self:RefreshStageRewards()
  
    --rank
    self.p_text_rank_player.text = I18N.GetWithParams("alliance_activity_big5", string.Empty)
    self.p_text_rank_league.text = I18N.GetWithParams("alliance_activity_big5", string.Empty)

   
end

function ActivityAllianceBossEvent:RefreshTimer()
    if self.timer then
        self.timer:Reset()
        self.timer = nil
    end
    self.timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.Tick), 1, -1)
end

function ActivityAllianceBossEvent:RefreshStageRewards()
    local scoreRewardConfig = ModuleRefer.AllianceBossEventModule:GetScoreRewardConfig(self.activityExpeditionConfig)
    local playerScoreLimits = {}
    local allianceScoreLimits = {}
    
    --personal rewards
    self.p_table_reward_player:Clear()
    local playerRewardLength = scoreRewardConfig:PlayerStageRewardLength()
    local playerSize = self.p_reward_player_rect.rect.size
    for i = 1, playerRewardLength do
        local itemGroupID = scoreRewardConfig:PlayerStageReward(i)
        local score = scoreRewardConfig:PlayerStageRewardScoreLimit(i)
        table.insert(playerScoreLimits, score)
        ---@type AllianceBossEventRewardParameter
        local rewardParam =
        {
            index = i,
            score = score,
            itemGroupID = itemGroupID,
            type = wrpc.AllianceScoreRewardReceiveType.AllianceScoreRewardReceiveTypePersonal,
            posX = playerSize.x * i / playerRewardLength,
            activityExpeditionConfig = self.activityExpeditionConfig
        }
        self.p_table_reward_player:AppendData(rewardParam)
    end
    self.p_table_reward_player:RefreshAllShownItem()
    
    --alliance rewards
    self.p_table_reward_league:Clear()
    local allianceRewardLength = scoreRewardConfig:AllianceStageRewardLength()
    local allianceSize = self.p_reward_league_rect.rect.size
    for i = 1, allianceRewardLength do
        local itemGroupID = scoreRewardConfig:AllianceStageReward(i)
        local score = scoreRewardConfig:AllianceStageRewardScoreLimit(i)
        table.insert(allianceScoreLimits, score)
        ---@type AllianceBossEventRewardParameter
        local rewardParam =
        {
            index = i,
            score = score,
            itemGroupID = itemGroupID,
            type = wrpc.AllianceScoreRewardReceiveType.AllianceScoreRewardReceiveTypeAlliance,
            posX = allianceSize.x * i / allianceRewardLength,
            activityExpeditionConfig = self.activityExpeditionConfig

        }
        self.p_table_reward_league:AppendData(rewardParam)
    end
    self.p_table_reward_league:RefreshAllShownItem()

    --personal scores
    local playerScore = ModuleRefer.AllianceBossEventModule:GetPersonalScore(self.activityExpeditionConfig)
    self.p_progress_player.value = ModuleRefer.AllianceBossEventModule:GetRewardProgress(playerScore, playerScoreLimits)
    self.p_text_score_player.text = tostring(playerScore)
    --alliance scores
    local allianceScore = ModuleRefer.AllianceBossEventModule:GetAllianceScore(self.activityExpeditionConfig)
    self.p_progress_league.value = ModuleRefer.AllianceBossEventModule:GetRewardProgress(allianceScore, allianceScoreLimits)
    self.p_text_score_league.text = tostring(allianceScore)
    self.p_text_league_score_limit.text = I18N.GetWithParams("alliance_activity_big18", scoreRewardConfig:PlayerScoreLimitForAllianceReward())

    --quantity pairs
    local itemID = self.activityExpeditionConfig:UseItems(1)
    local itemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemID)
    local itemCountMax = self.activityExpeditionConfig:UseItemsCount(1)
    ---@type CommonPairsQuantityParameter
    local quantityParam =
    {
        compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST,
        itemId = itemID,
        num1 = itemCount,
        num2 = itemCountMax,
        onClick = function()
            ---@type CommonItemDetailsParameter
            local tipParam = 
            {
                itemId = itemID,
                itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
                clickTransform = self.child_common_quantity:Transform('')
            }
            g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, tipParam)
        end,
    }
    self.child_common_quantity:FeedData(quantityParam)

    ModuleRefer.ActivityCenterModule:UpdateRedDotByTabId(self.tabID)
end

function ActivityAllianceBossEvent:RefreshRankData(callback)
    local leaderboardActivityConfig = ConfigRefer.LeaderboardActivity:Find(self.activityExpeditionConfig:LeaderboardConfig())
    ModuleRefer.LeaderboardModule:SendGetTopList(leaderboardActivityConfig:RelateLeaderboard(), 1, 100, function()
        if callback then
            callback()
        end
    end)
end

---@param isSuccess boolean
---@param reply wrpc.GetTopListReply
function ActivityAllianceBossEvent:OnGetTopListResponse(isSuccess, reply, req)
    if not isSuccess then
        return
    end
    
    self.currentAllianceRank = reply.PlayerInfo.Rank

    local playerScore = ModuleRefer.AllianceBossEventModule:GetPersonalScore(self.activityExpeditionConfig)
    self.p_text_rank_player.text = I18N.GetWithParams("alliance_activity_big5", playerScore)
    
    local allianceRank = reply.PlayerInfo.Rank
    if allianceRank > 0 then
        self.p_text_rank_league.text = I18N.GetWithParams("alliance_activity_big3", allianceRank)
    else
        self.p_text_rank_league.text = I18N.Get("alliance_activity_big8")
    end
end

function ActivityAllianceBossEvent:OnGoToAllianceClick()
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
    g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
end

function ActivityAllianceBossEvent:OnInfoClicked()
    self:RefreshRankData(function()self:ShowInfo(1)  end)
    
end

function ActivityAllianceBossEvent:OnPlayerInfoClicked()
    self:RefreshRankData(function()self:ShowInfo(2)  end)
end

function ActivityAllianceBossEvent:OnAllianceInfoClicked()
    self:RefreshRankData(function()self:ShowInfo(3)  end)
end

function ActivityAllianceBossEvent:ShowInfo(tab)
    local content1List = {}
    table.insert(content1List, {title = "alliance_activity_pet_20"})
    table.insert(content1List, {rule = I18N.Get("alliance_activity_big10")})
    ---@type CommonPlainTextContent
    local content1 = {list = content1List}

    local playerScore = ModuleRefer.AllianceBossEventModule:GetPersonalScore(self.activityExpeditionConfig)
    local myRank = 0
    local content2List = {}
    table.insert(content2List, {title = "alliance_activity_big11"})
    local scoreRewardConfig = ModuleRefer.AllianceBossEventModule:GetScoreRewardConfig(self.activityExpeditionConfig)
    local settleRewardLength = scoreRewardConfig:SettleRewardLength()
    for i = settleRewardLength, 1, -1 do
        local scoreLimit = scoreRewardConfig:SettleRewardRangeMaxScore(i)
        if playerScore >= scoreLimit then
            myRank = i
            break
        end
    end
    for i = settleRewardLength, 1, -1 do
        local scoreLimit = scoreRewardConfig:SettleRewardRangeMaxScore(i)
        local reward = ConfigRefer.ItemGroup:Find(scoreRewardConfig:SettleReward(i))
        local iconDataList = {}
        for j = 1, reward:ItemGroupInfoListLength() do
            local itemGroupInfo = reward:ItemGroupInfoList(j)
            ---@type ItemIconData
            local iconData =
            {
                configCell = ConfigRefer.Item:Find(itemGroupInfo:Items()),
                showCount = true,
                count = itemGroupInfo:Nums(),
            }
            table.insert(iconDataList, iconData)
        end
        local rule = I18N.GetWithParams("alliance_activity_big18", scoreLimit)
        local isSelected = myRank == i
        table.insert(content2List, {rule = rule, isSelected = isSelected})
        table.insert(content2List, {reward = iconDataList, isSelected = isSelected})
    end
    ---@type CommonPlainTextContent
    local content2 =
    {
        selectedIndex = settleRewardLength - myRank + 1,
        list = content2List,
    }

    local content3List = {}
    table.insert(content3List, {title = "alliance_activity_big44"})
    local leaderboardActivityID = self.activityExpeditionConfig:LeaderboardConfig()
    local rewardInfos = ModuleRefer.LeaderboardModule:GetActivityLeaderboardRankReward(leaderboardActivityID, true)
    local index = 1
    for _, rewardInfo in ipairs(rewardInfos) do
        local from = rewardInfo.from
        local to = rewardInfo.to
        local reward = rewardInfo.reward
        local rule = "city_competition_rank_num"
        if from == to then
            rule = I18N.GetWithParams(rule, from)
        elseif to > 0 then
            rule = I18N.GetWithParams(rule, ("%d-%d"):format(from, to))
        --else
        --    rule = I18N.GetWithParams(rule, ("%d-"):format(from))
        end
        local isSelected = self.currentAllianceRank == index
        table.insert(content3List, { rule = rule, isSelected = isSelected})
        table.insert(content3List, { reward = reward, isSelected = isSelected})
        index = index + 1
    end
    ---@type CommonPlainTextContent
    local content3 =
    {
        selectedIndex = #rewardInfos - self.currentAllianceRank + 1,
        list = content3List,
    }

    local leaderboardActivityConfig = ConfigRefer.LeaderboardActivity:Find(leaderboardActivityID)
    local content4 =
    {
        title = I18N.Get("alliance_activity_big20"),
        tip = I18N.Get("alliance_activity_big13"),
        leaderboardId = leaderboardActivityConfig:RelateLeaderboard(),
    }

    ---@type CommonPlainTextInfoParam
    local data = {}
    data.tabs = { "sp_chat_icon_copy", "sp_common_icon_reward_1", "sp_common_icon_reward_2", "sp_comp_icon_list"}
    data.contents = {content1, content2, content3, content4}
    data.title = I18N.Get("alliance_activity_big1")
    data.leaderboardActivityID = leaderboardActivityID
    data.startTab = tab
    g_Game.UIManager:Open(UIMediatorNames.CommonPlainTextInfoMediator, data)
end

function ActivityAllianceBossEvent:OnGoToBossClicked()
	local itemID = self.activityExpeditionConfig:UseItems(1)
	local itemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemID)
	local itemCountMax = self.activityExpeditionConfig:UseItemsCount(1)
	
	if itemCount < itemCountMax and not ModuleRefer.AllianceBossEventModule:HasCanClaimPlayerReward(self.tabID) then
		UIHelper.ShowConfirm(I18N.Get("alliance_activity_big45"), nil, function()
			---@type RadarMediatorParam
			local param =
			{
				isInCity = KingdomMapUtils.IsCityState(),
				stack = KingdomMapUtils.GetBasicCamera():RecordCurrentCameraStatus(),
				enterSelectBubbleType = ObjectType.SlgMob,
			}
			g_Game.UIManager:Open(UIMediatorNames.RadarMediator, param)
		end)
		return
	end
	
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
    ModuleRefer.AllianceBossEventModule:GotoAllianceBoss()
end

return ActivityAllianceBossEvent