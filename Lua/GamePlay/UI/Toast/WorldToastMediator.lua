local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local AudioConsts = require('AudioConsts')
local DBEntityPath = require('DBEntityPath')
local EventConst = require('EventConst')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local KingdomMapUtils = require("KingdomMapUtils")
local HUDConst = require('HUDConst')
local TouchMenuBasicInfoDatum = require("TouchMenuBasicInfoDatum")
local TouchMenuCellTextDatum = require("TouchMenuCellTextDatum")
local ProgressType = require("ProgressType")
local PlayType = require("PlayType")
local DBEntityType = require("DBEntityType")
local TimerUtility = require("TimerUtility")

---@class WorldToastMediator : BaseUIMediator
---@field eventCfg WorldExpeditionTemplateConfigCell
local WorldToastMediator = class('WorldToastMediator', BaseUIMediator)

local SHOW_TYPE = {
    Normal = 1,
    Shortly = 2,
}

function WorldToastMediator:OnCreate()
    self.root = self:GameObject('content')
    self.goBaseFinish = self:GameObject('p_base_finish')
    self.textContent = self:Text('p_text_content')
    self.textProgress = self:Text('p_text_progress')
    self.textLv = self:Text("p_text_lv")
    self.goTime = self:GameObject('p_time')
    self.goIcon = self:GameObject('p_icon')
    self.aniTrigger = self:AnimTrigger('vx_trigger')
    self.timeComp = self:LuaBaseComponent('child_time')
    self.sliderProgress = self:BindComponent("p_progress", typeof(CS.UnityEngine.UI.Slider))
    self.btnDetail = self:Button("p_btn_story", Delegate.GetOrCreate(self, self.OnDetailClicked))
    self.imgEventIcon = self:Image("p_event_icon")
    self.textFinish = self:Text('p_text_finish', I18N.Get("world_sj_wc"))

    self.imgFrame = self:Image('p_img_frame')
    self.textPersonalProgress = self:Text('p_text_progress_player')
    self.goFailed = self:GameObject('p_base_falied')
    self.textFaild = self:Text('p_text_falied', I18N.Get("Worldexpedition_event_failed"))

    --预告阶段
    self.goNotice = self:GameObject('p_event_icon_foreshow')
    self.goLv = self:GameObject('p_lv')
    self.textTimeOpen = self:Text('p_text_open', I18N.Get("relocate_info_open_after"))

    self.btnMask = self:Button("mask", Delegate.GetOrCreate(self, self.OnMaskClicked))

    self.qualityIconName = {"sp_world_base_1", "sp_world_base_2", "sp_world_base_3", "sp_world_base_4"}
end

function WorldToastMediator:OnOpened(param)
    if not param.expeditionInfo then
        return
    end
    self.expeditionInfo = param.expeditionInfo
    self.posX = param.x
    self.posY = param.y
    self.entityId = param.entityId
    self.state = wds.ExpeditionState.ExpeditionNotice
    self.showType = SHOW_TYPE.Normal
    self:Refresh()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Expedition.MsgPath, Delegate.GetOrCreate(self, self.Refresh))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Expedition.ExpeditionInfo.ExpeditionVanishInfo.MsgPath, Delegate.GetOrCreate(self, self.ShowFailReason))
    g_Game.EventManager:AddListener(EventConst.HUD_STATE_CHANGED,Delegate.GetOrCreate(self,self.OnCityStateChanged))
    g_Game.EventManager:AddListener(EventConst.CHANG_SEARCH_PANEL_STATE,Delegate.GetOrCreate(self,self.OnSearchPanelChanged))
    g_Game.EventManager:AddListener(EventConst.CHANG_TOAST_SHOW_TYPE,Delegate.GetOrCreate(self,self.OnToastShowTypeChanged))
    -- g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_TOAST_OPEN)
end

function WorldToastMediator:OnShow(param)
    if param and param.expeditionInfo then
        self.expeditionInfo = param.expeditionInfo
        self:Refresh()
    end
    g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_TOAST_OPEN)
end

