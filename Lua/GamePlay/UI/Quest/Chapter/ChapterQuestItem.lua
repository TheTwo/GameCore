local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local Utils = require('Utils')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local TimerUtility = require('TimerUtility')
local QueuedTask = require('QueuedTask')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')

---@class ChapterQuestItem.ChapterQuestItemData
---@field cachedQuestItem CachedChapterTaskItem
---@field _rewardList ItemGroupInfo[]
---@field hideFlag number @1:Show | 2:Locked | 3:Hide
---@field nextQuestId number

---@class ChapterQuestItem : BaseTableViewProCell
---@field _itemData ChapterQuestItem.ChapterQuestItemData
---@field _gotoAction fun(number)
---@field _cliamAction fun(number,RectTransform,TaskConfigCell)
---@field _chapterQuestCell TaskConfigCell
---@field _chapterQuestData wds.TaskUnit
---@field _rewardTableView CS.TableViewPro
---@field _infoGroup CS.UnityEngine.CanvasGroup
---@field queuedTask QueuedTask
local ChapterQuestItem = class("ChapterQuestItem", BaseTableViewProCell)

local I18N = require("I18N");

function ChapterQuestItem:ctor()
	self.isHidden = false
	self.module = ModuleRefer.QuestModule
	self.queuedTask = nil
end

function ChapterQuestItem:OnCreate()
	self._detailsRoot = self:RectTransform('p_details')
	self._infoGroup = self:BindComponent('p_info_group',typeof(CS.UnityEngine.CanvasGroup))
	self._rewardTableView = self:TableViewPro("p_item_table_slot_rewards")
	self._descText = self:Text("p_text_item_discription")
	self._finishText = self:Text('p_text_finish','[*]QuestComplete')
	self._claimedObj = self:GameObject("p_claimed")

	self._claimButton = self:Button("p_btn_getreward", Delegate.GetOrCreate(self, self.OnClaimClick))
	self.goClaimed = self:GameObject('vx_claimed')
	self._claimLabel = self:Text("p_text", "task_btn_claim");

	self._gotoButton = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoClick))
	self._gotoLabel = self:Text("p_text_goto", "task_btn_goto");

	self._lockRoot = self:RectTransform("p_lock")
	self._lockLabel = self:Text("p_text_unlock_tips", "task_locked");


    self._goVxUnlock = self:GameObject('vx_shuaxin')
	self._animtriggerVxTriggerUnlock = self:AnimTrigger('vx_trigger_shuaxin')
	self._goVxGetReward = self:GameObject('vx_getreward')
	self._goRecommend = self:GameObject("p_icon_recommend")
	self.animation = self:BindComponent("p_cell_group", typeof(CS.UnityEngine.Animation))
end

function ChapterQuestItem:OnHide()
	if self.claimTimer then
		self.claimTimer:Stop()
		self.claimTimer = nil
	end

	if self.queuedTask ~= nil then
		self.queuedTask:Release()
		self.queuedTask = nil
	end
end

function ChapterQuestItem:PlayShowAnim()
    self.animation:Play("anim_vx_ui_misson_item_slot_in")
end

function ChapterQuestItem:PlayInitAnim()
    self.animation:Play("anim_vx_ui_misson_item_slot_null")
end

---FeedData
---@param data ChapterQuestItem.ChapterQuestItemData
function ChapterQuestItem:OnFeedData(data)
	if self:Init(data) then
		self:UpdateUI()
	else
		g_Logger.Error('ChapterQuestItem init faild!')
	end
end

---@param data ChapterQuestItem.ChapterQuestItemData
function ChapterQuestItem:Init(data)
	self._itemData = data
	if self._itemData == nil then
		return false
	end
	self._parentQuestInfoComp = self._itemData.ParentQuestInfoComp
	if self._parentQuestInfoComp == nil or self._parentQuestInfoComp.GotoAction == nil or self._parentQuestInfoComp.QuestRewardAction == nil then
		return false
	end

	self._chapterQuestCell = self._itemData.cachedQuestItem.config
	if self._chapterQuestCell == nil then
		return false
	end
	self._chapterQuestData = self._itemData.cachedQuestItem.unit
	if self._chapterQuestData == nil then
		return false
	end
	return true
end

