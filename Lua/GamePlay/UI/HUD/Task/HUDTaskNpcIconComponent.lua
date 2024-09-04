local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local GuideUtils = require('GuideUtils')
local Utils = require("Utils")
local NpcServiceObjectType = require("NpcServiceObjectType")
local CitizenBTDefine = require("CitizenBTDefine")
local CityTileAssetNpcBubbleCommon = require("CityTileAssetNpcBubbleCommon")

local HUDTaskNpcIconComponent = class("HUDTaskNpcIconComponent",BaseUIComponent)

function HUDTaskNpcIconComponent:OnCreate(param)
    self.btnNpc1 = self:Button('', Delegate.GetOrCreate(self, self.OnBtnNpc1Clicked))
    self.goMissionFinish = self:GameObject('p_mission_finish')
    self.textMissionFinish = self:Text('p_text_mission_finish')
    self.imgImgHero = self:Image('p_img_hero')
    self.goStatusA = self:GameObject('p_status_a')
    self.textMission = self:Text('p_text_mission')
    self.goStatusB = self:GameObject('p_status_b')
    self.goFinger = self:GameObject('child_common_fingerguide')
    self.btnMissionButton = self:Button('p_mission_button', Delegate.GetOrCreate(self, self.OnBtnMissionButtonClicked))
    self.goStatusB:SetActive(false)
end

function HUDTaskNpcIconComponent:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.RefreshState))
end

function HUDTaskNpcIconComponent:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self,self.RefreshState))
end

function HUDTaskNpcIconComponent:ChangeFingerState(isSHow)
    if Utils.IsNotNull(self.goFinger) then
        self.goFinger:SetActive(isSHow and self.goStatusA.activeSelf and self.btnMissionButton.gameObject.activeSelf and not ModuleRefer.GuideModule:GetGuideState())
    end
end

function HUDTaskNpcIconComponent:RefreshState(changeTasks)
    if not self.chatNpcInfo then
        return
    end
    if not self.chatNpcInfo.taskId then
        return
    end
    local finishedTaskId
    local showTasks = {}
    local id
    local finishedTasks = {}
    if self.chatNpcInfo.isNpc and self.chatNpcInfo.cityElementNpcId then
        showTasks, id, finishedTasks = ModuleRefer.QuestModule.Chapter:GetCityElementNpcShowTasks(self.chatNpcInfo.cityElementNpcId)
    elseif self.chatNpcInfo.citizenId then
        showTasks, id, finishedTasks = ModuleRefer.QuestModule.Chapter:GetCitizenShowTasks(self.chatNpcInfo.citizenId)
    end
    local isAllFinish = #showTasks == 0
    for _, finishedTask in ipairs(finishedTasks) do
        if table.ContainsValue(changeTasks, finishedTask.taskId) then
            finishedTaskId = finishedTask.taskId
        end
    end
    if finishedTaskId then
        ModuleRefer.QuestModule.Chapter:SetHudQuestAnimState(true)
        ModuleRefer.QuestModule.Chapter:ForceRefreshAnimState()
        self.goMissionFinish:SetActive(true)
        self.textMissionFinish.text = ModuleRefer.QuestModule:GetTaskDescWithProgress(finishedTaskId)
        self.goStatusA:SetActive(false)
        self.goStatusB:SetActive(true)
        self.textMission.text = ""
        local callback = function()
            ModuleRefer.QuestModule.Chapter:SetHudQuestAnimState(false)
            g_Game.EventManager:TriggerEvent(EventConst.REFRESH_HUD_NPC_QUEST)
        end
        if self.index == 1 then
            self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2, function()
                if isAllFinish then
                    self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3, function() callback() end)
                else
                    callback()
                end
            end)
        elseif self.index == 2 then
            self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4, function()
                if isAllFinish then
                    self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5, function() callback() end)
                else
                    callback()
                end
            end)
        elseif self.index == 3 then
            self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom6, function()
                if isAllFinish then
                    self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom7, function() callback() end)
                else
                    callback()
                end
            end)
        end
    end
end

---@param chatNpcInfo Chapter_task_cache
function HUDTaskNpcIconComponent:UpdateNpcInfo(chatNpcInfo, index, animationTrigger)
    if not chatNpcInfo then
        return
    end
    self.index = index
    self.animationTrigger = animationTrigger
    self.chatNpcInfo = chatNpcInfo
    self.goMissionFinish:SetActive(false)
    self.goStatusA:SetActive(not chatNpcInfo.isAllFinish)
    self.goStatusB:SetActive(chatNpcInfo.isAllFinish)
    g_Logger.LogChannel('HUDNewTaskComponent', chatNpcInfo.isAllFinish)
    local chatId = chatNpcInfo.chatNpcId
    if chatId then
        g_Game.SpriteManager:LoadSprite(ConfigRefer.ChatNPC:Find(chatId):Icon(), self.imgImgHero)
    end
    if chatNpcInfo.isAllFinish then
        if self.index == 1 then
            self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
        elseif self.index == 2 then
            self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
        elseif self.index == 3 then
            self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom7)
        end
    end
    self.chatId = chatId
    self:RefreshTaskShow()
end