function WorldToastMediator:Refresh(entity, changeTable)
    if self.expeditionInfo.State == wds.ExpeditionState.ExpeditionNotice then
        self:RefreshNotice()
    elseif self.expeditionInfo.State == wds.ExpeditionState.ExpeditionActive or 
    self.expeditionInfo.State == wds.ExpeditionState.ExpeditionUnActive then
        self:RefreshActive()
    end
end

function WorldToastMediator:RefreshActive()
    -- if self.state == wds.ExpeditionState.ExpeditionNotice then
    --     --状态切换
    --     self.state = wds.ExpeditionState.ExpeditionActive
    --     g_Game.TriggerEvent(EventConst.WORLD_EVENT_PRE_NOTICE_STATE_END)
    -- end
    self:SetNoticeUIShow(false)
    self.eventCfg =  ConfigRefer.WorldExpeditionTemplate:Find(self.expeditionInfo.Tid)
    self.textLv.text = self.eventCfg:Level()
    self.progress = 0
    local percent = 0
    --boss事件进度特殊处理
    if self.eventCfg:PlayType() == PlayType.Boss then
        self:StopTimer()
        local bossID = self.expeditionInfo.ProgressRelatedEntityId
        self.bossEntity = g_Game.DatabaseManager:GetEntity(bossID, DBEntityType.MapMob)
        if self.bossEntity then
            percent = math.clamp(1 - self.bossEntity.Battle.Hp / self.bossEntity.Battle.MaxHp, 0, 1)
            local personalProgress = self.expeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
            local damageProgressUnit = self.eventCfg:DamageProgressUnit():Value1() or 100
            local personalPercent = math.clamp(personalProgress * damageProgressUnit / self.bossEntity.Battle.MaxHp, 0, 1)
            self.textPersonalProgress.gameObject:SetActive(true)
            self.textProgress.text = string.format('%s<b>%d</b>',I18N.Get("Worldexpedition_my_progress"), personalProgress)
            self.textPersonalProgress.text = math.floor(percent * 100) .. "%"
            self.progress = percent * 100
            self.personalProgress = personalProgress
            if percent < 1 then
                self.timer = TimerUtility.IntervalRepeat(function()
                    self:TickProgress()
                end, 0.2, -1)
            end
        end
    else
        local personalProgress = self.expeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
        self.personalProgress = personalProgress
        if self.eventCfg:ProgressType() == ProgressType.Whole then
            local personalPercent = math.clamp(personalProgress / self.eventCfg:MaxProgress(), 0, 1)
            self.textPersonalProgress.gameObject:SetActive(true)
            self.progress = self.expeditionInfo.Progress
            percent = math.clamp(self.progress / self.eventCfg:MaxProgress(), 0, 1)
            self.textPersonalProgress.text = math.floor(percent * 100) .. "%"
            self.textProgress.text = string.format('%s<b>%d</b>',I18N.Get("Worldexpedition_my_progress"), personalProgress)
        elseif self.eventCfg:ProgressType() == ProgressType.Personal then
            self.progress = personalProgress
            percent = math.clamp(self.progress / self.eventCfg:MaxProgress(), 0, 1)
            self.textPersonalProgress.text = math.floor(percent * 100) .. "%"
            self.textProgress.gameObject:SetActive(false)
        end
    end
    self.sliderProgress.value = percent
    self.isFinish = percent >= 1
    if self.isFinish then
        g_Game.SoundManager:PlayAudio(AudioConsts.sfx_worldtask_finish)
        self:ShowSuccessAnim()
    end
    -- self.goBaseFinish:SetActive(self.isFinish)
    self.textContent.text = I18N.Get(self.eventCfg:Name())
    if self.isFinish then
        self.textContent.text = self.textContent.text .. I18N.Get("worldevent_wancheng")
    end
    local finishTime = self.expeditionInfo.ActivateEndTime
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local isShowTime = finishTime and finishTime > curTime
    self.goTime:SetActive(isShowTime)
    local callBack = function()
        self:CheckIsFail()
    end
    if isShowTime then
        local color = CS.UnityEngine.Color(1.0, 63/255, 43/255, 1.0)
        self.timeComp:FeedData({endTime = finishTime, needTimer = true, callBack = callBack,
        deadline = 600, deadlineColor = color})
    end
    if not string.IsNullOrEmpty(self.eventCfg:WorldTaskIcon()) then
        g_Game.SpriteManager:LoadSprite(self.eventCfg:WorldTaskIcon(), self.imgEventIcon)
    end
    local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    self.quality = (radarInfo.ExpeditionQuality[self.expeditionInfo.ID] or {}).QualityType or 0
    if self.quality < #self.qualityIconName then
        g_Game.SpriteManager:LoadSprite(self.qualityIconName[self.quality + 1], self.imgFrame)
    end
