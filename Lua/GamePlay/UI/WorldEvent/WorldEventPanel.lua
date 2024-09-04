local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local AudioConsts = require('AudioConsts')
local DBEntityPath = require('DBEntityPath')
local EventConst = require('EventConst')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local KingdomMapUtils = require("KingdomMapUtils")
local ManualResourceConst = require('ManualResourceConst')
local TouchMenuBasicInfoDatum = require("TouchMenuBasicInfoDatum")
local TouchMenuCellTextDatum = require("TouchMenuCellTextDatum")
local ProgressType = require("ProgressType")
local PlayType = require("PlayType")
local DBEntityType = require("DBEntityType")
local TimerUtility = require("TimerUtility")
local TimeFormatter = require('TimeFormatter')
local ColorUtil = require('ColorUtil')
local ColorConsts = require('ColorConsts')
local Vector3 = CS.UnityEngine.Vector3
local MathUtils = require('MathUtils')
local GuideUtils = require('GuideUtils')

---@class WorldEventPanel : BaseUIMediator
---@field config WorldExpeditionTemplateConfigCell
local WorldEventPanel = class('WorldEventPanel', BaseUIMediator)
local ShowVfxType = {Preview = 1, OpenNotJoin = 2, Join = 3, Complete = 4}

function WorldEventPanel:OnCreate()
    self.textContent = self:Text('p_text_world_events')
    self.p_btn_detail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnDetailClicked))
    self.imgEventIcon = self:Image('p_icon_event')
    self.p_base = self:Image('p_base')
    self.group_start = self:GameObject('group_start')
    self.previewTime = self:Text('p_text_time')
    self.p_text_hint = self:Text('p_text_hint')
    self.group_progress = self:GameObject('progress')
    self.sliderProgress = self:Slider('p_progress_score')
    self.p_text_progress_score = self:Text('p_text_progress_score')
    self.p_table_rewards = self:GameObject('p_table_rewards')
    self.rewardsTable = self:TableViewPro('p_table_rewards')
    self.textProgress = self:Text('p_text_score')
    self.eventHolder = self:GameObject('p_table_events')
    self.p_table_events = self:TableViewPro('p_table_events')
    self.remainTime = self:Text('p_text_time_finish')
    self.group_time = self:GameObject('group_time')
    self.rect = self:RectTransform('p_progress_score')

    self.trigger_world_event = self:BindComponent("trigger_world_event", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    self.trigger_iem_rewards = self:BindComponent("trigger_iem_rewards", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end

function WorldEventPanel:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Expedition.MsgPath, Delegate.GetOrCreate(self, self.Refresh))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.MapMob.MapStates.Dying.MsgPath, Delegate.GetOrCreate(self, self.PlayVfx))
    -- g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.MapMob, Delegate.GetOrCreate(self, self.OnMobCreate))
    g_Game.EventManager:AddListener(EventConst.ON_SLG_END_ONCE_INTREACTOR, Delegate.GetOrCreate(self, self.InteractorComplete))
    g_Game.EventManager:AddListener(EventConst.WORLD_EVENT_FINISH, Delegate.GetOrCreate(self, self.EventFinish))
    self.tweenList = {}
end

function WorldEventPanel:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Expedition.MsgPath, Delegate.GetOrCreate(self, self.Refresh))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapMob.MapStates.Dying.MsgPath, Delegate.GetOrCreate(self, self.PlayVfx))
    -- g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.MapMob, Delegate.GetOrCreate(self, self.OnMobCreate))
    g_Game.EventManager:RemoveListener(EventConst.ON_SLG_END_ONCE_INTREACTOR, Delegate.GetOrCreate(self, self.InteractorComplete))
    g_Game.EventManager:RemoveListener(EventConst.WORLD_EVENT_FINISH, Delegate.GetOrCreate(self, self.EventFinish))
    self:Clear()
end