function ChapterQuestItem:Release()
	self._rewardTableView:Clear(false, true, true)
end

---private SetItemData
---@param taskState number
---@param desc string
---@param num number
---@param all number
---@param gotoId number
function ChapterQuestItem:SetItemData(taskState,desc,num,all,gotoId,hasPre,isRecommend)

	local claimed = taskState == wds.TaskState.TaskStateFinished
	local finished = taskState >= wds.TaskState.TaskStateCanFinish

	--	set info
	if num and all and all > 0 then
		local colorText = string.format('<b>(%d/%d)</b>',num, all)
		if num >= all then
			colorText = UIHelper.GetColoredText(colorText, "#F14A7C")
		else
			colorText = UIHelper.GetColoredText(colorText, "#744040")
		end
		self._descText.text = colorText .. desc
		self._finishText:SetVisible(false)
	else
		self._descText.text = desc
		self._finishText:SetVisible(false)
	end

	self._rewardTableView:Clear(false, false, true)
	if self._itemData._rewardList ~= nil and #self._itemData._rewardList > 0 then
		for _, chapterReward in ipairs(self._itemData._rewardList) do
			self._rewardTableView:AppendData(chapterReward, 0, -1)
		end
	end
	self.goClaimed:SetActive(false)
	--set state
	if claimed then
		self._claimButton.gameObject:SetActive(false)
		self._goVxGetReward:SetActive(false)
		self._gotoButton.gameObject:SetActive(false)
		self._goRecommend:SetActive(false)
		self._claimedObj:SetActive(true)
		self._infoGroup.alpha = 0.5
	elseif finished then
		self._claimButton.gameObject:SetActive(true)
		self._goVxGetReward:SetActive(false)
		UIHelper.ButtonEnable(self._claimButton, true )
		self._gotoButton.gameObject:SetActive(false)
		self._goRecommend:SetActive(false)
		self._claimedObj:SetActive(false)
		self._infoGroup.alpha = 1
	else
		self._claimedObj:SetActive(false)
		if gotoId > 0 then
			self._gotoButton.gameObject:SetActive(true)
			self._goRecommend:SetActive(isRecommend)
			self._claimButton.gameObject:SetActive(false)
		else
			self._gotoButton.gameObject:SetActive(false)
			self._goRecommend:SetActive(false)
			self._claimButton.gameObject:SetActive(false)
			UIHelper.ButtonEnable(self._claimButton, false )
		end
		self._goVxGetReward:SetActive(false)
		-- self._goBase:SetActive(true)
		self._infoGroup.alpha = 1
	end
end

function ChapterQuestItem:UpdateUI()
	--set state
	local taskState = self._chapterQuestData.State;
	self.isLocked = self._itemData.hideFlag == 2

	if self._itemData.hideFlag == 1 then
		--hide and play unlock anim
		self._detailsRoot:SetVisible(false)
		self._lockRoot:SetVisible(true)
		local progressCount,progressMax = self.module:GetTaskProgress(self._chapterQuestData)
		local taskNameKey,taskNameParam = self.module:GetTaskName(self._chapterQuestCell)
		local taskName = I18N.GetWithParamList(taskNameKey,taskNameParam)

		self:SetItemData(taskState, taskName
			,progressCount,progressMax
			,self._chapterQuestCell:Property():Goto(),false,self._chapterQuestCell:Property():Recommend()
		)

		--play unlock anim
		self._goVxUnlock:SetVisible(true)

		if self.queuedTask ~= nil then
			self.queuedTask:Release()
			self.queuedTask = nil
		end

		self.queuedTask = QueuedTask.new()
		self.queuedTask:DoAction(function()
			self._goVxUnlock:SetVisible(true)
		end):WaitForSeconds(0.1):DoAction(function()
			self._detailsRoot:SetVisible(true)
			self._lockRoot:SetVisible(false)
		end):WaitForSeconds(0.5):DoAction(function()
			self._goVxUnlock:SetVisible(false)
			self.module.Chapter:UpdateQuestCasheItem(self._chapterQuestData.TID)
		end):Start()

	else
		--normal state
		self._detailsRoot:SetVisible(not self.isLocked)
		self._lockRoot:SetVisible(self.isLocked)
		if not self.isLocked then
			local progressCount,progressMax = self.module:GetTaskProgress(self._chapterQuestData)
			local taskNameKey,taskNameParam = self.module:GetTaskName(self._chapterQuestCell)
			local taskName = I18N.GetWithParamList(taskNameKey,taskNameParam)
			local hasPre = self._itemData.cachedQuestItem.preId and self._itemData.cachedQuestItem.preId  > 0
			self:SetItemData(taskState, taskName
				,progressCount,progressMax
				,self._chapterQuestCell:Property():Goto(),hasPre,self._chapterQuestCell:Property():Recommend()
			)
		end
	end