end

function WorldToastMediator:RefreshNotice()
    self.state = wds.ExpeditionState.ExpeditionActive
    self.textTimeOpen.gameObject:SetActive(false)
    self.eventCfg =  ConfigRefer.WorldExpeditionTemplate:Find(self.expeditionInfo.Tid)
    if not self.eventCfg then
        return
    end
    self.textContent.text = I18N.Get(self.eventCfg:Name())

    self.sliderProgress.value = 0
    self:SetNoticeUIShow(true)
    local finishTime = self.expeditionInfo.ActivateEndTime
    self.timeComp:FeedData({endTime = finishTime, needTimer = true, textFormat = "WorldExpedition_info_Open_after"})
end

function WorldToastMediator:SetNoticeUIShow(isShow)
    self.imgFrame.gameObject:SetActive(not isShow)
    self.imgEventIcon.gameObject:SetActive(not isShow)
    self.goNotice:SetActive(isShow)

    self.goLv:SetActive(not isShow)
    self.textProgress.gameObject:SetActive(not isShow)
end

function WorldToastMediator:CheckIsFail()
    if not self.isFinish then
        local finishTime = self.expeditionInfo.ActivateEndTime
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        if finishTime and finishTime > curTime then
            self:BackToPrevious()
        else
            self:ShowFailAnim(1)
        end
    else
        self:BackToPrevious()
    end
end

function WorldToastMediator:OnClose(param)
    self:StopTimer()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Expedition.MsgPath, Delegate.GetOrCreate(self, self.Refresh))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Expedition.ExpeditionInfo.ExpeditionVanishInfo.MsgPath, Delegate.GetOrCreate(self, self.ShowFailReason))
    g_Game.EventManager:RemoveListener(EventConst.HUD_STATE_CHANGED,Delegate.GetOrCreate(self,self.OnCityStateChanged))
    g_Game.EventManager:RemoveListener(EventConst.CHANG_SEARCH_PANEL_STATE,Delegate.GetOrCreate(self,self.OnSearchPanelChanged))
    g_Game.EventManager:RemoveListener(EventConst.CHANG_TOAST_SHOW_TYPE,Delegate.GetOrCreate(self,self.OnToastShowTypeChanged))
end

function WorldToastMediator:OnCityStateChanged(hudState)
    if hudState == HUDConst.HUD_STATE.CITY then
        ---@type KingdomScene
        local _scene = g_Game.SceneManager.current
        if _scene:GetName() == require('KingdomScene').Name then
            if _scene:IsInCity() then
                -- self:BackToPrevious()
                self:CloseSelf()
            end
        end
    end
end

function WorldToastMediator:OnSearchPanelChanged(isShow)
    self.root:SetActive(not isShow)
end

function WorldToastMediator:OnToastShowTypeChanged(type)
    if type == self.showType then
        return
    end
    self.showType = type
    self:ChangeShowType()
end

function WorldToastMediator:ChangeShowType()
    if self.showType == SHOW_TYPE.Normal then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom5)
    elseif self.showType == SHOW_TYPE.Shortly then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom4)
    end
end