function WorldEventPanel:Clear()
    self:StopTimer()
    for k, v in pairs(self.tweenList) do
        if v then
            v:DOKill()
        end
    end
    self.tweenList = {}
end

function WorldEventPanel:OnFeedData(param)
    self.rewardDots = {}
    self.expeditionInfo = param.expeditionInfo
    self.posX = param.x
    self.posY = param.y
    self.entity = g_Game.DatabaseManager:GetEntity(param.entityId, DBEntityType.Expedition)
    self.entityId = param.entityId
    self.config = ConfigRefer.WorldExpeditionTemplate:Find(self.expeditionInfo.Tid)
    self.progressType = self.config:ProgressType()
    self.playType = self.config:PlayType()
    local isMine, isMulti, isAlliance, isBigEvent = ModuleRefer.WorldEventModule:CheckEventType(self.entity)
    self.isBigEvent = isBigEvent
    ModuleRefer.WorldEventModule:SetWorldEventByPanel(self.entity, isBigEvent)
    local icon = ModuleRefer.WorldEventModule:GetWorldEventPanelBaseByEntity(self.entity)
    local eventIcon = ModuleRefer.WorldEventModule:GetWorldEventPanelEventIconByEntity(self.entity)
    g_Game.SpriteManager:LoadSprite(icon, self.p_base)
    g_Game.SpriteManager:LoadSprite(eventIcon, self.imgEventIcon)

    self:Refresh()
    self:PlayOnShowEffect()
    -- Test 
    -- ModuleRefer.WorldEventModule:AllianceEventPreviewToast(self.entity)
end

function WorldEventPanel:EventFinish(entityID)
    if entityID and entityID ~= self.entity.ID then
        return
    end
    self:Refresh()
end

function WorldEventPanel:Refresh()
    if not self.entity then
        return
    end

    if self.progressType == ProgressType.Alliance then
        self.allianceExpeditionsInfo = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByExpeditionID(self.expeditionInfo.Tid)
        -- 联盟事件关闭时，判空
        if self.allianceExpeditionsInfo == nil then
            local param = {isShow = false, isBoss = false, isShutDown = true}
            g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_SHOW_HIDE, param)
            return
        end

        local allianceCfg = ConfigRefer.AllianceActivityExpedition:Find(self.allianceExpeditionsInfo.ConfigId)
        local activity = ModuleRefer.WorldEventModule:GetActiveActivity(allianceCfg)
        local startT, endT = ModuleRefer.WorldEventModule:GetActivityCountDown(activity)
        self.activityStartT = startT
        self.activityEndT = endT

        -- 联盟小事件倒计时特判
        if not self.isBigEvent then
            self.activityStartT = self.allianceExpeditionsInfo.StartActiveTime
        end
    end

    if self.expeditionInfo.State == wds.ExpeditionState.ExpeditionNotice then
        self.textContent.text = I18N.Get(self.config:Name())
        self.sliderProgress.value = 0
        local colorText = ColorUtil.FromGammaStrToLinearStr(ColorConsts.warning)

        if self.isBigEvent then
            local text = string.format("<color=%s>%s</color>", colorText, I18N.Get("alliance_worldevent_tips_main"))
            self.p_text_hint.text = text
            self.p_text_hint:SetVisible(true)
        else
            self.p_text_hint:SetVisible(false)
        end

        self.group_start:SetVisible(true)
        self.group_progress:SetVisible(false)
        self.eventHolder:SetVisible(false)
        self.group_time:SetVisible(false)
        self.textProgress:SetVisible(false)
        self.showType = ShowVfxType.Preview
        self:SetPreviewTime()
        self:SetPreviewTimer()
    elseif self.expeditionInfo.State == wds.ExpeditionState.ExpeditionActive or self.expeditionInfo.State == wds.ExpeditionState.ExpeditionUnActive then
        self.textContent.text = I18N.Get(self.config:Name())
        if self.isFinish then
            self.textContent.text = self.textContent.text .. I18N.Get("worldevent_wancheng")
        end
        self.textProgress:SetVisible(true)
        self.group_start:SetVisible(false)
        self.group_progress:SetVisible(true)
        self.eventHolder:SetVisible(true)
        self.group_time:SetVisible(true)

        self.showType = self.expeditionInfo.State == wds.ExpeditionState.ExpeditionUnActive and ShowVfxType.Complete or ShowVfxType.Join
        self:RefreshContent()
        self:SetProgressTime()
        self:SetProgressTimer()
    end
