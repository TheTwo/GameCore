local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require("ModuleRefer")

---@class LandformTaskParameter
---@field landformConfigID number
---@field activityInfo wds.LandActivityInfo

---@class LandformTaskPanel : BaseUIComponent
---@field landformConfig LandConfigCell
---@field activityInfo wds.LandActivityInfo
local LandformTaskPanel = class("LandformTaskPanel", BaseUIComponent)

function LandformTaskPanel:OnCreate(param)
    self.p_progress_task = self:Slider("p_progress_task")
    self.p_text_progress = self:Text("p_text_progress")
    self.p_table_reward = self:TableViewPro("p_table_reward")
    self.p_table_reward_rect = self:RectTransform("p_table_reward")
    self.p_table_task = self:TableViewPro("p_table_task")
end

---@param param LandformTaskParameter
function LandformTaskPanel:OnFeedData(param)
    self.landformConfig = ConfigRefer.Land:Find(param.landformConfigID)
    self.activityInfo = param.activityInfo

    self:RefreshRewards()
    self:RefreshTasks()
end

function LandformTaskPanel:RefreshRewards()
    local currentScore = ModuleRefer.LandformTaskModule:GetCurrentScore(self.activityInfo)
    self.p_text_progress.text = currentScore
    
    local scoreLimits = {}
    for i = 1, self.landformConfig:ActivityRewardScoresLength() do
        local limit = self.landformConfig:ActivityRewardScores(i)
        table.insert(scoreLimits, limit)
    end
    local progress = ModuleRefer.AllianceBossEventModule:GetRewardProgress(currentScore, scoreLimits)
    self.p_progress_task.value = progress
    
    local states = ModuleRefer.LandformTaskModule:GetStageRewardStates(self.activityInfo, self.landformConfig)
    local rewardRectSize = self.p_table_reward_rect.rect.size
    local rewardLength = self.landformConfig:ActivityRewardScoresLength()
    self.p_table_reward:Clear()
    for i = 1, rewardLength do
        local score = self.landformConfig:ActivityRewardScores(i)
        local itemGroupID = self.landformConfig:ActivityRewardLoots(i)
        local state = states[i]
        ---@type LandformTaskRewardCellParameter
        local param = 
        {
            index = i,
            landformConfigID = self.landformConfig:Id(),
            score = score,
            state = state,
            posX = rewardRectSize.x * i / rewardLength,
            itemGroupID = itemGroupID,
        }
        self.p_table_reward:AppendData(param)
    end
    self.p_table_reward:RefreshAllShownItem()
end

function LandformTaskPanel:RefreshTasks()
    local length = self.landformConfig:ActivityTasksLength()
    self.p_table_task:Clear()
    for i = 1, length do
        local taskID = self.landformConfig:ActivityTasks(i)
        ---@type LandformTaskCellParameter
        local param =
        {
            activityInfo = self.activityInfo,
            landformConfigID = self.landformConfig:Id(),
            taskID = taskID,
        }
        self.p_table_task:AppendData(param)
    end
    self.p_table_task:RefreshAllShownItem()
end

return LandformTaskPanel