local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local Delegate = require('Delegate')
local AllianceLongTermTaskType = require('AllianceLongTermTaskType')
local ConfigRefer = require('ConfigRefer')
local AllianceTaskOperationParameter = require('AllianceTaskOperationParameter')
local AllianceTaskItemDataProvider = require("AllianceTaskItemDataProvider")
local EventConst = require('EventConst')

---@class AllianceAchievementPopUpMediator : BaseUIMediator
local AllianceAchievementPopUpMediator = class('AllianceAchievementPopUpMediator', BaseUIMediator)
function AllianceAchievementPopUpMediator:OnCreate()
    ---@type AllianceAchievementTypeComp
    self.p_item_btn_typpe = self:LuaObject('p_item_btn_typpe')
    self.child_btn_close = self:Button('child_btn_close', Delegate.GetOrCreate(self, self.OnBtnClickClose))
    self.p_table_task = self:TableViewPro('p_table_task')
end

function AllianceAchievementPopUpMediator:OnOpened(param)
    -- g_Game.EventManager:AddListener(EventConst.ALLIANCE_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshTasks))

    self.param = param
    self.p_item_btn_typpe:FeedData(param)
    self.p_item_btn_typpe:SetCanClick(false)
    self:RefreshTasks()
end

function AllianceAchievementPopUpMediator:RefreshTasks(index)
    if index and index ~= self.param.index then
        return
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    for k, v in pairs(self.param.tasks) do
        if player.PlayerWrapper3.TaskExtra.RewardAllianceTasks[v.TID] then
            v.State = wds.TaskState.TaskStateFinished
        end
    end

    table.sort(self.param.tasks, AllianceAchievementPopUpMediator.SortTask)
    self.p_table_task:Clear()
    for k, v in pairs(self.param.tasks) do
        local data = {}
        data.provider = AllianceTaskItemDataProvider.new(v.TID)
        data.index = self.param.index
        data.RewardAlliancePoint = v.RewardAlliancePoint
        ---@type AllianceAchievementTaskComp
        self.p_table_task:AppendData(data)
    end
end

function AllianceAchievementPopUpMediator.SortTask(a, b)
    if a.State ~= b.State then
        if a.State == wds.TaskState.TaskStateCanFinish then
            return true
        elseif b.State == wds.TaskState.TaskStateCanFinish then
            return false
        else
            return a.State < b.State
        end
    else
        return a.TID < b.TID
    end
end

function AllianceAchievementPopUpMediator:OnClose(param)
    -- g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshTasks))
end

function AllianceAchievementPopUpMediator:OnBtnClickClose()
    self:CloseSelf()
end
return AllianceAchievementPopUpMediator