end


function ChapterQuestItem:OnGotoClick()
	if self._parentQuestInfoComp.GotoAction ~= nil then
		local taskProp = self._chapterQuestCell:Property()
		self._parentQuestInfoComp:GotoAction(taskProp:Goto())
	end
	g_Game.EventManager:TriggerEvent(
		EventConst.QUEST_SET_FOLLOW,
		self._chapterQuestData
	)
end

function ChapterQuestItem:OnClaimClick()
	if self._parentQuestInfoComp.QuestRewardAction ~= nil then
		self.animation:Play("anim_vx_ui_misson_item_slot_reward")
		
		if self.claimTimer then
			self.claimTimer:Stop()
			self.claimTimer = nil
		end

		self.claimTimer = TimerUtility.DelayExecute(function()
			local rect = self._claimButton:GetComponent(typeof(CS.UnityEngine.RectTransform))
			self._parentQuestInfoComp:QuestRewardAction(self._chapterQuestData.TID, rect, self)
		end, 0.5)
	end
end

function ChapterQuestItem:OnRecycle(way)
	if self._chapterRewards ~= nil then
		table.clear(self._chapterRewards)
		self._chapterRewards = nil
	end
end

function ChapterQuestItem:PlaySwitch()
	if not self._itemData.cachedQuestItem.inChain or not self._itemData.cachedQuestItem.nextId then
		return false
	end

	self.module.Chapter:UpdateQuestCasheItem(self._chapterQuestData.TID)
	local nextCachedItem = self.module.Chapter:UpdateQuestCasheItem(self._itemData.cachedQuestItem.nextId)
	if self._parentQuestInfoComp and Utils.IsNotNull(self.CSComponent) then
		--Dumplet Cell
		---@type CS.UnityEngine.GameObject
		local vfxGo = CS.UnityEngine.GameObject.Instantiate(self.CSComponent.gameObject,self._parentQuestInfoComp.tablePartQuests.transform)
		--UIHelper.DisableUIComponent(vfxGo)
		local comps = vfxGo:GetComponentsInChildren(typeof(CS.DragonReborn.UI.BaseComponent))
		if comps and comps.Length > 0 then
			for i = 0, comps.Length - 1 do
				comps[i].enabled = false
			end
		end
		---@type CS.FpAnimation.CommonTriggerType
		local animTrigger = nil
		if vfxGo then
			local vfxTriggerTrans = vfxGo.transform:Find('vx_trigger_sizhi')
			if vfxTriggerTrans then
				animTrigger = vfxTriggerTrans.gameObject:GetComponent(typeof(CS.FpAnimation.FpAnimationCommonTrigger))
			end
		end
		if animTrigger then
			animTrigger.gameObject:SetActive(true)
			animTrigger:ResetAll(FpAnimTriggerEvent.Custom1)
			animTrigger:PlayAll(FpAnimTriggerEvent.Custom1,function()
				CS.UnityEngine.GameObject.Destroy(vfxGo.gameObject)
			end)
		else
			CS.UnityEngine.GameObject.Destroy(vfxGo.gameObject)
		end
	end

	local taskState = nextCachedItem.state
	local progressCount,progressMax = self.module:GetTaskProgress(nextCachedItem.unit)
	local taskNameKey,taskNameParam = self.module:GetTaskName(nextCachedItem.config)
	local taskName = I18N.GetWithParamList(taskNameKey,taskNameParam)

	self:SetItemData(taskState, taskName
		,progressCount,progressMax
		,self._chapterQuestCell:Property():Goto(),true,self._chapterQuestCell:Property():Recommend()
	)
	return true
end

return ChapterQuestItem