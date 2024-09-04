local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local EventConst = require('EventConst')
local I18N = require('I18N')
--local DBRefer = require('DBRefer')
---@class ChapterQuestPageComponent : BaseUIComponent
---@field module QuestModule_Chapter
---@field chapterTarget ChapterTargetComponent
---@field allQuestInfo ChpaterQuestInfoComponent
local ChapterQuestPageComponent = class("ChapterQuestPageComponent", BaseUIComponent)

function ChapterQuestPageComponent:ctor()
	self.module = ModuleRefer.QuestModule.Chapter;
	self.animState = 0;
	self.questNpcDialg = nil
end

function ChapterQuestPageComponent:OnCreate(param)
	self.chapterTarget = self:LuaObject('content_target_mission');
	self.allQuestInfo = self:LuaObject('content_target_process');
end

function ChapterQuestPageComponent:PlayCellsShowAnim()
    self.allQuestInfo:PlayCellsShowAnim()
end

function ChapterQuestPageComponent:PlayCellInitAnim()
    self.allQuestInfo:PlayCellInitAnim()
end
---------------------------------------------------------------
---State Ctrl Interface
--显示PartNormal的状态
function ChapterQuestPageComponent:ShowPartNormalState()
	self._chapterConfig = self.module:CurrentChapterConfig()
	self.chapterTarget:SetVisible(false)
	self.allQuestInfo:SetVisible(true)
	self.allQuestInfo:OnChapterQuestNormal()
end

---显示PartComplete状态
---@param lastChapterConfig ChapterConfigCell
function ChapterQuestPageComponent:ShowPartCompletePage(lastChapterConfig)
	self.allQuestInfo:ShowPartCompletePage(lastChapterConfig)
	self.chapterTarget:SetVisible(false)
end

--更新任务列表但不重新排序 用于播放解锁动画
function ChapterQuestPageComponent:UpdatePartNormalState()
	self.allQuestInfo:OnChapterQuestNormal()
end

--显示章目标页面 - 普通状态
function ChapterQuestPageComponent:ShowChapterTarget()
	self._chapterConfig = self.module:CurrentChapterConfig()
	self.chapterTarget:SetVisible(true)
end

function ChapterQuestPageComponent:HideChapterTarget()
	self.chapterTarget:SetVisible(false)
end
--------------------------------------------------------------

function ChapterQuestPageComponent:OnUserQuestDatabaseChanged(data,changed)
	if self.module ~= nil and self.module.stateCtrl ~= nil then
		self.module.stateCtrl:Refresh()
	end
end

function ChapterQuestPageComponent:OnShow()
	self.module:OnViewerInit(self);
	self.module:StartPageState();
	g_Game.EventManager:AddListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.OnUserQuestDatabaseChanged))

end

function ChapterQuestPageComponent:OnHide()
	self.module:StopPageState();
	self.questNpcDialg = nil;
	g_Game.EventManager:RemoveListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.OnUserQuestDatabaseChanged))
	self.module:UpdateQuestCache(true)
end

return ChapterQuestPageComponent