function HUDTaskNpcIconComponent:RefreshTaskShow()
    if ModuleRefer.QuestModule.Chapter:GetHudQuestAnimState() then
        return
    end
    local sortfunc = function(a, b)
        return a < b
    end
    if self.chatNpcInfo.isNpc and self.chatNpcInfo.cityElementNpcId then
        local isShowTask =  ModuleRefer.QuestModule.Chapter:CheckIsReadCityElementNpcInitialStory(self.chatNpcInfo.cityElementNpcId)
        self.btnMissionButton.gameObject:SetActive(isShowTask)
        if isShowTask then
            local showTasks, _ = ModuleRefer.QuestModule.Chapter:GetCityElementNpcShowTasks(self.chatNpcInfo.cityElementNpcId)
            table.sort(showTasks, sortfunc)
            local firstTask = showTasks[1]
            if firstTask and firstTask > 0 then
                self.clickTaskId = firstTask
                local taskDesc = ModuleRefer.QuestModule:GetTaskDesc(firstTask)
                self.textMission.text = taskDesc
                self.goStatusB:SetActive(false)
            else
                self.textMission.text = ""
            end
        else
            self.textMission.text = ""
        end

    elseif self.chatNpcInfo.citizenId then
        local isShowTask =  ModuleRefer.QuestModule.Chapter:CheckIsReadCitizenInitialStory(self.chatNpcInfo.citizenId)
        self.btnMissionButton.gameObject:SetActive(isShowTask)
        if isShowTask then
            local showTasks, _ = ModuleRefer.QuestModule.Chapter:GetCitizenShowTasks(self.chatNpcInfo.citizenId)
            table.sort(showTasks, sortfunc)
            local firstTask = showTasks[1]
            if firstTask and firstTask > 0 then
                self.clickTaskId = firstTask
                local taskDesc = ModuleRefer.QuestModule:GetTaskDesc(firstTask)
                self.textMission.text = taskDesc
                self.goStatusB:SetActive(false)
            else
                self.textMission.text = ""
            end
        else
            self.textMission.text = ""
        end
    end
end

function HUDTaskNpcIconComponent:OnBtnMissionButtonClicked(args)
    if self.clickTaskId and self.clickTaskId > 0 then
        local gotoId = ModuleRefer.QuestModule:GetTaskGotoID(self.clickTaskId)
        GuideUtils.GotoByGuide(gotoId, true)
    end
end

function HUDTaskNpcIconComponent:OnBtnNpc1Clicked(args)
    if not self.chatNpcInfo then
        return
    end
    ---@type KingdomScene
    local currentScene = g_Game.SceneManager.current
    if not currentScene or currentScene:GetName() ~= "KingdomScene" then
        return
    end
    if not currentScene:IsInMyCity() then
        g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY)
        return
    end
    if self.chatNpcInfo.isNpc and self.chatNpcInfo.cityElementNpcId then
        local autoClick = ModuleRefer.QuestModule.Chapter:CheckIsShowCityElementNpcHeadIcon(self.chatNpcInfo.cityElementNpcId)
        if not autoClick then
            local city = ModuleRefer.CityModule.myCity
            if city and city.cityExplorerManager then
                local elementId = city.cityExplorerManager._cacheNpcIdSet[self.chatNpcInfo.cityElementNpcId]
                if elementId then
                    ModuleRefer.PlayerServiceModule:InteractWithTarget(NpcServiceObjectType.CityElement, elementId, true)
                end
            end
        else
            local npcConfig = ConfigRefer.CityElementNpc:Find(self.chatNpcInfo.cityElementNpcId)
            if npcConfig:InitStoryTaskId() ~= 0 and not ModuleRefer.StoryModule:IsPlayerStoryTaskFinished(npcConfig:InitStoryTaskId()) then
                ModuleRefer.PlayerServiceModule:FocusOnObjectBubble(NpcServiceObjectType.CityElement, self.chatNpcInfo.cityElementNpcId, nil, true)
            else
                local city = ModuleRefer.CityModule:GetMyCity()
                local explorerMgr = city.cityExplorerManager
                local elementId = explorerMgr:GetCityElementIdByNpcId(self.chatNpcInfo.cityElementNpcId)
                if not elementId or elementId == 0 then
                    g_Logger.Error("cityElementNpcId:%s 找不到对应的elemt", self.chatNpcInfo.cityElementNpcId)
                    return
                end
                ModuleRefer.PlayerServiceModule:FocusOnObjectBubble(NpcServiceObjectType.CityElement, self.chatNpcInfo.cityElementNpcId, function(isSuccess, bubbleTrans)
                    local clickNpcInfo = CityTileAssetNpcBubbleCommon.MakeClickNpcMsgContext(city, elementId)
                    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, clickNpcInfo)
                end)
            end
        end
    elseif self.chatNpcInfo.citizenId then
        local autoClick,initStoryId = ModuleRefer.QuestModule.Chapter:CheckIsShowCitizenHeadIcon(self.chatNpcInfo.citizenId)
        if not autoClick then
            ModuleRefer.PlayerServiceModule:InteractWithTarget(NpcServiceObjectType.Citizen, self.chatNpcInfo.citizenId, true)
        else
            if initStoryId and initStoryId ~= 0 and not ModuleRefer.StoryModule:IsPlayerStoryTaskFinished(initStoryId) then
                ModuleRefer.PlayerServiceModule:FocusOnObjectBubble(NpcServiceObjectType.Citizen, self.chatNpcInfo.citizenId, nil, true)
            else
                local citizenId = self.chatNpcInfo.citizenId
                local citizenMgr = ModuleRefer.CityModule:GetMyCity().cityCitizenManager
                ModuleRefer.PlayerServiceModule:FocusOnObjectBubble(NpcServiceObjectType.Citizen, citizenId, function(isSuccess, bubbleTrans)
                    if isSuccess then
                        citizenMgr:WriteGlobalContext(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId, citizenId)
                        if not ModuleRefer.QuestModule.Chapter:OpenCitizenTaskCircleMenu(citizenId, function()
                            citizenMgr:WriteGlobalContext(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId, nil)
                        end) then
                            citizenMgr:WriteGlobalContext(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId, nil)
                        end
                    end
                end)
            end
        end
    end
end

return HUDTaskNpcIconComponent