end

function WorldEventPanel:RefreshContent()
    local progress = 0
    local percent = 0
    local personalProgress = self.expeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
    self.personalProgress = personalProgress

    -- boss事件进度特殊处理
    if self.playType == PlayType.Boss then
        self:StopTimer()
        self.p_table_rewards:SetVisible(false)
        local bossID = self.expeditionInfo.ProgressRelatedEntityId
        self.bossEntity = g_Game.DatabaseManager:GetEntity(bossID, DBEntityType.MapMob)
        percent = math.clamp(1 - self.bossEntity.Battle.Hp / self.bossEntity.Battle.MaxHp, 0, 1)
        progress = self.personalProgress
        self:SetBossContent()
        if percent < 1 then
            self.bossTimer = TimerUtility.IntervalRepeat(function()
                self:SetBossContent()
            end, 0.2, -1)
        end
    else
        if self.progressType == ProgressType.Whole then
            self.p_table_rewards:SetVisible(false)
            progress = self.expeditionInfo.Progress
            self.textProgress.text = string.format('%s<b>%d</b>', I18N.Get("Worldexpedition_my_progress"), personalProgress)
        elseif self.progressType == ProgressType.Personal then
            self.p_table_rewards:SetVisible(false)
            self.textProgress:SetVisible(false)
            progress = personalProgress
            TimerUtility.DelayExecute(function()
                GuideUtils.GotoByGuide(44)
            end, 1)
        elseif self.progressType == ProgressType.Alliance then
            self.p_table_rewards:SetVisible(true)
            progress = self.expeditionInfo.Progress

            if #self.rewardDots == 0 then
                self.rewardsTable:Clear()
                local size = self.rect.rect.size
                local count = self.config:AlliancePartProgressRewardLength()
                for i = 1, count do
                    local cfg = self.config:AlliancePartProgressReward(i)
                    local num = cfg:Progress(i)
                    self.rewardDots[i] = num
                    local param = {}
                    param.pos = size * (num / 100)
                    param.index = i
                    param.progress = progress
                    param.num = num
                    self.rewardsTable:AppendData(param)
                end
            end
            self.textProgress.text = string.format('%s<b>%d</b>', I18N.Get("Worldexpedition_my_progress"), personalProgress)
        end
        percent = math.clamp(progress / self.config:MaxProgress(), 0, 1)

    end

    self:SetEventContent()

    self.progress = progress
    self.percent = percent
    self.sliderProgress.value = percent
    self.p_text_progress_score.text = math.floor(percent * 100) .. "%"
    self.isFinish = percent >= 1
    if self.isFinish then
        g_Game.SoundManager:PlayAudio(AudioConsts.sfx_worldtask_finish)
        self:ShowSuccessAnim()
    end
end

