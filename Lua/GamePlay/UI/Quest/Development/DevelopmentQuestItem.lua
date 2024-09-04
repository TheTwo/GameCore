local BaseTableViewProCell = require("BaseTableViewProCell")
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local TaskType = require('TaskType')
local TaskOperationParameter = require("PlayerTaskOperationParameter")
local EventConst = require('EventConst')
local I18N = require("I18N")
local UIHelper = require('UIHelper')
local TimerUtility = require('TimerUtility')
local DevelopmentQuestItem = class("DevelopmentQuestItem", BaseTableViewProCell)

function DevelopmentQuestItem:OnCreate()
    self.imgIconDay = self:Image('p_icon_development')
    self.textDay = self:Text('p_text_development')
    self.tableviewproTableRewards = self:TableViewPro('p_table_rewards_development')
    self.btnGotoDay = self:Button('p_btn_goto_development', Delegate.GetOrCreate(self, self.OnBtnGotoDayClicked))
    self.textGotoDay = self:Text('p_text_goto_development', I18N.Get("daily_info_goto"))
    self.btnGet = self:Button('p_btn_get_development', Delegate.GetOrCreate(self, self.OnBtnGetClicked))
    self.textGet = self:Text('p_text', I18N.Get("daily_info_get"))
	self.goGet = self:GameObject('vx_getreward')
    self.goClaimed = self:GameObject('p_claimed_development')
	self.goGet:SetActive(false)
	self.animation = self:BindComponent("p_cell_group", typeof(CS.UnityEngine.Animation))
end

function DevelopmentQuestItem:PlayShowAnim()
	self.animation:Play("anim_vx_ui_misson_item_development_in")
end

function DevelopmentQuestItem:PlayInitAnim()
	self.animation:Play("anim_vx_ui_misson_item_development_null")
end

function DevelopmentQuestItem:OnBtnGotoDayClicked()
    local taskProp = self.taskCfg:Property()
	g_Game.UIManager:Close(self:GetCSUIMediator().RuntimeId)
    require('GuideUtils').GotoByGuide(taskProp:Goto(), true)
end

function DevelopmentQuestItem:OnBtnGetClicked(args)
	self.animation:Play("anim_vx_ui_misson_item_development_reward")
	TimerUtility.DelayExecute(function()
		local operationParameter = TaskOperationParameter.new()
		operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
		operationParameter.args.CID = self.taskId
		operationParameter:Send(self.btnGet.transform)
		g_Game.EventManager:TriggerEvent(EventConst.RECORD_DEVELOPMENT_POS) end, 0.5)
end

function DevelopmentQuestItem:OnFeedData(data)
	if not data then
		return
	end
	self.animation:Play("anim_vx_ui_misson_item_development_normal")
	self.data = data
	self.taskId = data.taskId
	self:RefreshDetail()
end

function DevelopmentQuestItem:RefreshDetail()
	local isCanReward = self.data.isCanReward
	self.goClaimed:SetActive(false)
	self.btnGotoDay.gameObject:SetActive(not isCanReward)
	self.btnGet.gameObject:SetActive(isCanReward)
	self.taskCfg = ConfigRefer.Task:Find(self.taskId)
	local taskType = self.taskCfg:Property():TaskType()
	if taskType == TaskType.Explore then
		g_Game.SpriteManager:LoadSprite(ConfigRefer.DailyTaskConst:ExploreTaskIcon(), self.imgIconDay)
	elseif taskType == TaskType.Fight then
		g_Game.SpriteManager:LoadSprite(ConfigRefer.DailyTaskConst:FightTaskIcon(), self.imgIconDay)
	elseif taskType == TaskType.Production then
		g_Game.SpriteManager:LoadSprite(ConfigRefer.DailyTaskConst:ProductionTaskIcon(), self.imgIconDay)
	end
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
		self.textDay.text = colorText .. taskName
	else
		self.textDay.text = taskName
	end
	self.tableviewproTableRewards:Clear()
	local rewards = ModuleRefer.QuestModule.Chapter:GetQuestRewards(self.taskCfg) or {}
	for _, reward in ipairs(rewards) do
		self.tableviewproTableRewards:AppendData(reward)
	end
end

return DevelopmentQuestItem