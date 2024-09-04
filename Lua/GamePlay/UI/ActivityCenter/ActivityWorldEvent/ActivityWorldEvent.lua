local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')
local TimeFormatter = require('TimeFormatter')
local ConfigRefer = require('ConfigRefer')
local OpenAllianceExpeditionParameter = require('OpenAllianceExpeditionParameter')
local ReceiveExpeditionPartProgressRewardParameter = require('ReceiveExpeditionPartProgressRewardParameter')
local DBEntityType = require('DBEntityType')
local AllianceExpeditionOpenType = require('AllianceExpeditionOpenType')
local ActivityWorldEventConst = require('ActivityWorldEventConst')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')

---@class ActivityWorldEvent : BaseUIComponent
local ActivityWorldEvent = class('ActivityWorldEvent', BaseUIComponent)

function ActivityWorldEvent:OnCreate()
    self.p_text_time = self:Text('p_text_time')
    self.p_text_info = self:Text('p_text_info', I18N.Get("alliance_worldevent_rule"))
    self.p_btn_detail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnClickDetail))
    self.p_text_count_down = self:Text('p_text_count_down')
    self.p_text_count_down_1 = self:Text('p_text_count_down_1', I18N.Get(":"))
    self.p_text_count_down_2 = self:Text('p_text_count_down_2')
    self.p_text_count_down_3 = self:Text('p_text_count_down_3', I18N.Get(":"))
    self.p_text_count_down_4 = self:Text('p_text_count_down_4')

    self.p_text_title = self:Text('p_text_title')
    self.p_text_start = self:Text('p_text_start')
    self.p_text_describe = self:Text('p_text_describe', I18N.Get("alliance_worldevent_big_describe"))

    self.p_group_progress = self:GameObject('p_group_progress')
    -- 领奖部分
    self.p_text_score = self:Text('p_text_score', I18N.Get("alliance_worldevent_big_tips_personalpoints"))
    self.p_text_progress = self:Text('p_text_progress', I18N.Get("alliance_worldevent_big_title_schedule"))
    self.p_btn_score = self:Button('p_btn_score', Delegate.GetOrCreate(self, self.OnBtnClickPersonalClaim))

    self.p_icon_gift = self:Image('p_icon_gift')
    self.p_img_gift_claim = self:GameObject('p_img_gift_claim')
    self.p_icon_gift_finish = self:Image('p_icon_gift_finish')

    self.p_table_reward = self:TableViewPro('p_table_reward')
    self.p_table_rewards = self:TableViewPro('p_table_rewards')
    self.p_table_award = self:TableViewPro('p_table_award')

    self.p_progress = self:Slider('p_progress')
    self.p_progress_score = self:Slider('p_progress_score')
    self.p_text_progress_score = self:Text('p_text_progress_score')

    self.p_text_activity_time = self:Text('p_text_activity_time')
    self.p_text_activity_position = self:Text('p_text_activity_position', I18N.Get("alliance_worldevent_small_refreshlocation"))
    self.p_text_hint_start = self:Text('p_text_hint_start', I18N.Get("alliance_worldevent_tips_main"))
    ---@type BistateButton
    self.child_comp_btn_b = self:LuaObject('child_comp_btn_b')
    self.p_text_hint = self:Text('p_text_hint', I18N.Get("alliance_worldevent_big_openget"))
    self.p_btn_rank = self:Button('p_btn_rank', Delegate.GetOrCreate(self, self.OnBtnClickShowRank))

    self.rect = self:RectTransform('p_table_rewards')

    -- 联盟中心部分
    self.btn_alliance_build = self:GameObject('btn_alliance_build')
    self.p_text_hint_build = self:Text('p_text_hint_build', I18N.Get("alliance_worldevent_small_refreshcondition"))
    self.p_text = self:Text('p_text', I18N.Get("worldevent_qianwang"))
    self.child_comp_btn_b_l = self:Button('child_comp_btn_b_l', Delegate.GetOrCreate(self, self.OnBtnClickRepairAllianceCenter))

    -- 小事件刷新时间
    self.refreshTimeHolder = {}
    self.refreshTimeHolder[1] = self:Text('p_text_time_1')
    self.refreshTimeHolder[2] = self:Text('p_text_time_2')
    self.refreshTimeHolder[3] = self:Text('p_text_time_3')

    self.refreshTimeGroupHolder = {}
    self.refreshTimeGroupHolder[1] = self:GameObject('p_group_time_1')
    self.refreshTimeGroupHolder[2] = self:GameObject('p_group_time_2')
    self.refreshTimeGroupHolder[3] = self:GameObject('p_group_time_3')

    self.p_group_countdown = self:GameObject('p_group_countdown')

    -- 大事件单独用
    self.p_btn_detail_1 = self:Button('p_btn_detail_1', Delegate.GetOrCreate(self, self.onBtnClickPersonalPrompt))
    self.p_btn_detail_2 = self:Button('p_btn_detail_2', Delegate.GetOrCreate(self, self.onBtnClickAlliancePrompt))

    self.isFirstOpen = true
    self.vxTrigger = self:AnimTrigger('vx_trigger')
