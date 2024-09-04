local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local StoryDialogPlaceType = require('StoryDialogPlaceType')
local UIHelper = CS.DragonReborn.UI.UIHelper
local TimeFormatter = require("TimeFormatter")
local TimerUtility = require('TimerUtility')
local DBEntityPath = require('DBEntityPath')
local AcceptNpcCitizenChapterParameter = require('AcceptNpcCitizenChapterParameter')
---@class QuestEventUIMediator : BaseUIMediator
---@field btnBack CommonBackButtonComponent
local QuestEventUIMediator = class("QuestEventUIMediator", BaseUIMediator)

function QuestEventUIMediator:OnCreate()

    self.textTime = self:Text('p_text_time')
    self.textMessages = self:Text('p_text_messages', "new_chapter_chat_app_name")
    self.textNow = self:Text('p_text_now', "new_chapter_phone_time")
    self.btnMessage = self:Button('p_btn_message', Delegate.GetOrCreate(self, self.OnBtnMessageClicked))
    self.textName = self:Text('p_text_name')
    self.textMessage = self:Text('p_text_messagehint', "new_chapter_phone_tips")
    self.compChildCardHeroS = self:LuaObject('child_card_hero_s')
    self.btnPhone = self:Button('p_phone_btn', Delegate.GetOrCreate(self, self.OnBtnPhoneClicked))


    self.goStatusMessage = self:GameObject('p_status_message')
    self.textMessage = self:Text('p_text_message', I18N.Get("new_chapter_chat_app_name"))
    self.tableviewproTableLeft = self:TableViewPro('p_table_left')
    self.goStatusChat = self:GameObject('p_status_chat')
    self.btnBack = self:Button('p_btn_back', Delegate.GetOrCreate(self, self.OnBtnBackClicked))
    self.compChildReddotDefault = self:LuaObject('child_reddot_default')
    self.textChat = self:Text('p_text_chat')
    self.tableviewproTableChat = self:TableViewPro('p_table_chat')
    self.goDisconnected = self:GameObject('p_disconnected')
    self.textDisconnected = self:Text('p_text_disconnected', 'new_chapter_nosignal_long')
    self.imgImgHero = self:Image('p_img_hero')
    self.goImgHeroLock = self:GameObject('p_img_hero_lock')
    self.textTarget = self:Text('p_text_target', I18N.Get("new_chapter_task_title"))
    self.goClaimed = self:GameObject('p_claimed')
    self.textTask = self:Text('p_text_task')
    self.textTargetNum = self:Text('p_text_target_num')
    self.btnLeft = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnBtnLeftClicked))
    self.btnRight = self:Button('p_btn_right', Delegate.GetOrCreate(self, self.OnBtnRightClicked))
    self.goStatusEmpty = self:GameObject('p_status_empty')
    self.textEmpty = self:Text('p_text_empty')
    self.goTableTask = self:GameObject('p_table_task')
    self.tableviewproTableTask = self:TableViewPro('p_table_task')
    self.goStatusLock = self:GameObject('p_status_lock')
    self.textNeed = self:Text('p_text_need', I18N.Get("*需要"))
    self.tableviewproTableNeed = self:TableViewPro('p_table_need')
    self.animationTrigger = self:AnimTrigger("trigger")
    self.btnChildCommonBackS = self:Button('child_common_btn_back_s', Delegate.GetOrCreate(self, self.OnCloseWin))
    local cellPrefab = self.tableviewproTableChat.cellPrefab[0]
	self.prefabText = cellPrefab:GetComponentInChildren(typeof(CS.DragonReborn.UI.ShrinkText))
    local cellPrefabRight = self.tableviewproTableChat.cellPrefab[3]
	self.prefabTextRight = cellPrefabRight:GetComponentInChildren(typeof(CS.DragonReborn.UI.ShrinkText))
    self.goClaimed:SetActive(false)
    self.btnPhone.gameObject:SetActive(false)
end

function QuestEventUIMediator:OnShow(param)
    self.isShowingDialogue = false
    self.needCustomRefreshRight = false
    g_Game.EventManager:AddListener(EventConst.QUEST_EVENT_CHAT_NPC_CLICKED, Delegate.GetOrCreate(self, self.OnClickChatNpc))
    g_Game.EventManager:AddListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.OnTaskChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Chapter.LastFinishedNewChapter.MsgPath,Delegate.GetOrCreate(self,self.OnLastFinishedNewChapterChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Chapter.InProgressNewChapter.MsgPath,Delegate.GetOrCreate(self,self.OnInProgressNewChapterChanged))
    self.questChapterModule = ModuleRefer.QuestModule.Chapter
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        return
    end
    self:RefreshNpcDialogeState()
    self:ShowMessageState()
    self.curShowChapter = self:GetMaxSelectChapter()
    self:RefreshChapterInfo()
    self.showNewDialogueSpace = 0.5
    if param then
        if type(param) == 'string' then
            local chatNpcId = tonumber(param)
            if chatNpcId then
                self.outerChatNpcId = chatNpcId
            end
        elseif param.chatNpcId then
            self.outerChatNpcId = param.chatNpcId
            self.isNew = param.isNew
        end
        self.btnPhone.gameObject:SetActive(true)
        if self.isNew then
            self:ShowNewChatNpcMessage()
        else
            self:OnBtnMessageClicked()
        end
    end