function WorldToastMediator:OnDetailClicked()
    ---@type WorldEventDetailMediatorParameter
    local param = {}
    param.clickTransform =  self.btnDetail.transform
    param.touchMenuBasicInfoDatum = TouchMenuBasicInfoDatum.new(I18N.Get(self.eventCfg:Name()), "", "",self.eventCfg:Level())
    param.touchMenuCellTextDatum = TouchMenuCellTextDatum.new(I18N.Get(self.eventCfg:Des()), true)
    param.tid = self.expeditionInfo.Tid
    param.x = self.posX
    param.y = self.posY
    param.progress = self.progress
    if self.personalProgress then
        param.personalProgress = self.personalProgress
    end
    param.quality = self.quality
    param.openType = 1

    self._infoToastUI = ModuleRefer.ToastModule:ShowWorldEventDetail(param)
end

function WorldToastMediator:ShowFailReason(entity, changeTable)
    if not changeTable.VanishRea then
        return
    end
    if self.eventCfg:PlayType() == PlayType.PersonalChallenge and 
    changeTable.VanishRea == wds.ExpeditionVanishRea.ExpeditionVanishRea_Failed then
        self:ShowFailAnim(2)
    end
end

function WorldToastMediator:TickProgress()
    if self.bossEntity and self.eventCfg:PlayType() == PlayType.Boss then
        local percent = math.clamp(1 - self.bossEntity.Battle.Hp / self.bossEntity.Battle.MaxHp, 0, 1)
        local personalProgress = self.expeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
        local damageProgressUnit = self.eventCfg:DamageProgressUnit():Value1() or 100
        local personalPercent = math.clamp(personalProgress * damageProgressUnit / self.bossEntity.Battle.MaxHp, 0, 1)
        self.textPersonalProgress.gameObject:SetActive(true)
        self.textProgress.text = string.format('%s<b>%d</b>',I18N.Get("Worldexpedition_my_progress"), personalProgress)
        self.textPersonalProgress.text = math.floor(percent * 100) .. "%"
        self.progress = percent * 100
        self.personalProgress = personalProgress
        self.sliderProgress.value = percent
    end
end

function WorldToastMediator:StopTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function WorldToastMediator:ShowFailAnim(type)
    if self.showType == SHOW_TYPE.Normal then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom2, Delegate.GetOrCreate(self, self.BackToPrevious))
    elseif self.showType == SHOW_TYPE.Shortly then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom8, Delegate.GetOrCreate(self, self.BackToPrevious))
    end
    if type == 1 then
        ModuleRefer.ToastModule:AddTopToast({content = I18N.GetWithParams("WorldExpedition_taost_failed_rason", I18N.Get("WorldExpedition_info_Not_enough_time"), I18N.Get(self.eventCfg:Name()))})
    else
        ModuleRefer.ToastModule:AddTopToast({content = I18N.Get("WorldExpedition_taost_Youth_dies")})
    end
end

function WorldToastMediator:ShowSuccessAnim()
    if self.showType == SHOW_TYPE.Normal then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom1, Delegate.GetOrCreate(self, self.BackToPrevious))
    elseif self.showType == SHOW_TYPE.Shortly then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom7, Delegate.GetOrCreate(self, self.BackToPrevious))
    end
    ModuleRefer.ToastModule:AddTopToast({content = I18N.GetWithParams("WorldExpedition_taost_reward_automatically", I18N.Get(self.eventCfg:Name()))})
end

function WorldToastMediator:ShowProgressAnim()
    if self.showType == SHOW_TYPE.Normal then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom3)
    elseif self.showType == SHOW_TYPE.Shortly then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom5)
    end
end

function WorldToastMediator:ShowCloseAnim()
    if self.showType == SHOW_TYPE.Normal then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom9, Delegate.GetOrCreate(self, self.AnimClose))
    elseif self.showType == SHOW_TYPE.Shortly then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom10, Delegate.GetOrCreate(self, self.AnimClose))
    end
end

function WorldToastMediator:AnimClose()
    self:CloseSelf()
end

function WorldToastMediator:OnMaskClicked()
    self.showType = self.showType == SHOW_TYPE.Normal and SHOW_TYPE.Shortly or SHOW_TYPE.Normal
    self:ChangeShowType()
end

return WorldToastMediator