end
function ActivityWorldEvent:OnShow()
    if self.isFirstOpen then
        self.isFirstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
end

function ActivityWorldEvent:OnHide()
    self:StopTimer()
end

function ActivityWorldEvent:OnFeedData(param)
    self.p_text_hint_build:SetVisible(false)
    self.btn_alliance_build:SetVisible(false)

    self.personalRewardClaimable = false
    self.param = param
    local tabCfg = ConfigRefer.ActivityCenterTabs:Find(param.tabId)
    local allianceExpeditions = {}
    for i = 1, tabCfg:RefAllianceActivityExpeditionLength() do
        allianceExpeditions[i] = tabCfg:RefAllianceActivityExpedition(i)
    end
    self.cfgId = ModuleRefer.WorldEventModule:GetAllianceExpeditionCfgByLands(allianceExpeditions)
    local allianceCfg = ConfigRefer.AllianceActivityExpedition:Find(self.cfgId)
    local expedition = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByConfigID(self.cfgId)
    self.ExpeditionEntityId = expedition and expedition.ExpeditionEntityId or nil

    local status
    local expeditionID

    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceInfo then
        -- 大事件可能在没有联盟的时候刷新出来
        expeditionID = allianceCfg:Expeditions(1)
    else
        self.allianceEventInfo = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByConfigID(self.cfgId)
        expeditionID = self.allianceEventInfo and self.allianceEventInfo.ExpeditionConfigId or allianceCfg:Expeditions(1)
    end

    -- 区分大小联盟事件
    local isBigEvent = true
    -- 隐藏所有刷新时间
    for i = 1, 3 do
        if self.refreshTimeGroupHolder[i] then
            isBigEvent = false
            self.refreshTimeGroupHolder[i]:SetVisible(false)
        else
            isBigEvent = true
            break
        end
    end

    -- 活动总时间
    local eventStartT
    local eventEndT
    self.activityId = allianceCfg:DisplayTime()
    eventStartT, eventEndT = ModuleRefer.WorldEventModule:GetActivityCountDown(self.activityId)

    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    local startTimeStr = TimeFormatter.TimeToDateTimeStringUseFormat(eventStartT, "yyyy.MM.dd")
    local endTimeStr = TimeFormatter.TimeToDateTimeStringUseFormat(eventEndT, "yyyy.MM.dd")
    self.p_text_time.text = I18N.GetWithParams("alliance_worldevent_big_time", startTimeStr, endTimeStr)

    -- 预告倒计时
    self:SetPreviewCountDown()
    if curT < eventStartT then
        self:SetPreviewCountDownTimer()
    end

    -- 小型世界事件刷新时间
    if not isBigEvent then
        local timeTable = {}
        for i = 1, allianceCfg:ActivitiesLength() do
            local activityId = allianceCfg:Activities(i)
            local startT, endT = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityId)
            startT = TimeFormatter.TimeToDateTimeStringUseFormat(startT.Seconds, "HH:mm")
            endT = TimeFormatter.TimeToDateTimeStringUseFormat(endT.Seconds, "HH:mm")
            local res = startT .. " - " .. endT
            if not table.ContainsValue(timeTable, res) then
                table.insert(timeTable, res)
            end
        end

        local index = 1
        for k, v in pairs(timeTable) do
            if index > 3 then
                break
            end
            self.refreshTimeHolder[index].text = v
            self.refreshTimeGroupHolder[index]:SetVisible(true)
            index = index + 1
        end
        self.p_text_activity_time.text = I18N.Get("shop_refreshtime")
    end

    -- 联盟事件阶段倒计时
    local activityStartTime, activityEndTime = ModuleRefer.WorldEventModule:GetActivityCountDown(self.activityId)
    self.activityStartTime = activityStartTime
    self.activityEndTime = activityEndTime
    local isEventActive = self.allianceEventInfo and self.allianceEventInfo.ExpeditionConfigId or nil

    if isEventActive == nil or curT < activityStartTime then
        if self.p_group_countdown then
            self.p_group_countdown:SetVisible(false)
            self.p_text_start:SetVisible(false)
        end
        status = ActivityWorldEventConst.EventStatusEnum.Preveiw
    elseif curT > activityStartTime and curT < activityEndTime then
        if self.p_group_countdown then
            self.p_group_countdown:SetVisible(true)
            self.p_text_start:SetVisible(true)
            self.p_text_start.text = I18N.Get("alliance_worldevent_end1")
        end
        self:SetCountDown()
        self:SetCountDownTimer()
        status = ActivityWorldEventConst.EventStatusEnum.Start
    end

    local config = ConfigRefer.WorldExpeditionTemplate:Find(expeditionID)
    local type = allianceCfg:OpenType()
    self.progressType = type
    self.status = status
    self.config = config
    self.expeditionID = expeditionID

    -- 活动预告
    if type == AllianceExpeditionOpenType.AutoRandom then
        self:ShowCountDown(false)
        self.p_text_describe:SetVisible(false)
        self.p_text_title.text = I18N.Get("alliance_worldevent_small_name")
        self.p_text_activity_time:SetVisible(true)
        self.p_text_activity_position:SetVisible(true)
        self:SetPreviewReward()
    elseif type == AllianceExpeditionOpenType.Manual then
        self:ShowCountDown(true)
        self.p_text_describe:SetVisible(true)
        self.p_text_title.text = I18N.Get("alliance_worldevent_big_name")
        self.p_text_activity_time:SetVisible(false)
        self.p_text_activity_position:SetVisible(false)

        if status == ActivityWorldEventConst.EventStatusEnum.Preveiw then
            self:SetPreviewReward()
        elseif status == ActivityWorldEventConst.EventStatusEnum.Start then
            local needAccept = ModuleRefer.WorldEventModule:NeedAcceptAllianceEvent(self.cfgId)
            if allianceInfo == nil or needAccept then
                self:SetPreviewReward()
            else
                self:SetAllianceReward()
                self:SetPersonalReward()
            end
        end
    end
    self:SetButton()
