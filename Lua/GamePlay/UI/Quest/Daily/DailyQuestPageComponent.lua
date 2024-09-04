local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local DBEntityPath = require('DBEntityPath')
local Utils = require('Utils')

local PROGRESS_WIDTH = 1132
local MIN_X = -750

---@class DailyQuestPageComponent:BaseUIComponent
local DailyQuestPageComponent = class("DailyQuestPageComponent", BaseUIComponent)

function DailyQuestPageComponent:ctor()
	self.dailyModule = ModuleRefer.QuestModule.Daily
end

function DailyQuestPageComponent:OnCreate(param)
    self.sliderProgressDay = self:Slider('p_progress_day')
    self.goItemGift1 = self:GameObject('p_item_gift_1')
    self.compItemGift1 = self:LuaObject('p_item_gift_1')
    self.goItemGift2 = self:GameObject('p_item_gift_2')
    self.compItemGift2 = self:LuaObject('p_item_gift_2')
    self.goItemGift3 = self:GameObject('p_item_gift_3')
    self.compItemGift3 = self:LuaObject('p_item_gift_3')
    self.goItemGift4 = self:GameObject('p_item_gift_4')
    self.compItemGift4 = self:LuaObject('p_item_gift_4')
    self.goItemGift5 = self:GameObject('p_item_gift_5')
    self.compItemGift5 = self:LuaObject('p_item_gift_5')
    self.textLv = self:Text('p_text_lv')
	self.textDay = self:Text('p_title_day', I18N.Get("daily_info_name"))
    self.textActivity = self:Text('p_text_activity', I18N.Get('daily_info_point'))
    self.tableviewproTableDay = self:TableViewPro('p_table_day')
	self.goContent = self:GameObject('p_day_content')
	self.giftComps = {self.compItemGift1, self.compItemGift2, self.compItemGift3, self.compItemGift4, self.compItemGift5}
	self.giftGos = {self.goItemGift1, self.goItemGift2, self.goItemGift3, self.goItemGift4, self.goItemGift5}
end

function DailyQuestPageComponent:PlayCellsShowAnim()
	for _, comp in ipairs(self.giftComps) do
		comp:PlayShowAnim()
	end
	local count = self.tableviewproTableDay.CellCount
    for i = 0, count - 1 do
        local cell = self.tableviewproTableDay:GetCell(i)
        cell.Lua:PlayShowAnim()
    end
end

function DailyQuestPageComponent:PlayCellInitAnim()
	for _, comp in ipairs(self.giftComps) do
		comp:PlayInitAnim()
	end
	local count = self.tableviewproTableDay.CellCount
    for i = 0, count - 1 do
        local cell = self.tableviewproTableDay:GetCell(i)
        cell.Lua:PlayInitAnim()
    end
end

function DailyQuestPageComponent:OnShow()
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.DailyTaskInfo.MsgPath, Delegate.GetOrCreate(self,self.OnUserQuestDatabaseChanged))
    g_Game.EventManager:AddListener(EventConst.RECORD_DAILY_POS, Delegate.GetOrCreate(self, self.RecordPos))
	self:Refresh()
end

function DailyQuestPageComponent:OnUserQuestDatabaseChanged()
	self:Refresh()
end

function DailyQuestPageComponent:Refresh()
	self:RefreshDailyProgress()
	self:RefreshDailyTask()
end

function DailyQuestPageComponent:RefreshDailyProgress()
	local curScore = self.dailyModule:GetCurScore()
	local totalScore = ConfigRefer.DailyTaskConst:MaxProgress()
	self.sliderProgressDay.value = curScore / totalScore
	self.textLv.text = curScore
	local dailyTaskCfg = self.dailyModule:GetDailyTaskCfg()
	if not dailyTaskCfg then
		return
	end
	local progressId = dailyTaskCfg:Progress()
	local progressCfg = ConfigRefer.DailyTaskProgress:Find(progressId)
	local maxProgress = progressCfg:Progress(progressCfg:ProgressLength())
	for i = 1, progressCfg:ProgressLength() do
		local curProgress = progressCfg:Progress(i)
		if self.giftComps[i] then
			self.giftComps[i]:FeedData({index = i, cfg = progressCfg})
			self.giftGos[i].transform.localPosition = CS.UnityEngine.Vector3((curProgress / maxProgress) * PROGRESS_WIDTH + MIN_X, 84, 0)
		end
	end