end

function QuestEventUIMediator:ShowNewChatNpcMessage()
    self.textTime.text = TimeFormatter.TimeToDateTimeStringUseFormat(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor(), "HH:mm")
    local chatNpcCfg = ConfigRefer.ChatNPC:Find(self.outerChatNpcId)
    self.textName.text = I18N.Get(chatNpcCfg:Name())
    self.compChildCardHeroS:ShowCustomIcon(chatNpcCfg:Icon())
    self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
end

function QuestEventUIMediator:OnBtnMessageClicked(args)
    self.animationTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom5)
    self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom6, function()
        self.btnPhone.gameObject:SetActive(true)
    end)
    local chatNpcData = self.chatNpcDataMap[self.outerChatNpcId]
    if chatNpcData then
        self:OnClickChatNpc(chatNpcData)
        self.btnBack.gameObject:SetActive(false)
        self.compChildReddotDefault:SetVisible(false)
    end
end

function QuestEventUIMediator:OnBtnPhoneClicked(args)
    self:QuickShowAllDialogue()
end

function QuestEventUIMediator:QuickShowAllDialogue()
    if self.delayShowTimer then
        TimerUtility.StopAndRecycle(self.delayShowTimer)
        self.delayShowTimer = nil
    end
    self.showNewDialogueSpace = -1
    if self.nextShowDialogue then
        self:ShowSingeDialogues(self.nextShowDialogue[1],self.nextShowDialogue[2],self.nextShowDialogue[3],self.nextShowDialogue[4],self.nextShowDialogue[5])
    else
        self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom7, function()
            self.btnPhone.gameObject:SetActive(false)
        end)
        self.btnBack.gameObject:SetActive(true)
        self.compChildReddotDefault:SetVisible(true)
        self:RefreshRedDotNum()
        self:RefreshChapterInfo()
    end
end

