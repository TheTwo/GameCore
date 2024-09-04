local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local CitizenBTDefine = require("CitizenBTDefine")
local Utils = require("Utils")
local City3DBubbleStandard = require("City3DBubbleStandard")
local EventConst = require("EventConst")
local AudioConsts = require("AudioConsts")

local CitizenBubbleState = require("CitizenBubbleState")

---@class CitizenBubbleStateTask:CitizenBubbleState
---@field new fun():CitizenBubbleStateTask
---@field super CitizenBubbleState
local CitizenBubbleStateTask = class('CitizenBubbleStateTask', CitizenBubbleState)

function CitizenBubbleStateTask:Enter()
    g_Game.EventManager:RemoveListener(EventConst.STROY_FINISHE_LOG_SERVER_INFO_CHANGED, Delegate.GetOrCreate(self, self.Setup))
    g_Game.EventManager:AddListener(EventConst.STROY_FINISHE_LOG_SERVER_INFO_CHANGED, Delegate.GetOrCreate(self, self.Setup))
    self._bubble = self._bubbleMgr:QueryBubble(2)
    self:Setup()
end

function CitizenBubbleStateTask:Setup()
    if not self._host._citizenTaskInitStoryId or self._host._citizenTaskInitStoryId == 0 or ModuleRefer.StoryModule:IsPlayerStoryTaskFinished(self._host._citizenTaskInitStoryId) then
        self._host._forceClear = true
        self._host._delayCheckTask = true
        self._host._delayCheckService = true
        return
    end
    if self._bubble then
        self._bubble._attachTrans = self._citizen.model:Transform()
        self._bubble:SetActive(true)
        self._bubble:Reset()
        local bubbleIcon = "sp_city_icon_chat"
        local triggerStory = self._host._citizenTaskInitStoryId
        local triggerAni = nil
        local iconBg = City3DBubbleStandard.GetDefaultNormalBg()
        if triggerStory and triggerStory ~= 0 then
            if not ModuleRefer.StoryModule:IsPlayerStoryTaskFinished(triggerStory) then
                bubbleIcon = "sp_hud_icon_taskstip"
                triggerAni = 2
            end
        end
        ---@type CityCitizenBubbleTipTaskContext
        local context = {}
        context.icon = bubbleIcon
        context.bg = iconBg
        context.callback = Delegate.GetOrCreate(self, self.OnClickIcon)
        context.triggerAni = triggerAni
        self._bubble:SetupTask(context)
    end
end

function CitizenBubbleStateTask:Exit()
    g_Game.EventManager:RemoveListener(EventConst.STROY_FINISHE_LOG_SERVER_INFO_CHANGED, Delegate.GetOrCreate(self, self.Setup))
    CitizenBubbleStateTask.super.Exit(self)
end

function CitizenBubbleStateTask:OnClickIcon()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    self:OnClickTask()
end

function CitizenBubbleStateTask:OnClickTask()
    local citizenId = self._citizen._data._id
    local triggerStory = self._host._citizenTaskInitStoryId
    if triggerStory and triggerStory ~= 0 then
        self._citizenMgr:WriteGlobalContext(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId, citizenId)
        ModuleRefer.StoryModule:StoryStart(triggerStory, function(storyId, result)
            self:ContinueOnStoryEnd(citizenId)
        end)
    else
        self._citizenMgr:WriteGlobalContext(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId, citizenId)
        self:ContinueOnStoryEnd(citizenId)
    end
end

function CitizenBubbleStateTask:ContinueOnStoryEnd(citizenId)
    if not ModuleRefer.QuestModule.Chapter:OpenCitizenTaskCircleMenu(citizenId, function()
        self._citizenMgr:WriteGlobalContext(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId, nil)
    end) then
        self._citizenMgr:WriteGlobalContext(CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId, nil)
    end
end

function CitizenBubbleStateTask:GetCurrentBubbleTrans()
    if not self._bubble then return nil end
    local tipHandle = self._bubble
    if not tipHandle or not tipHandle._tip then return nil end
    if Utils.IsNull(tipHandle._tip.p_bubble_npc_trigger) then return nil end
    return tipHandle._tip.p_bubble_npc_trigger.transform
end

return CitizenBubbleStateTask