end

function DailyQuestPageComponent:RefreshDailyTask()
	self.tableviewproTableDay:Clear()
	local processingRecommendTasks = {}
	Utils.CopyArray(self.dailyModule.dailyTaskInfo.ProcessingRecommendTasks, processingRecommendTasks)
	local sort = function(a, b)
		local isCanRewardA = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(a) ==  wds.TaskState.TaskStateCanFinish
		local isCanRewardB = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(b) ==  wds.TaskState.TaskStateCanFinish
		if isCanRewardA ~= isCanRewardB then
			return isCanRewardA
		else
			return a < b
		end
	end
	table.sort(processingRecommendTasks, sort)

	local finishedMap = {}
	local finishedRecommendedTasks = self.dailyModule.dailyTaskInfo.FinishedRecommendedTasks
	local finishedNormalTasks = self.dailyModule.dailyTaskInfo.FinishedNormalTasks
	for _, id in ipairs(finishedRecommendedTasks) do
		finishedMap[id] = true
	end
	for _, id in ipairs(finishedNormalTasks) do
		finishedMap[id] = true
	end

	for _, id in ipairs(processingRecommendTasks) do
		if finishedMap[id] then goto continue end
		local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(id)
		if taskState < wds.TaskState.TaskStateReceived then goto continue end
		local isCanReward = taskState == wds.TaskState.TaskStateCanFinish
		self.tableviewproTableDay:AppendData({taskId = id, isRecommend = true, isFinish = false, isCanReward = isCanReward})
		::continue::
	end

	local id2Key = {}
	for index, id in ipairs(self.dailyModule.dailyTaskInfo.ProcessingNormalTasks) do
		id2Key[id] = index
	end
	local processingNormalTasks = {}
	Utils.CopyArray(self.dailyModule.dailyTaskInfo.ProcessingNormalTasks, processingNormalTasks)
	table.sort(processingNormalTasks, sort)
	for _, id in ipairs(processingNormalTasks) do
		if finishedMap[id] then goto continue end
		local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(id)
		if taskState < wds.TaskState.TaskStateReceived then goto continue end
		local isCanReward = taskState == wds.TaskState.TaskStateCanFinish
		self.tableviewproTableDay:AppendData({taskId = id, isRecommend = false, isFinish = false, isCanReward = isCanReward, index = id2Key[id]})
		::continue::
	end

	for _, id in ipairs(finishedRecommendedTasks) do
		self.tableviewproTableDay:AppendData({taskId = id, isRecommend = true, isFinish = true, isCanReward = false})
	end
	for _, id in ipairs(finishedNormalTasks) do
		self.tableviewproTableDay:AppendData({taskId = id, isRecommend = false, isFinish = true, isCanReward = false})
	end
	if self.recordPos then
		self.goContent.transform.localPosition = self.recordPos
		self.recordPos = nil
	end
	self.tableviewproTableDay:RefreshAllShownItem()
end

function DailyQuestPageComponent:RecordPos()
	self.recordPos = self.goContent.transform.localPosition
end

function DailyQuestPageComponent:OnHide()
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.DailyTaskInfo.MsgPath, Delegate.GetOrCreate(self,self.OnUserQuestDatabaseChanged))
	g_Game.EventManager:RemoveListener(EventConst.RECORD_DAILY_POS, Delegate.GetOrCreate(self, self.RecordPos))
end

return DailyQuestPageComponent