function QuestEventUIMediator:RefreshNpcDialogeState()
    self.redDotNum = 0
    self.chatNpcDataMap = {}
    self.tableviewproTableLeft:Clear()
    local chatNpcId2Tasks = self.questChapterModule:GetAllChatNpcTasks()
    --刷新主Npc对白
    local curNewChapterId = self.questChapterModule:GetInProgressNewChapterId()
    local lastNewChapterId = self.questChapterModule:GetLastFinishedNewChapterId()
    local chapterId
    local mainChatNpc
    local allDialogues
    local newDialogueIds
    if curNewChapterId == 0 then --当前没有正在进行的chapter
        if lastNewChapterId == 0 then --上次完成的章节是0代表现在是第一章
            chapterId = 1
        elseif lastNewChapterId > 0 then
            chapterId = ConfigRefer.NewMainChapter:Find(lastNewChapterId):Next()
        end
        if chapterId > 0 then
            local chapterCfg = ConfigRefer.NewMainChapter:Find(chapterId)
            mainChatNpc = chapterCfg:Chat()
            local systemSwitch = chapterCfg:SystemSwitch()
            local isLock = false
            if systemSwitch and systemSwitch > 0 then
                isLock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemSwitch)
            end
            allDialogues = self.questChapterModule:GetAllDialogueIds(chatNpcId2Tasks, mainChatNpc)
            if not isLock then --需要和主npc进行对话之后领取任务
                local dialogueGroupId = chapterCfg:MainTaskDialog()
                local dialogueIds = {}
                if dialogueGroupId and dialogueGroupId > 0 then
                    dialogueIds = self.questChapterModule:GetDilaogueIdsByGroupId(dialogueGroupId)
                end
                newDialogueIds = dialogueIds
                for _, dialogueId in ipairs(dialogueIds) do
                    allDialogues[#allDialogues+1] = {dialogueId, chapterId}
                end
            end
        else --如果ChapterId == 0代表当前所有的章节都已经完成了
            local chapterCfg = ConfigRefer.NewMainChapter:Find(lastNewChapterId)
            mainChatNpc = chapterCfg:Chat()
            allDialogues = self.questChapterModule:GetAllDialogueIds(chatNpcId2Tasks, mainChatNpc)
        end
    else
        local chapterCfg = ConfigRefer.NewMainChapter:Find(curNewChapterId)
        mainChatNpc = chapterCfg:Chat()
        allDialogues = self.questChapterModule:GetAllDialogueIds(chatNpcId2Tasks, mainChatNpc)
    end
    local data = {}
    data.isMainChatNpc = true
    data.chatNpcId = mainChatNpc
    data.allDialogues = allDialogues
    data.newDialogueIds = newDialogueIds
    data.acceptChapterId = chapterId
    self.chatNpcDataMap[mainChatNpc] = data
    self.tableviewproTableLeft:AppendData(data)
    if newDialogueIds and #newDialogueIds > 0 then
        self.redDotNum = self.redDotNum + #newDialogueIds
    end
    --刷新非主Npc对白
    local checkChapterId
    if curNewChapterId == 0 and lastNewChapterId > 0 then --当前没有正在进行的chapter并且已经完成了上个章节的
        checkChapterId = lastNewChapterId
    elseif curNewChapterId > 0 then
        checkChapterId = curNewChapterId
    end
    local outOfSignalChatNpcs = {}
    if curNewChapterId > 0 then
        outOfSignalChatNpcs = self.questChapterModule:GetChapterOutOfSignalChatNpcs(curNewChapterId)
    end
    local chatNpcList = {}
    if checkChapterId then
        for chatNpcId, tasks in pairs(chatNpcId2Tasks) do
            local task = self:GetMaxElementNpcIdTask(tasks)
            if task.newChapterId <= checkChapterId then
                if chatNpcId ~= mainChatNpc then
                    if not chatNpcList[chatNpcId] then
                        local isChapterContainChatNpc = self.questChapterModule:IsChapterContainChatNpc(checkChapterId, chatNpcId)
                        local isChatNpcContainChapter = self.questChapterModule:IsChatNpcContainChapter(task, checkChapterId)
                        local single = {}
                        single.isMainChatNpc = false
                        single.chatNpcId = chatNpcId
                        single.newChapterId = task.newChapterId
                        single.priority = task.priority
                        single.isNpc = task.isNpc
                        if single.isNpc then
                            single.cityElementNpcId = task.cityElementNpcId
                        else
                            single.citizenId = task.citizenId
                        end
                        local allNpcDialogues = self.questChapterModule:GetAllDialogueIds(chatNpcId2Tasks, chatNpcId)
                        --判断检查章节的npc对话中包含此npc的对话，但是此npc的章节任务数据并不包含检查章节，则代表了需要对话之后再给此npc接取检查章节
                        if isChapterContainChatNpc and not isChatNpcContainChapter then
                            local dialogueGroupId = self.questChapterModule:GetChapterDialogueInfoByNpcId(checkChapterId, chatNpcId)
                            local dialogueIds = {}
                            if dialogueGroupId and dialogueGroupId > 0 then
                                dialogueIds = self.questChapterModule:GetDilaogueIdsByGroupId(dialogueGroupId)
                            end
                            single.newDialogueIds = dialogueIds
                            single.acceptChapterId = checkChapterId
                            single.hasNew = true
                            if #dialogueIds > 0 then
                                self.redDotNum = self.redDotNum + #dialogueIds
                                for _, dialogueId in ipairs(dialogueIds) do
                                    allNpcDialogues[#allNpcDialogues+1] = {dialogueId, checkChapterId}
                                end
                            end
                            single.allDialogues = allNpcDialogues
                        else
                            single.allDialogues = allNpcDialogues
                            single.newDialogueIds = nil
                            single.hasNew = false
                        end
                        single.outOfSignal = outOfSignalChatNpcs[chatNpcId] ~= nil
                        chatNpcList[#chatNpcList+1] = single
                    end
                end
            end
        end
    end
    local sortfunc = function(a, b)
        if a.hasNew ~= b.hasNew then
            return a.hasNew
        else
            if a.newChapterId ~= b.newChapterId then
                return a.newChapterId > b.newChapterId
            else
                if a.priority ~= b.priority then
                    return a.priority < b.priority
                else
                    if a.chatNpcId ~= b.chatNpcId then
                        return a.chatNpcId > b.chatNpcId
                    else
                        return false
                    end
                end
            end
        end
    end
    table.sort(chatNpcList, sortfunc)
    for _, v in ipairs(chatNpcList) do
        self.chatNpcDataMap[v.chatNpcId] = v
        self.tableviewproTableLeft:AppendData(v)
    end
end

function QuestEventUIMediator:GetMaxElementNpcIdTask(tasks)
    local task = tasks[#tasks]
    if task.isNpc then
        local maxElementNpcId = 0
        for _, v in ipairs(tasks) do
            if v.cityElementNpcId > maxElementNpcId then
                maxElementNpcId = v.cityElementNpcId
                task = v
            end
        end
    end
    return task
end

function QuestEventUIMediator:ShowMessageState()
    self.goStatusMessage:SetActive(true)
    self.goStatusChat:SetActive(false)
end

function QuestEventUIMediator:ShowChatState()
    self.goStatusMessage:SetActive(false)
    self.goStatusChat:SetActive(true)
end


function QuestEventUIMediator:GetHeight(showText)
    local settings = self.prefabText:GetGenerationSettings(CS.UnityEngine.Vector2(self.prefabText:GetPixelAdjustedRect().size.x, 0))
    local height = self.prefabText.cachedTextGeneratorForLayout:GetPreferredHeight(showText, settings) / self.prefabText.pixelsPerUnit
    return height + 26
end

function QuestEventUIMediator:GetHeightRight(showText)
    local settings = self.prefabTextRight:GetGenerationSettings(CS.UnityEngine.Vector2(self.prefabTextRight:GetPixelAdjustedRect().size.x, 0))
    local height = self.prefabTextRight.cachedTextGeneratorForLayout:GetPreferredHeight(showText, settings) / self.prefabTextRight.pixelsPerUnit
    return height + 26
end

function QuestEventUIMediator:OnClickChatNpc(chatNpcData)
    self.showNewDialogueSpace = 0.5
    self:ShowChatState()
    local newDialogueIds = chatNpcData.newDialogueIds or {}
    local redDotNum = #newDialogueIds
    local showNum = self.redDotNum - redDotNum
    self.compChildReddotDefault:SetVisible(showNum > 0)
    if showNum > 0 then
        self.compChildReddotDefault:ShowNumRedDot(showNum)
    end
    local chatNpcCfg = ConfigRefer.ChatNPC:Find(chatNpcData.chatNpcId)
    self.textChat.text = I18N.Get(chatNpcCfg:Name())
    self.tableviewproTableChat:Clear()
    local hasHistory = false
    local showNpcHead = {}
    local focusIndex = -1
    for _, dialogueInfo in ipairs(chatNpcData.allDialogues) do
        local dialogueId = dialogueInfo[1]
        local dialogueChapterId = dialogueInfo[2]
        if not table.ContainsValue(newDialogueIds, dialogueId) then
            local dialogueCfg = ConfigRefer.StoryDialog:Find(dialogueId)
            local dialoguePlace = dialogueCfg:Type()
            local showHead = false
            if dialoguePlace ~= StoryDialogPlaceType.Right and not showNpcHead[dialogueChapterId] then
                showNpcHead[dialogueChapterId] = true
                showHead = true
            elseif dialoguePlace == StoryDialogPlaceType.Right then
                showNpcHead[dialogueChapterId] = false
            end
            local single = {}
            single.chatNpcData = chatNpcData
            single.dialogueId = dialogueId
            single.showHead = showHead
            focusIndex = focusIndex + 1
            if dialoguePlace == StoryDialogPlaceType.Right then
                local height = self:GetHeightRight(I18N.Get(dialogueCfg:DialogKey()))
                self.tableviewproTableChat:AppendDataEx(single,-1,height,3,0,0)
            else
                local height = self:GetHeight(I18N.Get(dialogueCfg:DialogKey()))
                self.tableviewproTableChat:AppendDataEx(single,-1,height,0,0,0)
            end
            hasHistory = true
        end
    end
    if hasHistory and redDotNum > 0 then
        focusIndex = focusIndex + 1
        self.tableviewproTableChat:AppendData({}, 1)
    end
    self.tableviewproTableChat:SetDataFocus(focusIndex, 0, CS.TableViewPro.MoveSpeed.None)
    if redDotNum > 0 then
        self.newDialogueIds = newDialogueIds
        self.isShowingDialogue = true
        self:AcceptChapterByType(chatNpcData)
        local showNewNpcHead = {}
        self:ShowNewDialogues(newDialogueIds, chatNpcData, focusIndex, showNewNpcHead)
    end
    self.goDisconnected:SetActive(chatNpcData.outOfSignal)
end

function QuestEventUIMediator:RecordNewDialogueAnim(dialogueId)
    self.newDialogueIds[dialogueId] = true
end

function QuestEventUIMediator:GetNewDialogueAnim(dialogueId)
    return self.newDialogueIds[dialogueId]
end

function QuestEventUIMediator:ShowNewDialogues(newDialogueIds, chatNpcData, focusIndex, showNewNpcHead)
    self.nextShowDialogue = nil
    if self.delayShowTimer then
        TimerUtility.StopAndRecycle(self.delayShowTimer)
        self.delayShowTimer = nil
    end
    if #newDialogueIds == 0 then
        self.isShowingDialogue = false
        if self.needCustomRefreshRight then
            if self.delayRefreshShowTimer then
                TimerUtility.StopAndRecycle(self.delayRefreshShowTimer)
                self.delayRefreshShowTimer = nil
            end
            if self.outerChatNpcId then
                self.delayRefreshShowTimer = TimerUtility.DelayExecute(function()
                    self.btnBack.gameObject:SetActive(true)
                    self.compChildReddotDefault:SetVisible(true)
                    self.btnPhone.gameObject:SetActive(false)
                    self:RefreshRedDotNum()
                    self:RefreshChapterInfo()
                end, 0.7)
                self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom7)
            else
                self.delayRefreshShowTimer = TimerUtility.DelayExecute(function()
                    self:RefreshRedDotNum()
                    self:RefreshChapterInfo()
                    self.btnPhone.gameObject:SetActive(false)
                end, 0.7)
            end
        end
        self.tableviewproTableChat:SetDataFocus(focusIndex, 0, CS.TableViewPro.MoveSpeed.None)
        return
    end
    if self.showNewDialogueSpace > 0 then
        self.nextShowDialogue = {newDialogueIds[1], chatNpcData, newDialogueIds, focusIndex, showNewNpcHead}
        self.delayShowTimer = TimerUtility.DelayExecute(function()
            self:ShowSingeDialogues(newDialogueIds[1], chatNpcData, newDialogueIds, focusIndex, showNewNpcHead)
        end, self.showNewDialogueSpace)
    else
        self:ShowSingeDialogues(newDialogueIds[1], chatNpcData, newDialogueIds, focusIndex, showNewNpcHead)
    end
end

function QuestEventUIMediator:ShowSingeDialogues(dialogueId, chatNpcData, newDialogueIds, focusIndex, showNewNpcHead)
    local single = {}
    single.chatNpcData = chatNpcData
    single.dialogueId = dialogueId
    focusIndex = focusIndex + 1
    local dialogueCfg = ConfigRefer.StoryDialog:Find(dialogueId)
    local dialoguePlace = dialogueCfg:Type()
    local showNewHead = false
    if dialoguePlace ~= StoryDialogPlaceType.Right and chatNpcData.acceptChapterId and not showNewNpcHead[chatNpcData.acceptChapterId] then
        showNewNpcHead[chatNpcData.acceptChapterId] = true
        showNewHead = true
    elseif dialoguePlace == StoryDialogPlaceType.Right and chatNpcData.acceptChapterId then
        showNewNpcHead[chatNpcData.acceptChapterId] = false
    end
    single.showHead = showNewHead
    single.newAnim = true
    if dialoguePlace == StoryDialogPlaceType.Right then
        local height = self:GetHeightRight(I18N.Get(dialogueCfg:DialogKey()))
        self.tableviewproTableChat:AppendDataEx(single,-1,height,3,0,0)
    else
        local height = self:GetHeight(I18N.Get(dialogueCfg:DialogKey()))
        self.tableviewproTableChat:AppendDataEx(single,-1,height,0,0,0)
    end
    table.removebyvalue(newDialogueIds, dialogueId)
    self.tableviewproTableChat:SetDataFocus(focusIndex, 0, CS.TableViewPro.MoveSpeed.None)
    self:ShowNewDialogues(newDialogueIds, chatNpcData, focusIndex, showNewNpcHead)
end

function QuestEventUIMediator:AcceptChapterByType(chatNpcData)
    if chatNpcData.acceptChapterId and chatNpcData.acceptChapterId > 0 then
        local acceptType
        local targetId
        if chatNpcData.isMainChatNpc then
            acceptType = wrpc.AcceptNpcCitizenTaskType.AcceptNpcCitizenTaskTypeMainTask
            targetId = 0
        elseif chatNpcData.isNpc then
            acceptType = wrpc.AcceptNpcCitizenTaskType.AcceptNpcCitizenTaskTypeNpc
            targetId = chatNpcData.cityElementNpcId
        elseif chatNpcData.citizenId and chatNpcData.citizenId > 0 then
            acceptType = wrpc.AcceptNpcCitizenTaskType.AcceptNpcCitizenTaskTypeCitizen
            targetId = chatNpcData.citizenId
        end
        if acceptType and acceptType > 0 then
            self:AcceptChapter(acceptType, chatNpcData.acceptChapterId, targetId)
        end
    end
end

function QuestEventUIMediator:AcceptChapter(acceptType, newChapterId, targetId)
    self.readyToRefreshTask = true
    local param = AcceptNpcCitizenChapterParameter.new()
    param.args.AcceptType = acceptType
    param.args.MainChapterCfgId = newChapterId
    param.args.TargetId = targetId
    g_Logger.LogChannel('QuestEventUIMediator','AcceptChapter: %d %d %d)', acceptType, newChapterId, targetId)
    param:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            self:AcceptChapterCallBack()
        end
    end)
end

function QuestEventUIMediator:AcceptChapterCallBack()
    g_Game.EventManager:TriggerEvent(EventConst.REFRESH_HUD_NPC_QUEST)
    if self.isShowingDialogue then
        self.needCustomRefreshRight = true
        return
    end
    self:RefreshRedDotNum()
    self:RefreshChapterInfo()
end

function QuestEventUIMediator:OnHide(param)
    if self.delayShowTimer then
        TimerUtility.StopAndRecycle(self.delayShowTimer)
        self.delayShowTimer = nil
    end
    if self.delayRefreshShowTimer then
        TimerUtility.StopAndRecycle(self.delayRefreshShowTimer)
        self.delayRefreshShowTimer = nil
    end
    g_Game.EventManager:TriggerEvent(EventConst.QUEST_SHOW_EXTEND)
    g_Game.EventManager:RemoveListener(EventConst.QUEST_EVENT_CHAT_NPC_CLICKED, Delegate.GetOrCreate(self, self.OnClickChatNpc))
    g_Game.EventManager:RemoveListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.OnTaskChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Chapter.LastFinishedNewChapter.MsgPath,Delegate.GetOrCreate(self,self.OnLastFinishedNewChapterChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Chapter.InProgressNewChapter.MsgPath,Delegate.GetOrCreate(self,self.OnInProgressNewChapterChanged))
end


function QuestEventUIMediator:OnBtnBackClicked(args)
    g_Game.EventManager:TriggerEvent(EventConst.QUEST_EVENT_CLEAR_PLAY)
    self:RefreshNpcDialogeState()
    self:ShowMessageState()
end

function QuestEventUIMediator:GetMaxSelectChapter()
    local curNewChapterId = self.questChapterModule:GetInProgressNewChapterId()
    local lastNewChapterId = self.questChapterModule:GetLastFinishedNewChapterId()
    local maxSelectChapter = curNewChapterId
    if curNewChapterId == 0 then --当前没有正在进行的chapter
        if lastNewChapterId == 0 then --上次完成的章节是0代表现在是第一章
            maxSelectChapter = 1
        elseif lastNewChapterId > 0 then
            maxSelectChapter = ConfigRefer.NewMainChapter:Find(lastNewChapterId):Next()
            if maxSelectChapter == 0 then --代表当前所有的章节都已经完成了
                maxSelectChapter = lastNewChapterId
            end
        end
    end
    return maxSelectChapter
end

function QuestEventUIMediator:RefreshRedDotNum()
    self:RefreshNpcDialogeState()
    self.compChildReddotDefault:SetVisible(self.redDotNum > 0)
    if self.redDotNum > 0 then
        self.compChildReddotDefault:ShowNumRedDot(self.redDotNum)
    end
end

function QuestEventUIMediator:RefreshChapterInfo()
    self.showTasks = {}
    local curNewChapterId = self.questChapterModule:GetInProgressNewChapterId()
    local lastNewChapterId = self.questChapterModule:GetLastFinishedNewChapterId()
    local showChapterCfg = ConfigRefer.NewMainChapter:Find(self.curShowChapter)
    local nextChapterId = showChapterCfg:Next() or 0
    self.btnRight.gameObject:SetActive(true)
    if nextChapterId == 0 then
        self.btnRight.gameObject:SetActive(false)
    elseif curNewChapterId == 0 and lastNewChapterId == 0 then
        self.btnRight.gameObject:SetActive(false)
    elseif curNewChapterId == 0 and lastNewChapterId > 0 then
        local nextChapter = ConfigRefer.NewMainChapter:Find(lastNewChapterId):Next()
        if self.curShowChapter == nextChapter then
            self.btnRight.gameObject:SetActive(false)
        end
    elseif curNewChapterId > 0 then
        if self.curShowChapter == curNewChapterId then
            self.btnRight.gameObject:SetActive(false)
        end
    end
    local lastChapterId = showChapterCfg:Front()
    self.btnLeft.gameObject:SetActive(lastChapterId and lastChapterId > 0)
    if self:ChapterIsLock(self.curShowChapter) then
        self.imgImgHero.gameObject:SetActive(false)
        self.goImgHeroLock:SetActive(true)
      --  self.goClaimed:SetActive(false)
        self.textTask.text = "???"
        self.textTargetNum.text = ""
        self.goStatusEmpty:SetActive(false)
        self.goTableTask:SetActive(false)
        self.goStatusLock:SetActive(true)
        local systemSwitch = showChapterCfg:SystemSwitch()
        local switchCfg = ConfigRefer.SystemEntry:Find(systemSwitch)
        local taskId = switchCfg:UnlockTask()
        self.tableviewproTableNeed:Clear()
        self.tableviewproTableNeed:AppendData({taskId = taskId})
    else
        self.imgImgHero.gameObject:SetActive(true)
        self.goImgHeroLock:SetActive(false)
        local mainChatNpc = showChapterCfg:Chat()
        local chatNpcCfg = ConfigRefer.ChatNPC:Find(mainChatNpc)
        g_Game.SpriteManager:LoadSprite(chatNpcCfg:Icon(), self.imgImgHero)
        if self:ChapterNeedDialogue(self.curShowChapter) then
            self.textTask.text = "???"
            self.textTargetNum.text = ""
            if showChapterCfg:MainTipsLength() >= 1 then
                self.goStatusEmpty:SetActive(true)
                self.textEmpty.text = I18N.GetWithParams(showChapterCfg:MainTips(1), I18N.Get(chatNpcCfg:Name()))
            else
                self.goStatusEmpty:SetActive(false)
            end
            self.goTableTask:SetActive(false)
            self.goStatusLock:SetActive(false)
            --self.goClaimed:SetActive(false)
        else
            --self.goClaimed:SetActive(true)
            self.goStatusEmpty:SetActive(false)
            self.goTableTask:SetActive(true)
            self.goStatusLock:SetActive(false)
            local mainTask = showChapterCfg:MainTask()
            self.textTask.text = ModuleRefer.QuestModule:GetTaskDesc(mainTask)
            self.textTargetNum.text = ModuleRefer.QuestModule:GetTaskParam(mainTask)
            local sortTaskFunc = function(a, b)
                if a.isFinished ~= b.isFinished then
                    return not a.isFinished
                else
                    return a.taskId < b.taskId
                end
            end
            local allChapterTask = {}
            for i = 1, showChapterCfg:NPCParamsLength() do
                local npcParam = showChapterCfg:NPCParams(i)
                local chatNpcId = npcParam:Chat()
                local priority = npcParam:Priority()
                local tasks = {}
                local allFinished = true
                for j = 1, npcParam:TasksLength() do
                    local taskId = npcParam:Tasks(j)
                    local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
                    if state >= wds.TaskState.TaskStateReceived then
                        if state == wds.TaskState.TaskStateReceived then
                            allFinished = false
                            --self.goClaimed:SetActive(false)
                        end
                        local isFinished = state == wds.TaskState.TaskStateFinished
                        tasks[#tasks + 1] = {isFinished = isFinished, taskId = taskId, cityElementNpcId = npcParam:NPC(), isNpc = true, rewards = npcParam:Rewards(), title = npcParam:Title()}
                    end
                end
                table.sort(tasks, sortTaskFunc)
                allChapterTask[#allChapterTask + 1] = {allFinished = allFinished, chatNpcId = chatNpcId, priority = priority, tasks = tasks}
            end
            for i = 1, showChapterCfg:CitizenParamsLength() do
                local citizenParam = showChapterCfg:CitizenParams(i)
                local chatNpcId = citizenParam:Chat()
                local priority = citizenParam:Priority()
                local tasks = {}
                local allFinished = true
                for j = 1, citizenParam:TasksLength() do
                    local taskId = citizenParam:Tasks(j)
                    local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
                    if state >= wds.TaskState.TaskStateReceived then
                        if state == wds.TaskState.TaskStateReceived then
                            allFinished = false
                            --self.goClaimed:SetActive(false)
                        end
                        local isFinished = state == wds.TaskState.TaskStateFinished
                        tasks[#tasks + 1] = {isFinished = isFinished, taskId = taskId, citizenId = citizenParam:Citizens(), rewards = citizenParam:Rewards(), title = citizenParam:Title()}
                    end
                end
                table.sort(tasks, sortTaskFunc)
                allChapterTask[#allChapterTask + 1] = {allFinished = allFinished, chatNpcId = chatNpcId, priority = priority, tasks = tasks}
            end
            local sortChatNpcFunc = function(a, b)
                if a.allFinished ~= b.allFinished then
                    return not a.allFinished
                else
                    if a.priority ~= b.priority then
                        return a.priority < b.priority
                    else
                        return a.chatNpcId < b.chatNpcId
                    end
                end
            end
            table.sort(allChapterTask, sortChatNpcFunc)
            local showNpcHead = {}
            self.tableviewproTableTask:Clear()
            local hasTask = false
            local focusIndex = -1
            self.recordTasks = self.recordTasks or {}
            for _, v in ipairs(allChapterTask) do
                local chatNpcId = v.chatNpcId
                for _, task in ipairs(v.tasks) do
                    hasTask = true
                    local showHead = false
                    if not showNpcHead[chatNpcId] then
                        showNpcHead[chatNpcId] = true
                        showHead = true
                        local single = {}
                        single.isFinished = task.isFinished
                        single.taskId = task.taskId

                        single.chatNpcId = chatNpcId
                        single.allFinished = v.allFinished
                        single.isNpc = task.isNpc
                        if task.isNpc then
                            single.cityElementNpcId = task.cityElementNpcId
                        else
                             single.citizenId = task.citizenId
                        end
                        single.title = task.title
                        single.showHead = showHead
                        single.rewards = task.rewards
                        if self.readyToRefreshTask and not self.recordTasks[task.taskId] then
                            single.isNew = true
                        end
                        if task.rewards and task.rewards > 0 then
                            focusIndex = focusIndex + 1
                            self.tableviewproTableTask:AppendData(single,1)
                        end
                    end
                    local single1 = {}
                    single1.isFinished = task.isFinished
                    single1.taskId = task.taskId

                    single1.chatNpcId = chatNpcId
                    single1.allFinished = v.allFinished
                    single1.isNpc = task.isNpc
                    if task.isNpc then
                        single1.cityElementNpcId = task.cityElementNpcId
                    else
                        single1.citizenId = task.citizenId
                    end
                    if self.readyToRefreshTask and not self.recordTasks[task.taskId] then
                        single1.isNew = true
                    end
                    single1.showHead = showHead
                    focusIndex = focusIndex + 1
                    self.tableviewproTableTask:AppendData(single1,0)
                    self.showTasks[#self.showTasks + 1] = single1.taskId
                    self.recordTasks[task.taskId] = true
                    if single1.isNew then
                        self.tableviewproTableTask:SetDataFocus(focusIndex, 0, CS.TableViewPro.MoveSpeed.None)
                    end
                end
            end
            self.readyToRefreshTask = false
            if not hasTask then
                --self.goClaimed:SetActive(false)
                self.goStatusEmpty:SetActive(true)
                self.goTableTask:SetActive(false)
                self.textTargetNum.text = ""
                local npcString = string.Empty
                for index, v in ipairs(allChapterTask) do
                    local chatNpcId = v.chatNpcId
                    local cfg = ConfigRefer.ChatNPC:Find(chatNpcId)
                    if index < #allChapterTask then
                        npcString = npcString .. I18N.Get(cfg:Name()) .. "、"
                    else
                        npcString = npcString .. I18N.Get(cfg:Name())
                    end
                end
                if not string.IsNullOrEmpty(npcString) then
                    self.textEmpty.text = I18N.GetWithParams("new_chapter_task_tips_common", npcString)
                end
            end
        end
    end
end

function QuestEventUIMediator:ChapterIsLock(chapterId)
    local chapterCfg = ConfigRefer.NewMainChapter:Find(chapterId)
    local systemSwitch = chapterCfg:SystemSwitch()
    local isLock = false
    if systemSwitch and systemSwitch > 0 then
        isLock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemSwitch)
    end
    return isLock
end

function QuestEventUIMediator:ChapterNeedDialogue(chapterId)
    local curNewChapterId = self.questChapterModule:GetInProgressNewChapterId()
    local lastNewChapterId = self.questChapterModule:GetLastFinishedNewChapterId()
    return curNewChapterId == 0 and ((lastNewChapterId > 0 and chapterId == ConfigRefer.NewMainChapter:Find(lastNewChapterId):Next()) or (lastNewChapterId == 0 and chapterId == 1))
end

function QuestEventUIMediator:OnBtnLeftClicked(args)
    local lastChapterId = ConfigRefer.NewMainChapter:Find(self.curShowChapter):Front()
    self.curShowChapter = lastChapterId
    self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
        self:RefreshChapterInfo()
        self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    end)
end

function QuestEventUIMediator:OnBtnRightClicked(args)
    local nextChapterId = ConfigRefer.NewMainChapter:Find(self.curShowChapter):Next()
    self.curShowChapter = nextChapterId
    self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3, function()
        self:RefreshChapterInfo()
        self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4)
    end)
end

function QuestEventUIMediator:OnTaskChanged(params)
    local isNeedRefresh = false
	if params then
        if self.showTasks then
            for _, taskId in ipairs(self.showTasks) do
                if table.ContainsValue(params, taskId) then
                    isNeedRefresh = true
                    break
                end
            end
        end
	end
    if isNeedRefresh then
        if self.isShowingDialogue then
            self.needCustomRefreshRight = true
            return
        end
        self:RefreshChapterInfo()
    end
end

function QuestEventUIMediator:OnLastFinishedNewChapterChanged()
    if self.isShowingDialogue then
        self.needCustomRefreshRight = true
        return
    end
    self:RefreshChapterInfo()
end

function QuestEventUIMediator:OnInProgressNewChapterChanged()
    if self.isShowingDialogue then
        self.needCustomRefreshRight = true
        return
    end
    self:RefreshChapterInfo()
end

function QuestEventUIMediator:OnCloseWin()
    self:BackToPrevious()
end

return QuestEventUIMediator