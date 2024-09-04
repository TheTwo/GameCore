local BaseModule = require("BaseModule")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local DBEntityPath = require('DBEntityPath')

local QuestModule_Daily = class("QuestModule_Daily", BaseModule)

function QuestModule_Daily:OnRegister(parent)
    self.parentModule = parent
    self:UpdatePlayerInfo()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.DailyTaskInfo.MsgPath, Delegate.GetOrCreate(self,self.OnDataChanged))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self,self.UpdatePlayerInfo))
end

function QuestModule_Daily:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.DailyTaskInfo.MsgPath, Delegate.GetOrCreate(self,self.OnDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self,self.UpdatePlayerInfo))
end

function QuestModule_Daily:UpdatePlayerInfo()
    self.player = ModuleRefer.PlayerModule:GetPlayer()
    self.dailyTaskInfo = self.player.PlayerWrapper.Task.DailyTaskInfo
end

function QuestModule_Daily:OnDataChanged()
    g_Game.EventManager:TriggerEvent(EventConst.REFRESH_DAILY_QUEST)
end

function QuestModule_Daily:GetDailyTaskCfg()
    local cfgId = self.dailyTaskInfo.CfgId
    if cfgId == 0 then
        return ConfigRefer.DailyTask:Find(10001)
    end
    return ConfigRefer.DailyTask:Find(cfgId)
end

function QuestModule_Daily:GetCurScore()
    return self.dailyTaskInfo.Progress or 0
end

function QuestModule_Daily:CheckIsGotReward(score)
    for _, gotProgress in ipairs(self.dailyTaskInfo.RewardedProgress or {}) do
        if score == gotProgress then
            return true
        end
    end
    return false
end

function QuestModule_Daily:GetQuestDailyRewardCount()
    local rewardCount = 0
    for _, id in pairs(self.dailyTaskInfo.ProcessingRecommendTasks) do
        if ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(id) ==  wds.TaskState.TaskStateCanFinish then
            rewardCount = rewardCount + 1
        end
    end
    for _, id in pairs(self.dailyTaskInfo.ProcessingNormalTasks) do
        if ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(id) ==  wds.TaskState.TaskStateCanFinish then
            rewardCount = rewardCount + 1
        end
    end
    return rewardCount
end

function QuestModule_Daily:CheckHasCanGetReward()
    local dailyTaskCfg = self:GetDailyTaskCfg()
	if not dailyTaskCfg then
		return false
	end
    local curScore = self:GetCurScore()
    local progressId = dailyTaskCfg:Progress()
	local progressCfg = ConfigRefer.DailyTaskProgress:Find(progressId)
	for index = 1, progressCfg:ProgressLength() do
        local score = progressCfg:Progress(index)
        local isEnough = curScore >= score
        local isGot = self:CheckIsGotReward(score)
        if isEnough and not isGot then
            return true
        end
	end
    return false
end

function QuestModule_Daily:GetRefreshTimes()
    return self.dailyTaskInfo.RefreshTimes or 0
end

return QuestModule_Daily