end

function ActivityWorldEvent:ShowCountDown(isShow)
    self.p_text_count_down:SetVisible(isShow)
    if self.p_text_count_down_1 then -- 两个 child_activity_world_events 未同步时 判空一下
        self.p_text_count_down_1:SetVisible(isShow)
        self.p_text_count_down_2:SetVisible(isShow)
        self.p_text_count_down_3:SetVisible(isShow)
        self.p_text_count_down_4:SetVisible(isShow)
    end
end

-- 下方按钮
function ActivityWorldEvent:SetButton()
    local btnData = {}
    local type = self.progressType
    local status = self.status

    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    local allianceCenterId = ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillageId()
    local systemEntry = ConfigRefer.AllianceActivityExpedition:Find(self.cfgId):SystemSwitch()
    local unlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemEntry)

    -- 没加入联盟
    if not allianceInfo then
        self.p_text_hint_start:SetVisible(false)
        self.p_text_hint:SetVisible(true)
        self.p_text_hint.text = I18N.Get("alliance_worldevent_big_tips")
        self.child_comp_btn_b:SetVisible(true)
        btnData.onClick = Delegate.GetOrCreate(self, self.OnBtnClickJoinAlliance)
        btnData.buttonText = I18N.Get("alliance_worldevent_big_button_enter")
        self.child_comp_btn_b:SetEnabled(true)
    elseif allianceCenterId == nil then
        -- 没联盟中心
        self.child_comp_btn_b:SetVisible(true)
        self.p_text_hint.text = I18N.Get("alliance_worldevent_small_refreshcondition")
        btnData.onClick = Delegate.GetOrCreate(self, self.OnBtnClickRepairAllianceCenter)
        btnData.buttonText = I18N.Get("worldevent_qianwang")
        self.child_comp_btn_b:SetEnabled(true)

    elseif not unlock then
        local stage = ConfigRefer.SystemEntry:Find(systemEntry):UnlockWorldStageIndex()
        self.p_text_hint:SetVisible(true)
        self.p_text_hint.text = I18N.GetWithParams("WorldStage_toast_unlockStage", stage)
        self.child_comp_btn_b:SetVisible(false)
    else
        -- 自动下发类型事件
        if type == AllianceExpeditionOpenType.AutoRandom then
            self.p_text_hint:SetVisible(true)
            local limits = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerExpeditions.AllianceExpeditionLimitInfo.Limits
            local curWeeklyRewardTime = limits[self.cfgId] and limits[self.cfgId] or 0
            local maxWeeklyRewardTime = ConfigRefer.AllianceActivityExpedition:Find(self.cfgId):Limit()
            self.p_text_hint.text = I18N.Get("alliance_worldevent_small_rewardnum") .. "<b><color=off_white>" .. maxWeeklyRewardTime - curWeeklyRewardTime .. "/" .. maxWeeklyRewardTime ..
                                        "</color></b>"
            self.p_text_hint_start:SetVisible(false)
            if status == ActivityWorldEventConst.EventStatusEnum.Preveiw then
                self.child_comp_btn_b:SetVisible(false)
            elseif status == ActivityWorldEventConst.EventStatusEnum.Start then
                self.child_comp_btn_b:SetVisible(true)
                -- 检查联盟进度是否已满
                local curValue = self.allianceEventInfo and self.allianceEventInfo.Progress or 0
                if curValue >= 100 then
                    btnData.onClick = nil
                    btnData.buttonText = I18N.Get("alliance_worldevent_big_state_end")
                else
                    btnData.onClick = Delegate.GetOrCreate(self, self.OnBtnClickGoto)
                    btnData.buttonText = I18N.Get("worldevent_qianwang")
                end
                self.child_comp_btn_b:SetEnabled(true)
            end
            -- 主动领取类型事件
        elseif type == AllianceExpeditionOpenType.Manual then
            if status == ActivityWorldEventConst.EventStatusEnum.Preveiw then
                self.child_comp_btn_b:SetVisible(false)
                self.p_text_hint:SetVisible(false)
                self.p_text_hint_start:SetVisible(true)
            elseif status == ActivityWorldEventConst.EventStatusEnum.Start then
                self.p_text_hint:SetVisible(true)
                self.p_text_hint_start:SetVisible(false)
                -- 是否需要接取
                local needAccept = ModuleRefer.WorldEventModule:NeedAcceptAllianceEvent(self.cfgId)
                if needAccept then
                    self.p_text_hint.text = I18N.Get("alliance_worldevent_big_openget")
                    local isLeader = ModuleRefer.AllianceModule:IsAllianceR4Above()
                    if isLeader then
                        btnData.onClick = Delegate.GetOrCreate(self, self.OnBtnClickAccept)
                        btnData.buttonText = I18N.Get("alliance_worldevent_big_button_receiving")
                        self.child_comp_btn_b:SetEnabled(true)
                    else
                        btnData.buttonText = I18N.Get("alliance_worldevent_not_receiving")
                        self.child_comp_btn_b:SetEnabled(false)
                    end
                else
                    -- 检查联盟进度是否已满
                    local curValue = self.allianceEventInfo and self.allianceEventInfo.Progress or 0
                    self.p_text_hint.text = I18N.Get("alliance_worldevent_big_tips_goto")

                    if curValue >= 100 then
                        btnData.onClick = nil
                        btnData.buttonText = I18N.Get("alliance_worldevent_big_state_end")
                        self.p_text_hint:SetVisible(false)
                    else
                        btnData.onClick = Delegate.GetOrCreate(self, self.OnBtnClickGoto)
                        btnData.buttonText = I18N.Get("worldevent_qianwang")
                    end
                    self.child_comp_btn_b:SetEnabled(true)
                end
            end
        end
    end

    self.child_comp_btn_b:FeedData(btnData)
