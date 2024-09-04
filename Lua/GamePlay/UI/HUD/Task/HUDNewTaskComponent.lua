local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')
local NpcServiceObjectType = require('NpcServiceObjectType')
local NewFunctionUnlockIdDefine = require('NewFunctionUnlockIdDefine')
---@class HUDNewTaskComponent:BaseUIComponent
local HUDNewTaskComponent = class("HUDNewTaskComponent",BaseUIComponent)

function HUDNewTaskComponent:ctor(...)
    BaseUIComponent.ctor(self, ...)
    self.questModule = ModuleRefer.QuestModule
end

function HUDNewTaskComponent:OnCreate(param)
    self.btnNpcMessage = self:Button('p_btn_npc_message', Delegate.GetOrCreate(self, self.OnBtnNpcMessageClicked))
    self.imgImgHero = self:Image('p_img_hero')
    self.textName = self:Text('p_text_name')
    self.textNew = self:Text('p_text_new', I18N.Get("new_chapter_chat_new"))

    self.btnMissionExtend = self:Button('p_btn_mission_extend', Delegate.GetOrCreate(self, self.OnBtnMissionExtendClicked))
    self.goMission = self:GameObject('p_collider_mission')
    self.goBase = self:GameObject('base_1')
    self.compChildReddotDefault = self:LuaObject('child_reddot_default')
    self.textMission = self:Text('p_text_mission')
    self.compNpc1 = self:LuaObject('p_btn_npc1')
    self.compNpc2 = self:LuaObject('p_btn_npc2')
    self.compNpc3 = self:LuaObject('p_btn_npc3')
    self.animationTrigger = self:AnimTrigger("vx_trigger_2")
    self.taskNpcs = {self.compNpc1, self.compNpc2, self.compNpc3}
    self.compChildReddotDefault:SetVisible(false)
    self.btnNpcMessage.gameObject:SetActive(false)
end

function HUDNewTaskComponent:OnShow(param)
    self:UpdateMainTask()
    self:RefreshNpcTask()
    self:CheckBtnState()
    self:ResetTime()
    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.Citizen, Delegate.GetOrCreate(self, self.RefreshNpcTask))
    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.RefreshNpcTask))
    g_Game.EventManager:AddListener(EventConst.REFRESH_HUD_NPC_QUEST, Delegate.GetOrCreate(self,self.RefreshNpcTask))
    g_Game.EventManager:AddListener(EventConst.QUEST_LATE_UPDATE, Delegate.GetOrCreate(self,self.RefreshState))
    g_Game.EventManager:AddListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self,self.CheckBtnState))
    g_Game.EventManager:AddListener(EventConst.QUEST_SHOW_EXTEND, Delegate.GetOrCreate(self,self.CheckBtnState))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_NPC_ID_CACHE_REFRESH, Delegate.GetOrCreate(self,self.RefreshNpcTask))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Chapter.MsgPath,Delegate.GetOrCreate(self,self.OnNewChapterIdChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.NpcServices.NpcAcceptedChapters.MsgPath,Delegate.GetOrCreate(self,self.RefreshNpcTask))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Chapter.MsgPath,Delegate.GetOrCreate(self,self.RefreshNpcTask))
    if not self.tickDelegate then
        self.tickDelegate = Delegate.GetOrCreate(self,self.Tick)
        g_Game:AddFrameTicker(self.tickDelegate)
    end
end

function HUDNewTaskComponent:ResetTime()
    self.showFinger = false
    self.showWait = 7
    self.hideWait = 5
    self.curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
end

function HUDNewTaskComponent:Tick(delta)
    local passTime = g_Game.ServerTime:GetServerTimestampInSeconds() - self.curTime
    if passTime > self.showWait and not self.showFinger then
        self.compNpc1:ChangeFingerState(true)
        self:ResetTime()
        self.showFinger = true
        return
    end
    if passTime > self.hideWait and self.showFinger then
        self.compNpc1:ChangeFingerState(false)
        self:ResetTime()
        self.showFinger = false
        return
    end
    if CS.UnityEngine.Input.anyKey then
        self.compNpc1:ChangeFingerState(false)
        self:ResetTime()
        self.showFinger = false
    end
end

function HUDNewTaskComponent:CheckBtnState()
    local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.Quest)
    self.btnMissionExtend.gameObject:SetActive(unlocked)
    if not unlocked then
        for _, taskNpc in ipairs(self.taskNpcs) do
            taskNpc:SetVisible(false)
        end
    end
end

