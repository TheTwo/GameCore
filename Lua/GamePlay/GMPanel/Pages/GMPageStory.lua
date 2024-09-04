local DBEntityPath = require("DBEntityPath")
local GUILayout = require("GUILayout")
local Delegate = require("Delegate")
local GMPage = require("GMPage")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")

---@class GMPageStory:GMPage
---@field new fun():GMPageStory
---@field super GMPage
local GMPageStory = class('GMPageStory', GMPage)

function GMPageStory:ctor()
    self._storyId = "0"
    self._choice = "0"
    ---@type table<number, wds.StoryInfo>
    self._storyInfo = nil
    self._cgTimelineAsset = nil
    self._cgHideElements = nil
    self._noBlockGesture = false
end

function GMPageStory:OnShow()
    ---@type StoryModule
    self._storyModule = g_Game.ModuleManager:RetrieveModule("StoryModule")
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Story.MsgPath, Delegate.GetOrCreate(self, self.OnStoryDataChanged))
end

function GMPageStory:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Story.MsgPath, Delegate.GetOrCreate(self, self.OnStoryDataChanged))
end

function GMPageStory:Release()
    self._storyInfo = nil
end

function GMPageStory:OnGUI()
    GUILayout.BeginHorizontal()
    GUILayout.Label("StoryId/StepId/DialogGroupId", GUILayout.shrinkWidth)
    self._storyId = GUILayout.TextField(self._storyId)
    GUILayout.Label("choice", GUILayout.shrinkWidth)
    self._choice = GUILayout.TextField(self._choice)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    if GUILayout.Button("测试开始") then
        self._storyModule:StoryStart(tonumber(self._storyId), function(storyId, result) 
            g_Logger.Error("%d,%d", storyId, result)
        end)
        self.panel:PanelShow(false)
    end
    if GUILayout.Button("测试字幕") then
        local param = require("StoryDialogUIMediatorParameter").new()
        param:SetCaption(tonumber(self._storyId), function()
            g_Game.UIManager:CloseByName(require('UIMediatorNames').StoryDialogUIMediator)
        end)
        g_Game.UIManager:Open(require('UIMediatorNames').StoryDialogUIMediator, param)
        self.panel:PanelShow(false)
    end
    if GUILayout.Button("测试对话") then
        local param = require("StoryDialogUIMediatorParameter").new()
        local type = param:SetDialogGroup(tonumber(self._storyId), function(uiRuntimeId)
            if uiRuntimeId then
                g_Game.UIManager:Close(uiRuntimeId)
            end
        end)
        ModuleRefer.StoryModule:OpenDialogMediatorByType(type, param)
        self.panel:PanelShow(false)
    end
    if GUILayout.Button("本地测试剧情") then
        if self._storyModule:LocalStart(tonumber(self._storyId)) then
            self.panel:PanelShow(false)
        end
    end
    if GUILayout.Button("上报完成Step") then
        self._storyModule:StoryFinish(tonumber(self._storyId), tonumber(self._choice))
    end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.FlexibleSpace()
    if GUILayout.Button("DumpStoryInfo") then
        self:OnStoryDataChanged()
        self:DumpStoryInfo(self._storyInfo)
    end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    if GUILayout.Button("立即完成当前step") then
        local g,c = self._storyModule:GetStatus()
        if g then
            g.HasError = false
            local step = g:GetCurrentStep()
            if step then
                step.IsFailure = false
                step.HashError = false
                step:EndStep()
                return
            end
        end
    end
    --GUILayout.Label('Quest Test')
    --if GUILayout.Button("Test New Chapter win") then
    --    g_Game.UIManager:Open(require('UIMediatorNames').NewChapterUIMediator,{ onWinClose = function()
    --        g_Logger.LogChannel('Quest Test',"New Chapter win Closed!")
    --    end})
    --end
    --
    --if GUILayout.Button("Test Main Chapter win") then
    --    require('ModuleRefer').QuestModule:OpenMissionWindow(1)
    --end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("测试Timeline资源名", GUILayout.shrinkWidth)
    self._cgTimelineAsset = GUILayout.TextField(self._cgTimelineAsset)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("播放时隐藏elements,分隔", GUILayout.shrinkWidth)
    self._cgHideElements = GUILayout.TextField(self._cgHideElements)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    self._noBlockGesture = GUILayout.Toggle(self._noBlockGesture, "允许场景点击")
    if GUILayout.Button("播放") then
        local s = require("StoryTimeline").new()
        local releaseHelper = {}
        releaseHelper.OnTimePlayEnd = function(helper)
            g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(helper, helper.OnTimePlayEnd))
            s:Release()
        end
        local ele = {}
        if not string.IsNullOrEmpty(self._cgHideElements) then
            local arr = string.split(self._cgHideElements, ',')
            for i, v in ipairs(arr) do
                if not string.IsNullOrEmpty(v) then
                    ele[tonumber(v)] = true
                end
            end
        end
        s:FillData(1, self._cgTimelineAsset, self._noBlockGesture, ele)
        g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(releaseHelper, releaseHelper.OnTimePlayEnd))
        s:PrepareAsset(true)
    end
    GUILayout.EndHorizontal()
end

function GMPageStory:OnStoryDataChanged(data, changed)
    ---@type StoryModule
    local storyModule = g_Game.ModuleManager:RetrieveModule("StoryModule")
    self._storyInfo = storyModule:QueryCurrentStoryInfo()
end

function GMPageStory:DumpStoryInfo(storyInfo)
    if not storyInfo then
        g_Logger.TraceChannel(nil, "storyInfo - nil")
        return
    end
    dump(storyInfo)
    for _, storyStepInfo in ipairs(storyInfo) do
        dump(storyStepInfo)
    end
end

return GMPageStory
