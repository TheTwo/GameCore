local BaseUIComponent = require('BaseUIComponent')
local BattlePassConst = require('BattlePassConst')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local Utils = require('Utils')
local TaskListSortHelper = require('TaskListSortHelper')
local DBEntityPath = require('DBEntityPath')
---@class BattlePassTask : BaseUIComponent
local BattlePassTask = class('BattlePassTask', BaseUIComponent)

local TASK_TAB_TYPE = BattlePassConst.TASK_TAB_TYPE

function BattlePassTask:OnCreate()
    self.tabCtrler = {
        [TASK_TAB_TYPE.DAILY] = self:LuaObject('p_toggle_1'),
        [TASK_TAB_TYPE.WEEKLY] = self:LuaObject('p_toggle_2'),
        [TASK_TAB_TYPE.SEASON] = self:LuaObject('p_toggle_3'),
    }
    self.tabTask = self:TableViewPro('p_task_table')
end

function BattlePassTask:OnShow()
    self.cfgId = ModuleRefer.BattlePassModule:GetCurOpeningBattlePassId()
    for k, v in pairs(self.tabCtrler) do
        v:FeedData({
            tabType = k,
            onClick = Delegate.GetOrCreate(self, self.OnTabClick),
        })
    end
    self:OnTabClick(TASK_TAB_TYPE.DAILY)
    g_Game.EventManager:AddListener(EventConst.BATTLEPASS_TASK_REWARD_CLAIM, Delegate.GetOrCreate(self, self.OnTaskClaimed))
end

function BattlePassTask:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.BATTLEPASS_TASK_REWARD_CLAIM, Delegate.GetOrCreate(self, self.OnTaskClaimed))
end

function BattlePassTask:OnTabClick(tabType)
    self.tabType = tabType
    for k, v in pairs(self.tabCtrler) do
        v:SetToggleActive(k == tabType)
    end
    self:UpdateTaskList()
end

function BattlePassTask:UpdateTaskList()
    local taskIds = {}
    Utils.CopyArray(ModuleRefer.BattlePassModule:GetTasksByTaskType(self.cfgId, self.tabType), taskIds)
    TaskListSortHelper.Sort(taskIds)
    self.tabTask:Clear()
    for _, taskId in ipairs(taskIds) do
        self.tabTask:AppendData({
            taskId = taskId,
        })
    end
    self.isDirty = false
end

function BattlePassTask:OnTaskClaimed()
    self:UpdateTaskList()
end

function BattlePassTask:OnTaskChange()
end

function BattlePassTask:SetTaskStateDirty()
    self.isDirty = true
end

return BattlePassTask