function HUDNewTaskComponent:OnHide(param)
    if self.tickDelegate then
        g_Game:RemoveFrameTicker(self.tickDelegate)
        self.tickDelegate = nil
    end
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.Citizen, Delegate.GetOrCreate(self, self.RefreshNpcTask))
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.RefreshNpcTask))
    g_Game.EventManager:RemoveListener(EventConst.REFRESH_HUD_NPC_QUEST, Delegate.GetOrCreate(self,self.RefreshNpcTask))
    g_Game.EventManager:RemoveListener(EventConst.QUEST_LATE_UPDATE, Delegate.GetOrCreate(self,self.RefreshState))
    g_Game.EventManager:RemoveListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self,self.CheckBtnState))
    g_Game.EventManager:RemoveListener(EventConst.QUEST_SHOW_EXTEND, Delegate.GetOrCreate(self,self.CheckBtnState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_NPC_ID_CACHE_REFRESH, Delegate.GetOrCreate(self,self.RefreshNpcTask))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Chapter.MsgPath,Delegate.GetOrCreate(self,self.OnNewChapterIdChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.NpcServices.NpcAcceptedChapters.MsgPath,Delegate.GetOrCreate(self,self.RefreshNpcTask))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Chapter.MsgPath,Delegate.GetOrCreate(self,self.RefreshNpcTask))
end

function HUDNewTaskComponent:OnNewChapterIdChanged()
    local curNewChapterId = self.questModule.Chapter:GetInProgressNewChapterId()
    local lastNewChapterId = self.questModule.Chapter:GetLastFinishedNewChapterId()
    local isNewDialogue = curNewChapterId == 0
    local chapterId
    if isNewDialogue then --上次完成的章节是0代表现在是第一章
        if lastNewChapterId > 0 then
            chapterId = ConfigRefer.NewMainChapter:Find(lastNewChapterId):Next()
        end
        if chapterId > 0 then
            local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.Quest)
            local chapterCfg = ConfigRefer.NewMainChapter:Find(chapterId)
            local systemSwitch = chapterCfg:SystemSwitch()
            local isLock = false
            if systemSwitch and systemSwitch > 0 then
                isLock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemSwitch)
            end
            local dialogueGroupId = chapterCfg:MainTaskDialog()
            local dialogueIds = {}
            if dialogueGroupId and dialogueGroupId > 0 then
                dialogueIds = self.questModule.Chapter:GetDilaogueIdsByGroupId(dialogueGroupId)
            end
            local showMessage = #dialogueIds > 0 and unlocked and not isLock
            self.btnNpcMessage.gameObject:SetActive(showMessage)
            if showMessage then
                self.btnMissionExtend.gameObject:SetActive(false)
            end
            if showMessage then
                local chatNpc = chapterCfg:Chat()
                local chatNpcCfg = ConfigRefer.ChatNPC:Find(chatNpc)
                g_Game.SpriteManager:LoadSprite(chatNpcCfg:Icon(), self.imgImgHero)
                self.textName.text = I18N.Get(chatNpcCfg:Name())
                self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
                self.newMessageChatNpcId = chatNpc
            end
        else
            self.btnNpcMessage.gameObject:SetActive(false)
        end
    else
        self.btnNpcMessage.gameObject:SetActive(false)
    end
    self:UpdateMainTask()
end

function HUDNewTaskComponent:RefreshState()
    if not self.taskId then
        return
    end
    local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.taskId)
    if taskState == wds.TaskState.TaskStateFinished then
        self:UpdateMainTask()
    end
    if ModuleRefer.QuestModule.Chapter:GetHudQuestAnimState() then
        if self.timer then
            TimerUtility.StopAndRecycle(self.timer)
            self.timer = nil
        end
        self.timer = TimerUtility.DelayExecute(function()
            self:RefreshNpcTask()
        end, 2.3)
    else
        self:RefreshNpcTask()
    end
end

function HUDNewTaskComponent:UpdateMainTask()
    -- local curChapterId = self.questModule.Chapter:GetInProgressNewChapterId()
    -- local lastNewChapterId = self.questModule.Chapter:GetLastFinishedNewChapterId()
    -- local hasChapter = curChapterId > 0
    -- -- self.goBase:SetActive(hasChapter)
    -- self.goMission:SetActive(hasChapter)
    -- if hasChapter then
    --     self.taskId = ConfigRefer.NewMainChapter:Find(curChapterId):MainTask()
    --     self.textMission.text = ModuleRefer.QuestModule:GetTaskDesc(self.taskId)
    -- else
    --     local chapterId = 0
    --     if lastNewChapterId == 0 then --上次完成的章节是0代表现在是第一章
    --         chapterId = 1
    --     elseif lastNewChapterId > 0 then
    --         chapterId = ConfigRefer.NewMainChapter:Find(lastNewChapterId):Next()
    --     end
    --     if chapterId > 0 then
    --         local chapterCfg = ConfigRefer.NewMainChapter:Find(chapterId)
    --         local systemSwitch = chapterCfg:SystemSwitch()
    --         local isLock = false
    --         if systemSwitch and systemSwitch > 0 then
    --             isLock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemSwitch)
    --         end
    --         if not isLock then
    --             local mainChatNpc = chapterCfg:Chat()
    --             local chatNpcCfg = ConfigRefer.ChatNPC:Find(mainChatNpc)
    --             self.textMission.text = I18N.GetWithParams("new_chapter_task_tips_short", I18N.Get(chatNpcCfg:Name()))
    --         else
    --             self.textMission.text = ''
    --         end
    --     else
    --         self.textMission.text = ''
    --     end
    -- end
