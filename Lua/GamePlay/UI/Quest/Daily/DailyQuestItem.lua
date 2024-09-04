local BaseTableViewProCell = require("BaseTableViewProCell")
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local TaskType = require('TaskType')
local TaskOperationParameter = require("PlayerTaskOperationParameter")
local UIMediatorNames = require('UIMediatorNames')
local EventConst = require('EventConst')
local DailyTaskRefreshNormalTaskParameter = require('DailyTaskRefreshNormalTaskParameter')
local I18N = require("I18N")
local UIHelper = require('UIHelper')
local TimerUtility = require('TimerUtility')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local DailyQuestItem = class("DailyQuestItem", BaseTableViewProCell)

function DailyQuestItem:OnCreate()
    self.imgIconDay = self:Image('p_icon_day')
    self.textDay = self:Text('p_text_day')
    self.tableviewproTableRewards = self:TableViewPro('p_table_rewards')
    self.goRefresh = self:GameObject('p_refresh')
    self.btnRefresh = self:Button('p_btn_refresh', Delegate.GetOrCreate(self, self.OnBtnRefreshClicked))
    self.imgIconItem = self:Image('p_icon_item')
    self.textFree = self:Text('p_text_free')
    self.btnGotoDay = self:Button('p_btn_goto_day', Delegate.GetOrCreate(self, self.OnBtnGotoDayClicked))
    self.textGotoDay = self:Text('p_text_goto_day', I18N.Get("daily_info_goto"))
    self.btnGet = self:Button('p_btn_get', Delegate.GetOrCreate(self, self.OnBtnGetClicked))
    self.textGet = self:Text('p_text', I18N.Get("daily_info_get"))
	self.goGet = self:GameObject('vx_getreward')
	self.goClaimed = self:GameObject('vx_claimed')
    self.goClaimed = self:GameObject('p_claimed')
	self.animation = self:BindComponent("p_cell_group", typeof(CS.UnityEngine.Animation))

    self.goDouble = self:GameObject('p_double')
    self.textDouble = self:Text('p_text_double', I18N.Get("daily_info_recommand"))
	self.taskId = nil
	self.goGet:SetActive(false)
	self.goClaimed:SetActive(false)
end

function DailyQuestItem:OnShow()
	if not self.addedListener then
		self.addedListener = true
		g_Game.EventManager:AddListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.RefreshSelf))
	end
end

function DailyQuestItem:OnHide()
	self.taskId = nil
	if self.addedListener then
		self.addedListener = false
		g_Game.EventManager:RemoveListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.RefreshSelf))
	end
end

function DailyQuestItem:OnClose()
	self.taskId = nil
	if self.addedListener then
		self.addedListener = false
		g_Game.EventManager:RemoveListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.RefreshSelf))
	end
end

function DailyQuestItem:RefreshSelf(params)
	if not self.taskId then
		return
	end
	if params and table.ContainsValue(params, self.taskId) then
		self:RefreshDetail()
	end
end

function DailyQuestItem:OnBtnRefreshClicked(args)
	local curRefreshTimes = ModuleRefer.QuestModule.Daily:GetRefreshTimes()
	local maxRefreshTimes = ConfigRefer.DailyTaskConst:MaxRefreshTimes()
	local isCanRefresh = maxRefreshTimes > curRefreshTimes
	if isCanRefresh then
		local freeRefreshTimes = ConfigRefer.DailyTaskConst:FreeRefreshTimes()
		local isFreeRefresh = freeRefreshTimes > curRefreshTimes
		if isFreeRefresh then
			local operationParameter = DailyTaskRefreshNormalTaskParameter.new()
			operationParameter.args.Slot = self.index - 1
			operationParameter:Send(self.btnRefresh.transform)
			--self.animation:Play("anim_vx_ui_misson_item_day_refresh")
		else
			local leftTimes = maxRefreshTimes - curRefreshTimes
			local costNum = ConfigRefer.DailyTaskConst:RefreshCostItemCount()
			local itemCfg = ConfigRefer.Item:Find(ConfigRefer.DailyTaskConst:RefreshCostItem())
			local dialogParam = {}
			dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
			dialogParam.title = I18N.Get("daily_title_tips")
			dialogParam.content = I18N.GetWithParams("daily_info_confirm", costNum , I18N.Get(itemCfg:NameKey()))
			dialogParam.contentDescribe = I18N.GetWithParams("daily_info_leftchance", leftTimes)
			dialogParam.onConfirm = function(context)
				local operationParameter = DailyTaskRefreshNormalTaskParameter.new()
				operationParameter.args.Slot = self.index - 1
				operationParameter:Send(self.btnRefresh.transform)
				self.animation:Play("anim_vx_ui_misson_item_day_refresh")
				return true
			end
			g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
		end
		g_Game.EventManager:TriggerEvent(EventConst.RECORD_DAILY_POS)
	end
