local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local BattlePassConst = require('BattlePassConst')
local TaskItemDataProvider = require('TaskItemDataProvider')
local DBEntityPath = require('DBEntityPath')
---@class BattlePassTaskCell : BaseTableViewProCell
local BattlePassTaskCell = class('BattlePassTaskCell', BaseTableViewProCell)

---@class BattlePassTaskCellParam
---@field taskId number
---@field onClaim fun()

function BattlePassTaskCell:OnCreate()
    self.tableRewards = self:TableViewPro('p_table_rewards')
    self.textTask = self:Text('p_text_task', "")

    self.btnGoto = self:Button('p_btn_go', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text_go', 'task_btn_goto')
    self.btnClaim = self:Button('p_btn_claim', Delegate.GetOrCreate(self, self.OnBtnClaimClicked))
    self.textClaim = self:Text('p_text', 'task_btn_claim')
    self.goFinish = self:GameObject('p_finish')

    self.goTask = self:GameObject('p_cell_group')
    self.goLock = self:GameObject('p_cell_group_lock')
    self.textLock = self:Text('p_text_unlock', "")

    self.btnCtrler = {}
    self.btnCtrler[wds.TaskState.TaskStateReceived] = self.btnGoto.gameObject
    self.btnCtrler[wds.TaskState.TaskStateCanFinish] = self.btnClaim.gameObject
    self.btnCtrler[wds.TaskState.TaskStateFinished] = self.goFinish
end

---@param param BattlePassTaskCellParam
function BattlePassTaskCell:OnFeedData(param)
    if not param then
        return
    end
    self.param = param
    self.cfgId = ModuleRefer.BattlePassModule:GetCurOpeningBattlePassId()
    self:Init()
end

function BattlePassTaskCell:Init()
    local param = self.param
    if not self.taskDataProvider then
        self.taskDataProvider = TaskItemDataProvider.new(param.taskId, self.btnClaim.transform)
        if param.onClaim then
            self.taskDataProvider:SetOnClaim(param.onClaim)
        end
        self.taskDataProvider:SetClaimCallback(function ()
            g_Game.EventManager:TriggerEvent(EventConst.BATTLEPASS_TASK_REWARD_CLAIM)
        end)
    end
    local taskState = self.taskDataProvider:GetTaskState()
    self:SetBtnVisible(taskState)
    if taskState > wds.TaskState.TaskStateCanReceive then
        self.goTask:SetActive(true)
        self.goLock:SetActive(false)
        self.textTask.text = self.taskDataProvider:GetTaskStr()
        local score = string.split(self.taskDataProvider:GetTaskCfg():FinishBranch(1):BranchReward(1):Param(), ';')[2]
        self.tableRewards:Clear()
        if score then
            local scoreItem = ModuleRefer.BattlePassModule:GetProgressItemId(self.cfgId)
            local scoreItemCfg = ConfigRefer.Item:Find(scoreItem)
            local count = tonumber(score)
            local data = {}
            data.configCell = scoreItemCfg
            data.count = count
            data.showTips = true
            self.tableRewards:AppendData(data)
        end
        for _, reward in ipairs(self.taskDataProvider:GetTaskRewards(nil, 2)) do
            self.tableRewards:AppendData(reward)
        end
    else
        self.goTask:SetActive(false)
        self.goLock:SetActive(true)
        self.textLock.text = self.taskDataProvider:GetTaskUnlockStr() or ""
    end
end

function BattlePassTaskCell:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.OnTaskChange))
end

function BattlePassTaskCell:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.OnTaskChange))
end

function BattlePassTaskCell:OnBtnClaimClicked()
    self.taskDataProvider:OnClaim()
end

function BattlePassTaskCell:OnBtnGotoClicked()
    self.taskDataProvider:OnGoto()
end

function BattlePassTaskCell:OnTaskChange()
    self:Init()
end

function BattlePassTaskCell:SetBtnVisible(taskState)
    for state, btn in pairs(self.btnCtrler) do
        btn:SetActive(taskState == state)
    end
end

return BattlePassTaskCell