local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local I18N = require('I18N')
local TaskOperationParameter = require('PlayerTaskOperationParameter')
local FactionTaskCell = class('FactionTaskCell',BaseTableViewProCell)

function FactionTaskCell:OnCreate(param)
    self.textTaskDetail = self:Text('p_text_task_detail')
    self.tableviewproItemTableRewards = self:TableViewPro('p_item_table_rewards')
    self.goClaimed = self:GameObject('p_claimed')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text_goto', I18N.Get("sov_general_des0"))
    self.btnGetreward = self:Button('p_btn_getreward', Delegate.GetOrCreate(self, self.OnBtnGetrewardClicked))
    self.textText = self:Text('p_text', I18N.Get("sov_general_des1"))
end

function FactionTaskCell:OnFeedData(taskId)
    self.taskId = taskId
    self.taskCfg = ConfigRefer.Task:Find(self.taskId)
    local taskNameKey,taskNameParam = ModuleRefer.QuestModule:GetTaskName(self.taskCfg)
	local taskName = I18N.GetWithParamList(taskNameKey,taskNameParam)
	local progressCount,progressMax = ModuleRefer.QuestModule:GetTaskProgressByTaskID(self.taskCfg:Id())
	if progressCount and progressMax and progressMax > 0 then
		local colorText = string.format('<b>(%d/%d)</b>',progressCount, progressMax)
		if progressCount >= progressMax then
			colorText = UIHelper.GetColoredText(colorText, "#F14A7C")
		else
			colorText = UIHelper.GetColoredText(colorText, "#744040")
		end
		self.textTaskDetail.text = colorText .. taskName
	else
		self.textTaskDetail.text = taskName
	end
    self.tableviewproItemTableRewards:Clear()
	local rewards = ModuleRefer.QuestModule.Chapter:GetQuestRewards(self.taskCfg) or {}
	for _, reward in ipairs(rewards) do
		self.tableviewproItemTableRewards:AppendData(reward)
	end
    local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.taskId)
    local isFinish = taskState ==  wds.TaskState.TaskStateFinished
	local isCanReward = taskState == wds.TaskState.TaskStateCanFinish
	self.goClaimed:SetActive(isFinish)
	self.btnGoto.gameObject:SetActive(not (isFinish or isCanReward))
	self.btnGetreward.gameObject:SetActive(isCanReward and not isFinish)
end

function FactionTaskCell:OnBtnGotoClicked(args)
    local taskProp = self.taskCfg:Property()
	g_Game.UIManager:Close(self:GetCSUIMediator().RuntimeId)
    require('GuideUtils').GotoByGuide(taskProp:Goto(), true)
end

function FactionTaskCell:OnBtnGetrewardClicked(args)
    local operationParameter = TaskOperationParameter.new()
    operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
    operationParameter.args.CID = self.taskId
    operationParameter:Send(self.btnGetreward.transform)
end

return FactionTaskCell
