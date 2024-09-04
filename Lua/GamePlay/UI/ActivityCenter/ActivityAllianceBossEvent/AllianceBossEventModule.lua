local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local AllianceBossEventState = require("AllianceBossEventState")
local AllianceBossEventRewardState = require("AllianceBossEventRewardState")
local KingdomMapUtils = require("KingdomMapUtils")
local SceneType = require("SceneType")

---@class AllianceBossEventModule : BaseModule
local AllianceBossEventModule = class("AllianceBossEventModule", BaseModule)

function AllianceBossEventModule:OnRegister()
end

function AllianceBossEventModule:OnRemove()
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:RequestClaimReward(activityExpeditionConfig, index, type)
    local scoreRewardConfig = self:GetScoreRewardConfig(activityExpeditionConfig)
    if scoreRewardConfig then
        local parameter = require("ReceiveScoreRewardParameter").new()
        parameter.args.CfgId = scoreRewardConfig:Id()
        parameter.args.Type = type
        parameter.args.RewardIndex = index - 1
        parameter:SendWithFullScreenLock()
    end
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
---@return number[] @ItemConfigCell
function AllianceBossEventModule:GetPreviewRewards(activityExpeditionConfig)
    local rewards = {}
    local playerLength = activityExpeditionConfig:PreviewRewardItemIdsLength()
    for i = 1, playerLength do
        local itemID = activityExpeditionConfig:PreviewRewardItemIds(i)
        table.insert(rewards, itemID)
    end
    return rewards
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetEventStateAndRemainTime(activityExpeditionConfig)
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local startTime, endTime, remainingTime = ModuleRefer.WorldEventModule:GetAllianceEventTime(activityExpeditionConfig:Id(), true)
    if startTime <= serverTime and serverTime < endTime then
        return AllianceBossEventState.Preview, remainingTime
    else
        startTime, endTime, remainingTime = ModuleRefer.WorldEventModule:GetAllianceEventTime(activityExpeditionConfig:Id(), false)
        if startTime <= serverTime and serverTime < endTime then
            return AllianceBossEventState.Active, remainingTime
        end
    end
    return AllianceBossEventState.End, 0
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetStartEndTime(activityExpeditionConfig)
    if not activityExpeditionConfig then
        return 0, 0
    end
    
    local activityID = activityExpeditionConfig:DisplayTime()
    local startTime, endTime = ModuleRefer.WorldEventModule:GetActivityCountDown(activityID)
    return startTime, endTime
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetPersonalScore(activityExpeditionConfig)
    local scoreReward = self:GetPersonalScoreReward(activityExpeditionConfig)
    if scoreReward then
        return scoreReward.CurAllianceScore
    end
    return 0
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetPersonalScoreMax(activityExpeditionConfig)
    local scoreRewardConfig = self:GetScoreRewardConfig(activityExpeditionConfig)
    if scoreRewardConfig then
        local length = scoreRewardConfig:PlayerStageRewardScoreLimitLength()
        local stageScore = scoreRewardConfig:PlayerStageRewardScoreLimit(length)
        return stageScore
    end
    return 1
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetPlayerScoreRank(activityExpeditionConfig)
    local scoreRewardInfo = self:GetAllianceScoreReward(activityExpeditionConfig)
    if scoreRewardInfo and scoreRewardInfo.MemberScore then
        local players = {}
        for playerID, score in pairs(scoreRewardInfo.MemberScore) do
            table.insert(players, playerID)
        end
        table.sort(players, function(a, b)
            return scoreRewardInfo.MemberScore[a] > scoreRewardInfo.MemberScore[b]
        end)
        
        local myFacebookID = ModuleRefer.PlayerModule:GetAllianceFacebookId()
        for rank, facebookID in ipairs(players) do
            if facebookID == myFacebookID then
                return rank
            end
        end
    end
   
    return 0
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetAllianceScore(activityExpeditionConfig)
    local scoreReward = self:GetAllianceScoreReward(activityExpeditionConfig)
    if scoreReward then
        return scoreReward.SumScore
    end
    return 0
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetAllianceScoreMax(activityExpeditionConfig)
    local scoreRewardConfig = self:GetScoreRewardConfig(activityExpeditionConfig)
    if scoreRewardConfig then
        local length = scoreRewardConfig:AllianceStageRewardScoreLimitLength()
        local stageScore = scoreRewardConfig:AllianceStageRewardScoreLimit(length)
        return stageScore
    end
    return 1