end

function DailyQuestItem:OnBtnGotoDayClicked()
    local taskProp = self.taskCfg:Property()
	g_Game.UIManager:Close(self:GetCSUIMediator().RuntimeId)
    require('GuideUtils').GotoByGuide(taskProp:Goto(), true)
end

function DailyQuestItem:OnBtnGetClicked(args)
	self.animation:Play("anim_vx_ui_misson_item_day_reward")
	TimerUtility.DelayExecute(function()
		local operationParameter = TaskOperationParameter.new()
		operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
		operationParameter.args.CID = self.taskId
		operationParameter:Send(self.btnGet.transform)
		g_Game.EventManager:TriggerEvent(EventConst.RECORD_DAILY_POS) end, 0.2)
end

function DailyQuestItem:PlayShowAnim()
	self.animation:Play("anim_vx_ui_misson_item_day_in")
end

function DailyQuestItem:PlayInitAnim()
	self.animation:Play("anim_vx_ui_misson_item_day_null")
end

function DailyQuestItem:OnFeedData(data)
	if not data then
		return
	end
	self.animation:Play("anim_vx_ui_misson_item_day_normal")
	self.data = data
	self.index = data.index
	self.taskId = data.taskId
	self:RefreshDetail()
end

function DailyQuestItem:RefreshDetail()
	local isDouble = self.data.isRecommend
	self.goDouble:SetActive(isDouble)
	local isFinish = self.data.isFinish
	local isCanReward = self.data.isCanReward
	self.goClaimed:SetActive(isFinish)
	self.btnGotoDay.gameObject:SetActive(not (isFinish or isCanReward))
	self.btnGet.gameObject:SetActive(isCanReward and not isFinish)
	self.taskCfg = ConfigRefer.Task:Find(self.taskId)
	if not self.taskCfg then
		return
	end
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


    local finish = self.taskCfg:FinishBranch(1)
	local score = finish:BranchReward(1):Param()
	if score then
		local item = function() return ConfigRefer.DailyTaskConst:ProgressItem() end
		local num = function() return tonumber(score) end
		self.tableviewproTableRewards:AppendData({Items = item, Nums = num})
	end
	local rewards = ModuleRefer.QuestModule.Chapter:GetQuestRewards(self.taskCfg, nil, 2) or {}
	for _, reward in ipairs(rewards) do
		self.tableviewproTableRewards:AppendData(reward)
	end

	local curRefreshTimes = ModuleRefer.QuestModule.Daily:GetRefreshTimes()
	local maxRefreshTimes = ConfigRefer.DailyTaskConst:MaxRefreshTimes()
	local isCanRefresh = maxRefreshTimes > curRefreshTimes and not isFinish and not isDouble
	if isCanRefresh then
		local freeRefreshTimes = ConfigRefer.DailyTaskConst:FreeRefreshTimes()
		local isFreeRefresh = freeRefreshTimes > curRefreshTimes
		self.imgIconItem.gameObject:SetActive(not isFreeRefresh)
		self.textFree.text = isFreeRefresh and I18N.Get("daily_btn_freefresh") or ConfigRefer.DailyTaskConst:RefreshCostItemCount()
		if not isFreeRefresh then
			local itemCfg = ConfigRefer.Item:Find(ConfigRefer.DailyTaskConst:RefreshCostItem())
			g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgIconItem)
		end
		CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.goRefresh.transform)
	end
	self.goRefresh:SetActive(isCanRefresh)
end

return DailyQuestItem