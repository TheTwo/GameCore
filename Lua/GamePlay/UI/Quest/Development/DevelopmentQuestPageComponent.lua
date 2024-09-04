local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TaskType = require("TaskType")
local I18N = require('I18N')

---@class DevelopmentQuestPageComponent:BaseUIComponent
local DevelopmentQuestPageComponent = class("DevelopmentQuestPageComponent", BaseUIComponent)

function DevelopmentQuestPageComponent:ctor()
	self.dailyModule = ModuleRefer.QuestModule.Daily
end

function DevelopmentQuestPageComponent:OnCreate(param)
	self.textDevelopment = self:Text('p_title_development', I18N.Get("ssr_chapter_title"))
    self.tableviewproTableDevelopment = self:TableViewPro('p_table_development')
	self.goContent = self:GameObject('p_development_content')
end

function DevelopmentQuestPageComponent:OnShow()
	g_Game.EventManager:AddListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.OnUserQuestDatabaseChanged))
    g_Game.EventManager:AddListener(EventConst.RECORD_DEVELOPMENT_POS, Delegate.GetOrCreate(self, self.RecordPos))
	self:Refresh()
end

function DevelopmentQuestPageComponent:OnUserQuestDatabaseChanged()
	self:Refresh()
end

function DevelopmentQuestPageComponent:Refresh()
	self:RefreshDevelopmentTask()
end

function DevelopmentQuestPageComponent:RefreshDevelopmentTask()
	self.tableviewproTableDevelopment:Clear()
	for _, id in ipairs(ModuleRefer.QuestModule.growUpQuests) do
		local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(id)
		if taskState < wds.TaskState.TaskStateFinished and taskState > wds.TaskState.TaskStateCanReceive then
			local isCanReward = taskState == wds.TaskState.TaskStateCanFinish
			self.tableviewproTableDevelopment:AppendData({taskId = id, isCanReward = isCanReward})
		end
	end
	self.tableviewproTableDevelopment:RefreshAllShownItem()

	if self.recordPos then
		self.goContent.transform.localPosition = self.recordPos
		self.recordPos = nil
	end
end

function DevelopmentQuestPageComponent:RecordPos()
	self.recordPos = self.goContent.transform.localPosition
end

function DevelopmentQuestPageComponent:OnHide()
	g_Game.EventManager:RemoveListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.OnUserQuestDatabaseChanged))
	g_Game.EventManager:RemoveListener(EventConst.RECORD_DEVELOPMENT_POS, Delegate.GetOrCreate(self, self.RecordPos))
end

function DevelopmentQuestPageComponent:PlayCellsShowAnim()
    local count = self.tableviewproTableDevelopment.CellCount
    for i = 0, count - 1 do
        local cell = self.tableviewproTableDevelopment:GetCell(i)
        cell.Lua:PlayShowAnim()
    end
end

function DevelopmentQuestPageComponent:PlayCellInitAnim()
	local count = self.tableviewproTableDevelopment.CellCount
    for i = 0, count - 1 do
        local cell = self.tableviewproTableDevelopment:GetCell(i)
        cell.Lua:PlayInitAnim()
    end
end

return DevelopmentQuestPageComponent