end

function ActivityWorldEvent:SetPreviewReward()
    self.p_table_award:Clear()
    self.p_table_award:SetVisible(true)
    self.p_group_progress:SetVisible(false)

    local cfg = ConfigRefer.AllianceActivityExpedition:Find(self.cfgId)
    for i = 1, cfg:PreviewRewardItemIdsLength() do
        local item = cfg:PreviewRewardItemIds(i)
        local iconData = {}
        iconData.configCell = ConfigRefer.Item:Find(item)
        self.p_table_award:AppendData(iconData)
    end
    self.p_btn_rank:SetVisible(false)
    -- self.p_table_award:RefreshAllShownItem()
end

function ActivityWorldEvent:SetAllianceReward()
    local record = ModuleRefer.WorldEventModule:GetAllianceExpeditionRecord()[self.ExpeditionEntityId]
    local curValue = self.allianceEventInfo and self.allianceEventInfo.Progress or 0
    local maxValue = 100
    self.p_progress.value = math.clamp01(curValue / maxValue)

    self.p_table_award:SetVisible(false)
    self.p_group_progress:SetVisible(true)

    local size = self.rect.rect.size
    local count = self.config:AlliancePartProgressRewardLength()

    self.p_table_rewards:Clear()
    for i = 1, count do
        local param = {}
        local cfg = self.config:AlliancePartProgressReward(i)
        local num = cfg:Progress(i)
        local itemGroupConfig = ConfigRefer.ItemGroup:Find(cfg:Reward())
        param.itemGroupConfig = itemGroupConfig
        param.index = i
        param.num = num
        param.curValue = curValue
        param.isClaimed = self:CheckAllianceRecord(record, num)
        param.posX = size.x * (num / 100)
        param.ExpeditionEntityId = self.ExpeditionEntityId
        self.p_table_rewards:AppendData(param)
    end
    self.p_table_rewards:RefreshAllShownItem()
    self.p_btn_rank:SetVisible(true)