end

function HUDNewTaskComponent:RefreshNpcTask()
    -- if ModuleRefer.QuestModule.Chapter:GetHudQuestAnimState() then
    --     return
    -- end
    -- if self.timer then
    --     TimerUtility.StopAndRecycle(self.timer)
    --     self.timer = nil
    -- end
    -- local receivedTaskChatNpcList = self.questModule.Chapter:GetReceivedTaskChatNpcs()
    -- local allNpcIds = self.questModule.Chapter:GetAllNpcsInCurChapter() or {}
    -- local showedNpc = {}
    -- local taskCount = 0
    -- local showInfos = {}
    -- for i = 1, #self.taskNpcs do
    --     local chatNpcInfo = receivedTaskChatNpcList[i]
    --     local isShow = chatNpcInfo ~= nil and not showedNpc[chatNpcInfo.chatNpcId]
    --     self.taskNpcs[i]:SetVisible(isShow)
    --     if isShow then
    --         showedNpc[chatNpcInfo.chatNpcId] = true
    --         if isShow then
    --             if allNpcIds[chatNpcInfo.chatNpcId] then
    --                 allNpcIds[chatNpcInfo.chatNpcId].showHead = false
    --             end
    --             taskCount = taskCount + 1
    --             chatNpcInfo.isAllFinish = false
    --             showInfos[#showInfos + 1] = {chatNpcInfo = chatNpcInfo, index = i}
    --             g_Logger.LogChannel('HUDNewTaskComponent', chatNpcInfo.chatNpcId)
    --         end
    --     end
    -- end
    -- if taskCount >= #self.taskNpcs then
    --     for i, head in ipairs(self.taskNpcs) do
    --         local info = showInfos[i]
    --         head:SetVisible(info ~= nil)
    --         if info then
    --             head:UpdateNpcInfo(info.chatNpcInfo, info.index, self.animationTrigger)
    --         end
    --     end
    --     return
    -- end
    -- local singles = {}
    -- for chatNpcId, info in pairs(allNpcIds) do
    --     singles[#singles + 1] = {chatNpcId = chatNpcId, info = info}
    -- end
    -- for i = 1, #singles do
    --     local npcInfo = singles[i]
    --     if npcInfo and not showedNpc[npcInfo.chatNpcId] then
    --         showedNpc[npcInfo.chatNpcId] = true
    --         if npcInfo.info.showHead then
    --             local showNpc = self.taskNpcs[taskCount + 1]
    --             if showNpc then
    --                 showNpc:SetVisible(true)
    --                 local chatNpcInfo = {}
    --                 chatNpcInfo.isNpc = npcInfo.info.isNpc
    --                 chatNpcInfo.chatNpcId = npcInfo.chatNpcId
    --                 chatNpcInfo.cityElementNpcId = npcInfo.info.cityElementNpcId
    --                 chatNpcInfo.citizenId = npcInfo.info.citizenId
    --                 chatNpcInfo.isAllFinish = true
    --                 g_Logger.LogChannel('HUDNewTaskComponent', chatNpcInfo.chatNpcId)
    --                 showInfos[#showInfos + 1] = {chatNpcInfo = chatNpcInfo, index = taskCount + 1}
    --             end
    --         end
    --     end
    -- end
    -- local sortFunc = function(a, b)
    --     if a.chatNpcInfo.isAllFinish ~= b.chatNpcInfo.isAllFinish then
    --         return a.chatNpcInfo.isAllFinish
    --     else
    --         return a.index < b.index
    --     end
    -- end
    -- table.sort(showInfos, sortFunc)
    -- for i, head in ipairs(self.taskNpcs) do
    --     local info = showInfos[i]
    --     head:SetVisible(info ~= nil)
    --     if info then
    --         head:UpdateNpcInfo(info.chatNpcInfo, i, self.animationTrigger)
    --     end
    -- end
end

function HUDNewTaskComponent:OnBtnMissionExtendClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.QuestEventUIMediator)
end

function HUDNewTaskComponent:OnBtnNpcMessageClicked(args)
    self.btnNpcMessage.gameObject:SetActive(false)
    self.btnNpcMessage.gameObject:SetActive(false)
    self.btnMissionExtend.gameObject:SetActive(true)
    g_Game.UIManager:Open(UIMediatorNames.QuestEventUIMediator, {chatNpcId = self.newMessageChatNpcId, isNew = false})
end

return HUDNewTaskComponent