function WorldEventPanel:SetEventContent()
    self.p_table_events:Clear()
    local param = ModuleRefer.WorldEventModule:GetSpawnerUnit(self.expeditionInfo.Tid)

    for i = 1, self.config:WorldExpeditionDescGroupLength() do
        local cfg = ConfigRefer.WorldExpeditionDesc:Find(self.config:WorldExpeditionDescGroup(i))
        local res = {}
        res.descType = cfg:StageDescType(1)
        res.desc = cfg:StageDesc(1)
        res.expeditionId = self.entityId
        res.curValue = 0
        res.maxValue = 0
        res.spawnUnits = {}
        -- 多个交互物进度
        for i = 1, cfg:SpawnerBaseRuleUnitIndexLength() do
            local index = cfg:SpawnerBaseRuleUnitIndex(i)
            local curValueKey = "spawner_unit_" .. index
            if param[index] == nil then
                g_Logger.Error("未找到世界事件交互物：" .. curValueKey)
            else
                local unit = {spawnID = param[index].spawnID, spawnType = param[index].spawnType}
                res.spawnUnits[i] = unit
                local unitValue = self.entity.Level.SyncData.Global[curValueKey] and self.entity.Level.SyncData.Global[curValueKey].IntValue or 0
                res.curValue = res.curValue + unitValue
                res.maxValue = res.maxValue + param[index].maxValue
            end
        end
        self.p_table_events:AppendData(res)

    end

    -- self.p_table_events:RefreshAllShownItem()
end

function WorldEventPanel:SetBossContent()
    if self.bossEntity and self.playType == PlayType.Boss then
        local percent = math.clamp(1 - self.bossEntity.Battle.Hp / self.bossEntity.Battle.MaxHp, 0, 1)
        self.personalProgress = self.expeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0

        self.textProgress.text = string.format('%s<b>%d</b>', I18N.Get("Worldexpedition_my_progress"), self.personalProgress)

        self.percent = percent
        self.progress = percent * 100
        self.sliderProgress.value = percent
    end
end

function WorldEventPanel:SetPreviewTime()
    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local endTime
    if self.progressType == ProgressType.Alliance then
        if curTime < self.activityStartT then
            endTime = self.activityStartT
            if not self.isBigEvent then
                self.previewTime.text = I18N.GetWithParams("alliance_worldevent_open_times", TimeFormatter.SimpleFormatTime(math.max(0, endTime - curTime)))
            else
                self.previewTime.text = I18N.GetWithParams("alliance_worldevent_time1", TimeFormatter.SimpleFormatTime(math.max(0, endTime - curTime)))
            end
        else
            endTime = self.activityEndT
            self.previewTime.text = I18N.Get('protect_info_time_left') .. TimeFormatter.SimpleFormatTime(math.max(0, endTime - curTime))
            self.showType = ShowVfxType.OpenNotJoin
        end
    else
        endTime = self.expeditionInfo.ActivateEndTime
        self.previewTime.text = I18N.GetWithParams("alliance_worldevent_open_times", TimeFormatter.SimpleFormatTime(math.max(0, endTime - curTime)))
    end
end

function WorldEventPanel:SetProgressTime()
    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local endTime
    if self.progressType == ProgressType.Alliance then
        endTime = self.activityEndT
    else
        endTime = self.expeditionInfo.ActivateEndTime
    end
    local remainTime = math.max(0, endTime - curTime)
    self.remainTime.text = I18N.Get("worldevent_time") .. TimeFormatter.SimpleFormatTime(remainTime)
end

function WorldEventPanel:SetPreviewTimer()
    if not self.previewTimer then
        self.previewTimer = TimerUtility.IntervalRepeat(function()
            self:SetPreviewTime()
        end, 1, -1)
    end
end

function WorldEventPanel:SetProgressTimer()
    if not self.remainTimer then
        self.remainTimer = TimerUtility.IntervalRepeat(function()
            self:SetProgressTime()
        end, 1, -1)
    end
end

function WorldEventPanel:StopTimer()
    if self.bossTimer then
        TimerUtility.StopAndRecycle(self.bossTimer)
        self.bossTimer = nil
    end
    if self.remainTimer then
        TimerUtility.StopAndRecycle(self.remainTimer)
        self.remainTimer = nil
    end
    if self.previewTimer then
        TimerUtility.StopAndRecycle(self.previewTimer)
        self.previewTimer = nil
    end
end