end

function ActivityWorldEvent:CheckAllianceRecord(record, progress)
    if record then
        for k, v in pairs(record.RewardedProgress) do
            if v == progress then
                return true
            end
        end
    end

    return false
end

function ActivityWorldEvent:GetPersonalRewardStatus(rewards)
    local stage = 0
    for k, v in pairs(rewards) do
        if v == true then
            stage = stage + 1
        end
    end
    return stage
end

function ActivityWorldEvent:SetPersonalReward()
    self.personalRewards = {}
    local playerRewardInfo = ModuleRefer.WorldEventModule:GetPersonalExpeditionInfo(self.expeditionID)
    local curProgress = playerRewardInfo.PersonalProgress
    local rewardState = playerRewardInfo.stageRewardState
    local rewardTable = ModuleRefer.WorldEventModule:GetPersonalRewardByExpeditionID(self.expeditionID)
    local count = #rewardTable
    self.personalRewardTier = math.clamp(self:GetPersonalRewardStatus(rewardState) + 1, 1, count)
    self.p_table_reward:Clear()
    local chestIndex = 1
    for i = 1, count do
        local num = rewardTable[i].progress
        local param = {}
        local itemGroupConfig = ConfigRefer.ItemGroup:Find(rewardTable[i].reward)
        param.itemGroupConfig = itemGroupConfig
        param.index = i
        param.isLast = i == count
        param.num = num
        param.curValue = curProgress
        param.isClaimed = rewardState and rewardState[i - 1] or false
        param.eventID = self.expeditionID
        self.p_table_reward:AppendData(param)
        self.personalRewards[i] = param

        if curProgress >= num and param.isClaimed then
            chestIndex = chestIndex + 1
        end
    end
    self.p_table_reward:RefreshAllShownItem()

    local maxPrgoress = rewardTable[self.personalRewardTier].progress
    self.personalRewardClaimable = curProgress >= maxPrgoress
    self.p_progress_score.value = math.clamp01(curProgress / maxPrgoress)
    self.p_text_progress_score.text = curProgress .. "/" .. maxPrgoress

    if chestIndex == 1 then
        g_Game.SpriteManager:LoadSprite("sp_task_icon_box_1", self.p_icon_gift)
    elseif chestIndex == 2 then
        g_Game.SpriteManager:LoadSprite("sp_task_icon_box_4", self.p_icon_gift)
    else
        g_Game.SpriteManager:LoadSprite("sp_task_icon_box_5", self.p_icon_gift)
    end

    if self.personalRewardClaimable then
        if self.personalRewards[self.personalRewardTier].isClaimed then
            self.p_img_gift_claim:SetVisible(false)
            self.p_icon_gift:SetVisible(false)
            self.p_icon_gift_finish:SetVisible(true)
            g_Game.SpriteManager:LoadSprite("sp_task_icon_box_5_open", self.p_icon_gift_finish)
        else
            self.p_img_gift_claim:SetVisible(true)
            self.p_icon_gift:SetVisible(true)
            self.p_icon_gift_finish:SetVisible(false)
        end
    else
        self.p_img_gift_claim:SetVisible(false)
        self.p_icon_gift:SetVisible(true)
        self.p_icon_gift_finish:SetVisible(false)
    end