end

function AllianceBossEventModule:HasCanClaimPlayerReward(tabID)
	local activityExpeditionConfig = self:GetActivityExpeditionConfigByTab(tabID)
	if not activityExpeditionConfig then
		return
	end
	local scoreRewardConfig = self:GetScoreRewardConfig(activityExpeditionConfig)
	if not scoreRewardConfig then
		return
	end

	local playerRewardLength = scoreRewardConfig:PlayerStageRewardLength()
	for i = 1, playerRewardLength do
		local state = self:GetStageRewardState(activityExpeditionConfig, wrpc.AllianceScoreRewardReceiveType.AllianceScoreRewardReceiveTypePersonal, i)
		if state == AllianceBossEventRewardState.CanClaim then
			return true
		end
	end
	return false
end

function AllianceBossEventModule:HasCanClaimAllianceReward(tabID)
    local activityExpeditionConfig = self:GetActivityExpeditionConfigByTab(tabID)
    if not activityExpeditionConfig then
        return
    end
    local scoreRewardConfig = self:GetScoreRewardConfig(activityExpeditionConfig)
    if not scoreRewardConfig then
        return
    end
    
    local allianceRewardLength = scoreRewardConfig:AllianceStageRewardLength()
    for i = 1, allianceRewardLength do
        local state = self:GetStageRewardState(activityExpeditionConfig, wrpc.AllianceScoreRewardReceiveType.AllianceScoreRewardReceiveTypeAlliance, i)
        if state == AllianceBossEventRewardState.CanClaim then
            return true
        end
    end
    return false
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetStageRewardState(activityExpeditionConfig, rewardType, index)
    if rewardType == wrpc.AllianceScoreRewardReceiveType.AllianceScoreRewardReceiveTypePersonal then
        return self:GetPersonalStageRewardState(activityExpeditionConfig, index)
    else
        return self:GetAllianceStageRewardState(activityExpeditionConfig, index)
    end
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
---@return number @AllianceBossEventRewardState
function AllianceBossEventModule:GetPersonalStageRewardState(activityExpeditionConfig, index)
    local scoreRewardConfig = self:GetScoreRewardConfig(activityExpeditionConfig)
    if scoreRewardConfig then
        local scoreReward = self:GetPersonalScoreReward(activityExpeditionConfig)
        if scoreReward and scoreReward.ReceivedPlayerRewards then
            for _, i in ipairs(scoreReward.ReceivedPlayerRewards) do
                if i == index - 1 then
                    return AllianceBossEventRewardState.Claimed
                end
            end
        end
        local score = scoreReward and scoreReward.CurAllianceScore or 0
        if 1 <= index and index <= scoreRewardConfig:PlayerStageRewardScoreLimitLength() then
            if score >= scoreRewardConfig:PlayerStageRewardScoreLimit(index) then
                return AllianceBossEventRewardState.CanClaim
            end
        end
    end
    return AllianceBossEventRewardState.NotClaimed
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
---@return number @AllianceBossEventRewardState
function AllianceBossEventModule:GetAllianceStageRewardState(activityExpeditionConfig, index)
    local scoreRewardConfig = self:GetScoreRewardConfig(activityExpeditionConfig)
    if scoreRewardConfig then
        local scoreReward = self:GetPersonalScoreReward(activityExpeditionConfig)
        if scoreReward and scoreReward.ReceivedAllianceRewards then
            for _, i in ipairs(scoreReward.ReceivedAllianceRewards) do
                if i == index - 1 then
                    return AllianceBossEventRewardState.Claimed
                end
            end
        end

        local playerScore = self:GetPersonalScore(activityExpeditionConfig)
        if playerScore < scoreRewardConfig:PlayerScoreLimitForAllianceReward() then
            return AllianceBossEventRewardState.NotClaimed
        end
        
        local allianceScoreReward = self:GetAllianceScoreReward(activityExpeditionConfig)
        local score = allianceScoreReward and allianceScoreReward.SumScore or 0
        if 1 <= index and index <= scoreRewardConfig:AllianceStageRewardScoreLimitLength() then
            if score >= scoreRewardConfig:AllianceStageRewardScoreLimit(index) then
                return AllianceBossEventRewardState.CanClaim
            end
        end
    end
    return AllianceBossEventRewardState.NotClaimed
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetScoreRewardConfig(activityExpeditionConfig)
    local scoreRewardConfig = ConfigRefer.AllianceActivityScoreReward:Find(activityExpeditionConfig:RewardScore())
    return scoreRewardConfig
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
---@return wds.AllianceScoreRewardInfo
function AllianceBossEventModule:GetAllianceScoreReward(activityExpeditionConfig)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return nil
    end

    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if allianceData and allianceData.AllianceWrapper.AllianceScoreReward and allianceData.AllianceWrapper.AllianceScoreReward.Data then
        local scoreReward = allianceData.AllianceWrapper.AllianceScoreReward.Data[activityExpeditionConfig:RewardScore()]
        return scoreReward
    end
    return nil
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
---@return wds.PlayerAllianceActivityScoreReward
function AllianceBossEventModule:GetPersonalScoreReward(activityExpeditionConfig)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        return nil
    end

    if player.PlayerAlliance.ActivityScoreReward then
        local scoreReward = player.PlayerAlliance.ActivityScoreReward[activityExpeditionConfig:RewardScore()]
        return scoreReward
    end
    return nil