function WorldEventPanel:OnDetailClicked()
    ---@type WorldEventDetailMediatorParameter
    local param = {}
    param.clickTransform = self.p_btn_detail.transform
    param.touchMenuBasicInfoDatum = TouchMenuBasicInfoDatum.new(I18N.Get(self.config:Name()), "", "", self.config:Level())
    param.touchMenuCellTextDatum = TouchMenuCellTextDatum.new(I18N.Get(self.config:Des()), true)
    param.tid = self.expeditionInfo.Tid
    param.x = self.posX
    param.y = self.posY
    param.progress = self.progress
    if self.personalProgress then
        param.personalProgress = self.personalProgress
    end
    param.openType = 1

    self._infoToastUI = ModuleRefer.ToastModule:ShowWorldEventDetail(param)
end

-- 动画部分
function WorldEventPanel:PlayOnShowEffect()
    if self.showType == ShowVfxType.Preview then
        self.trigger_world_event:PlayAll(FpAnimTriggerEvent.Custom1)
    elseif self.showType == ShowVfxType.OpenNotJoin then
        self.trigger_world_event:PlayAll(FpAnimTriggerEvent.Custom2)
    elseif self.showType == ShowVfxType.Join then
        self.trigger_world_event:PlayAll(FpAnimTriggerEvent.Custom3)
    end
end

function WorldEventPanel:ShowSuccessAnim()
    self.trigger_world_event:PlayAll(FpAnimTriggerEvent.Custom4)
    TimerUtility.DelayExecute(function()
        local param = {isShow = false, isBoss = false}
        g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_SHOW_HIDE, param)
    end, 1)
end

function WorldEventPanel:InteractorComplete(msg)
    local entity = g_Game.DatabaseManager:GetEntity(msg.InteractorId, DBEntityType.SlgInteractor)
    self:PlayVfx(entity)
end

-- 联盟世界事件内怪物死亡/交互物消失，飞特效
function WorldEventPanel:PlayVfx(entity, changeTable)
    if not entity or entity.Owner.ExclusiveAllianceId ~= ModuleRefer.AllianceModule:GetAllianceId() then
        return
    end
    local startCoorPos = entity.MapBasics.Position
    local startWorldPos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(math.floor(startCoorPos.X), math.floor(startCoorPos.Y), KingdomMapUtils.GetMapSystem())
    local startScreenPos = KingdomMapUtils.WorldToScreenPosition(startWorldPos) + Vector3(-CS.UnityEngine.Screen.width / 2, -CS.UnityEngine.Screen.height / 2, 0)
    local endPos = self.group_progress.transform.position
    local rewardVfx = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    local uiRoot = g_Game.UIManager:GetUIRoot()

    rewardVfx:Create(ManualResourceConst.ui_hud_city_vfx_word_event_trail, ManualResourceConst.ui_hud_city_vfx_word_event_trail, uiRoot.transform, function(success, obj, handle)
        if success then
            local go = handle.Effect.gameObject
            go.transform.localPosition = startScreenPos
            go.transform.localScale = Vector3(10, 10, 1)
            local startPos = go.transform.position

            -- 特殊处理曲线形状
            local pivot = Vector3.up
            if startPos.y < endPos.y then
                pivot = Vector3.up
            elseif startPos.y >= endPos.y then
                pivot = Vector3.down
            end
            if startPos.x < endPos.x then
                pivot = Vector3.right
            end
            MathUtils.Paracurve(go.transform, startPos, endPos, pivot, 2.5, 8, 0.6)
            table.insert(self.tweenList, go.transform)
            TimerUtility.DelayExecute(function()
                self.trigger_iem_rewards:PlayAll(FpAnimTriggerEvent.Custom1)
                g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_PROGRESS_DOT, self.progress)
                rewardVfx:Delete()
            end, 0.6)
        end
    end, nil, 0, false, false)
end

function WorldEventPanel:OnMobCreate(type, entity)
    -- if entity.LevelEntityInfo.LevelEntityId == self.entityId then
    --     ModuleRefer.WorldEventModule:SpawnProjectile(entity)
    -- end
end

return WorldEventPanel