end

function ActivityWorldEvent:SetCountDown()
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    local seconds = self.activityEndTime - curT
    local h, m, s = self:GetCountDown(seconds)
    self.p_text_count_down.text = string.format("%02d", h)
    if self.p_text_count_down_2 then
        self.p_text_count_down_2.text = string.format("%02d", m)
        self.p_text_count_down_4.text = string.format("%02d", s)
    end
end

function ActivityWorldEvent:GetCountDown(seconds)
    local int = math.floor(seconds);
    int = int > 0 and int or 0
    local h = int // TimeFormatter.OneHourSeconds;
    int = int - h * TimeFormatter.OneHourSeconds;
    local m = int // TimeFormatter.OneMinuteSeconds;
    local s = int % TimeFormatter.OneMinuteSeconds;
    return h, m, s
end

function ActivityWorldEvent:SetCountDownTimer()
    if not self.countdownTimer then
        self.countdownTimer = TimerUtility.IntervalRepeat(function()
            self:SetCountDown()
        end, 1, -1, true)
    end
end

function ActivityWorldEvent:StopTimer()
    if self.countdownTimer then
        TimerUtility.StopAndRecycle(self.countdownTimer)
        self.countdownTimer = nil
    end
    if self.previewTimer then
        TimerUtility.StopAndRecycle(self.previewTimer)
        self.previewTimer = nil
    end
end

function ActivityWorldEvent:SetPreviewCountDown()
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    local eventStartT, eventEndT = ModuleRefer.WorldEventModule:GetActivityCountDown(self.activityId)

    if curT < eventStartT then
        self.p_text_start:SetVisible(true)
        self.p_text_start.text = I18N.GetWithParams("alliance_worldevent_begin1", TimeFormatter.SimpleFormatTime(math.max(0, eventStartT - curT)))
    else
        self.p_text_start:SetVisible(false)
        if self.previewTimer then
            TimerUtility.StopAndRecycle(self.previewTimer)
            self.previewTimer = nil
            -- 重新刷新此页面
            self:OnFeedData(self.param)
        end
    end
end

function ActivityWorldEvent:SetPreviewCountDownTimer()
    if not self.previewTimer then
        self.previewTimer = TimerUtility.IntervalRepeat(function()
            self:SetPreviewCountDown()
        end, 1, -1, true)
    end
end

function ActivityWorldEvent:SetCountDownTimer()
    if not self.countdownTimer then
        self.countdownTimer = TimerUtility.IntervalRepeat(function()
            self:SetCountDown()
        end, 1, -1, true)
    end
end

function ActivityWorldEvent:OnBtnClickDetail()
    ---@type TextToastMediatorParameter
    local param = {}
    if self.cfgId == 1 then
        param.content = I18N.Get('alliance_worldevent_big_rule')
    else
        param.content = I18N.Get('alliance_worldevent_small_rule')
    end
    param.clickTransform = self.p_btn_detail.gameObject.transform
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function ActivityWorldEvent:OnBtnClickPersonalClaim()
    if self.personalRewardClaimable and not self.personalRewards[self.personalRewardTier].isClaimed then
        -- claim
        local parameter = ReceiveExpeditionPartProgressRewardParameter.new()
        parameter.args.ExpeditionEntityId = self.ExpeditionEntityId
        parameter.args.StageId = self.personalRewardTier - 1

        parameter:SendOnceCallback(nil, nil, nil, function(_, isSuccess, _)
            if isSuccess then
                local param = self.personalRewards[self.personalRewardTier]
                local items = {}
                local count = param.itemGroupConfig:ItemGroupInfoListLength()
                for i = 1, count do
                    local itemGroup = param.itemGroupConfig:ItemGroupInfoList(i)
                    table.insert(items, {id = itemGroup:Items(), count = itemGroup:Nums()})
                end
                g_Game.UIManager:Open(UIMediatorNames.UIRewardMediator, {itemInfo = items})
                self:SetPersonalReward()
            end
        end)
    else
        -- tips
        local itemPram = {}
        local items = {}
        local param = self.personalRewards[self.personalRewardTier]
        for i = 1, param.itemGroupConfig:ItemGroupInfoListLength() do
            local itemGroup = param.itemGroupConfig:ItemGroupInfoList(i)
            table.insert(items, {itemId = itemGroup:Items(), itemCount = itemGroup:Nums()})
        end
        itemPram.listInfo = items
        itemPram.clickTrans = self.p_btn_score.gameObject.transform
        g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, itemPram)
    end