end

---@param tabID number
---@return AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetActivityExpeditionConfigByTab(tabID)
    local tabConfig = ConfigRefer.ActivityCenterTabs:Find(tabID)
    if tabConfig and tabConfig:RefAllianceActivityExpeditionLength() > 0 then
        local activityExpeditionID = tabConfig:RefAllianceActivityExpedition(1)
        local activityExpeditionConfig = ConfigRefer.AllianceActivityExpedition:Find(activityExpeditionID)
        return activityExpeditionConfig
    end
    return nil
end

---@return wds.AllianceExpeditionNode
function AllianceBossEventModule:GetCurrentExpeditionNode()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return nil
    end

    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if allianceData and allianceData.AllianceWrapper.AllianceExpedition and allianceData.AllianceWrapper.AllianceExpedition.Expeditions then
        for _, expedition in pairs(allianceData.AllianceWrapper.AllianceExpedition.Expeditions) do
            if expedition.Type == wds.AllianceExpeditionType.AllianceExpeditionTypeBossEvent then
                return expedition
            end
        end
    end

    return nil
end

---@return AllianceActivityExpeditionConfigCell
function AllianceBossEventModule:GetCurrentActivityExpeditionConfig()
    local expeditionNode = self:GetCurrentExpeditionNode()
    if not expeditionNode then
        return nil
    end

    local activityExpeditionConfig = ConfigRefer.AllianceActivityExpedition:Find(expeditionNode.ConfigId)
    return activityExpeditionConfig
end

---@param activityExpeditionConfig AllianceActivityExpeditionConfigCell
---@return WorldExpeditionTemplateConfigCell
function AllianceBossEventModule:GetCurrentExpeditionConfig(activityExpeditionConfig)
    local expeditionConfigID = activityExpeditionConfig:Expeditions(1)
    local expeditionConfig = ConfigRefer.WorldExpeditionTemplate:Find(expeditionConfigID)
    return expeditionConfig
end

function AllianceBossEventModule:GotoAllianceBoss()
    local expeditionNode = self:GetCurrentExpeditionNode()
    if expeditionNode then
        local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(expeditionNode.BornPos)
        KingdomMapUtils.GotoCoordinate(tileX, tileZ, SceneType.SlgBigWorld)
    end
end

---@param limits number[]
---@return number
function AllianceBossEventModule:GetRewardProgress(score, limits)
    local current = 0
    for i = 1, #limits do
        local limit = limits[i]
        if score <= limit then
            local localRatio = (score - current) / (limit - current)
            local ratio = (i - 1 + localRatio) / #limits 
            return ratio
        end
        current = limit
    end
    return 1
end


return AllianceBossEventModule