end

function ActivityWorldEvent:OnBtnClickAccept()
    ---@type CommonConfirmPopupMediatorParameter
    local confirmParameter = {}
    confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    confirmParameter.confirmLabel = I18N.Get("confirm")
    confirmParameter.cancelLabel = I18N.Get("cancle")
    confirmParameter.content = I18N.GetWithParams("alliance_worldevent_open_pop_second", ModuleRefer.AllianceModule:GetMyAllianceOnlineMemberCount())
    confirmParameter.title = I18N.Get("alliance_worldevent_chat_title")
    confirmParameter.onConfirm = function()
        self:OnBtnClickConfirm()
        g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonConfirmPopupMediator)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
end

function ActivityWorldEvent:OnBtnClickConfirm()
    local parameter = OpenAllianceExpeditionParameter.new()
    parameter.args.ConfigId = self.cfgId
    parameter.args.ExpeditionEntityId = self.ExpeditionEntityId
    parameter:SendOnceCallback(nil, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            local btnData = {}
            self.p_text_hint.text = I18N.Get("alliance_worldevent_big_tips_goto")
            btnData.onClick = Delegate.GetOrCreate(self, self.OnBtnClickGoto)
            btnData.buttonText = I18N.Get("worldevent_qianwang")
            self.child_comp_btn_b:SetEnabled(true)
            self.child_comp_btn_b:FeedData(btnData)
            self:SetAllianceReward()
            self:SetPersonalReward()
        end
    end)
end

function ActivityWorldEvent:OnBtnClickJoinAlliance()
    g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
end
function ActivityWorldEvent:OnBtnClickGoto()
    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        local callback = function()
            ModuleRefer.WorldEventModule:GotoAllianceExpedition(self.cfgId)
        end
        g_Game.UIManager:CloseAllByName(UIMediatorNames.EarthRevivalMediator)
        scene:LeaveCity(callback)
    else
        ModuleRefer.WorldEventModule:GotoAllianceExpedition(self.cfgId)
    end
end

function ActivityWorldEvent:OnBtnClickRepairAllianceCenter()
    ---@type AllianceTerritoryMainMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceTerritoryMainMediator, param)
end

function ActivityWorldEvent:OnBtnClickShowRank()
    -- 测试结算界面
    -- ModuleRefer.WorldEventModule:AllianceEventComplete(self.ExpeditionEntityId)
    local entity = g_Game.DatabaseManager:GetEntity(self.ExpeditionEntityId, DBEntityType.Expedition)
    g_Game.UIManager:Open(UIMediatorNames.ActivityWorldEventRankMediator, {ProgressList = entity.ExpeditionInfo.PersonalProgress})
end

function ActivityWorldEvent:onBtnClickPersonalPrompt()
    ---@type TextToastMediatorParameter
    local param = {}
    param.content = I18N.Get('alliance_worldevent_reward_desc1')
    param.clickTransform = self.p_btn_detail_1.gameObject.transform
    ModuleRefer.ToastModule:ShowTextToast(param)
end
function ActivityWorldEvent:onBtnClickAlliancePrompt()
    ---@type TextToastMediatorParameter
    local param = {}
    param.content = I18N.Get('alliance_worldevent_reward_desc2')
    param.clickTransform = self.p_btn_detail_2.gameObject.transform
    ModuleRefer.ToastModule:ShowTextToast(param)
end
return ActivityWorldEvent
