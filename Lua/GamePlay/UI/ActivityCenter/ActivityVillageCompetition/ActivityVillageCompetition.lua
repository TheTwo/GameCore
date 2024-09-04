---scene: scene_child_activity_city_competition
local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ActivityCategory = require("ActivityCategory")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local ConfigRefer = require("ConfigRefer")
local TaskItemDataProvider = require("TaskItemDataProvider")
local UIHelper = require("UIHelper")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local UIMediatorNames = require("UIMediatorNames")
local Utils = require("Utils")
local QualityColorHelper = require("QualityColorHelper")
---@class ActivityVillageCompetition : BaseUIComponent
local ActivityVillageCompetition = class("ActivityVillageCompetition", BaseUIComponent)

---@class ActivityVillageCompetitionData
---@field tabId number

function ActivityVillageCompetition:ctor()
    self.tabId = 0
    self.tick = false
    self.stage = nil
    self.isStageDirty = false
    ---@type TaskItemDataProvider
    self.taskProvider = nil
end

function ActivityVillageCompetition:OnCreate()
    self.btnRankReward = self:Button("p_btn_reward_rank", Delegate.GetOrCreate(self, self.OnClickRankReward))
    self.textBtnRankReward = self:Text("p_text_rank", "worldstage_city_competition_rankreward")
    self.imgRewardBase = self:Image("p_reward_pet")
    self.imgReward = self:Image("p_img_pet")

    self.textTime = self:Text("p_text_time")
    self.textTitle = self:Text("p_text_title", "worldstage_city_competition")
    self.textDesc = self:Text("p_text_describe", "worldstage_city_competition_des")

    self.textTimerLabel = self:Text("p_text_start", "city_competition_countdown")
    self.textTimer = self:Text("p_text_count_down")

    self.textTask = self:Text("p_text_task")
    self.tableReward = self:TableViewPro("p_table_award")

    self.textHint = self:Text("p_text_hint", "worldstage_city_competition_event_waiting")
    self.btnSearch = self:Button("p_btn_search", Delegate.GetOrCreate(self, self.OnClickSearch))
    self.textBtnSearch = self:Text("p_text_search", "city_competition_search_target_city")
    self.btnClaim = self:Button("p_btn_claimed", Delegate.GetOrCreate(self, self.OnClickClaim))
    self.textBtnClaim = self:Text("p_text_claimed", "city_competition_receive_award")

    self.textCityDesc = self:Text("p_text_city_desc", "city_competition_city_description")
    self.textCityName = self:Text("p_text_name")
    self.btnView = self:Button("p_btn_view", Delegate.GetOrCreate(self, self.OnClickView))

    self.imgVillage = self:Image("p_base_city")
    self.imgBackground = self:Image("p_base")
end

function ActivityVillageCompetition:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTimerTick))
end

function ActivityVillageCompetition:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTimerTick))
end

---@param param ActivityVillageCompetitionData
function ActivityVillageCompetition:OnFeedData(param)
    self.tabId = param.tabId
    self.tabCfg = ConfigRefer.ActivityCenterTabs:Find(self.tabId)
    self.actCfg = ConfigRefer.ActivityRewardTable:Find(self.tabCfg:RefActivityReward())
    if not self.actCfg then
        g_Logger.ErrorChannel("ActivityVillageCompetition", "未关联到ActivityRewardTable, 活动tabId: %d", self.tabId)
        return
    end
    self.cfg = ConfigRefer.CityCompetition:Find(self.actCfg:RefConfig())
    if not self.cfg then
        g_Logger.ErrorChannel("ActivityVillageCompetition", "未关联到CityCompetition, 活动tabId: %d", self.tabId)
        return
    end
    self.lvl = self.cfg:TargetLevel()
    self.tick = true
    self.taskProvider = TaskItemDataProvider.new(self.cfg:RelatedTask(), self.btnClaim.transform)
    self.taskProvider:SetClaimCallback(function ()
        self:UpdateBtns()
    end)

    local imgVillage = self.cfg:ImageCity()
    local imgBackground = self.cfg:ImageBase()

    if not Utils.IsNullOrEmpty(imgVillage) then
        self.imgVillage.gameObject:SetActive(true)
        g_Game.SpriteManager:LoadSprite(imgVillage, self.imgVillage)
    else
        self.imgVillage.gameObject:SetActive(false)
    end

    if not Utils.IsNullOrEmpty(imgBackground) then
        self.imgBackground.gameObject:SetActive(true)
        g_Game.SpriteManager:LoadSprite(imgBackground, self.imgBackground)
    else
        self.imgBackground.gameObject:SetActive(false)
    end

    self:UpdateStage()
    self:UpdateContent()
    self:UpdateRankReward()
    self:UpdateBtns()
    self:OnTimerTick()

    self.btnView.gameObject:SetActive(false)
    self.textCityName.gameObject:SetActive(false)
end

function ActivityVillageCompetition:UpdateStage()
    local category = ModuleRefer.ActivityCenterModule:GetActivityCategory(self.tabId)

    if self.isStageDirty then
        self.isStageDirty = category == self.stage
    end

    self.stage = category

    -- 按钮
    self:UpdateBtns()

    -- 倒计时
    if category == ActivityCategory.Hot then
        self.textTimerLabel.text = I18N.Get("city_competition_countdown")
    else
        self.textTimerLabel.text = I18N.Get("worldstage_city_competition_distance")
    end
end

function ActivityVillageCompetition:UpdateTime()
    local startTimeStamp, endTimeStamp
    for i = 1, self.tabCfg:CategoryLength() do
        local category = self.tabCfg:Category(i)
        if category == ActivityCategory.Preview then goto continue end
        local s, e = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByCategory(self.tabId, category)
        if not startTimeStamp then startTimeStamp = s end
        endTimeStamp = e
        ::continue::
    end
    local localStartTimeStr = TimeFormatter.TimeToLocalTimeZoneDateTimeStringUseFormat(startTimeStamp.Seconds, "yyyy-MM-dd HH:mm")
    local localEndTimeStr = TimeFormatter.TimeToLocalTimeZoneDateTimeStringUseFormat(endTimeStamp.Seconds, "yyyy-MM-dd HH:mm")
    self.textTime.text = I18N.GetWithParams("alliance_activity_pet_02", ("%s ~ %s"):format(localStartTimeStr, localEndTimeStr))
end

function ActivityVillageCompetition:UpdateContent()
    self.textTask.text = self.taskProvider:GetTaskStr()
    local rewards = self.taskProvider:GetTaskRewards()
    self.tableReward:Clear()
    for _, reward in ipairs(rewards) do
        self.tableReward:AppendData(reward)
    end
end

function ActivityVillageCompetition:UpdateRankReward()
    local rewardInfos = ModuleRefer.LeaderboardModule:GetActivityLeaderboardRankReward(self.cfg:RankTable())
    local rewardInfo = rewardInfos[1]
    if rewardInfo then
        local rewardCfg = rewardInfo.reward[1].configCell
        if rewardCfg then
            g_Game.SpriteManager:LoadSprite(rewardCfg:Icon(), self.imgReward)
            local quality = rewardCfg:Quality()
            local baseIcon = QualityColorHelper.GetQualityCircleBaseIcon(quality, QualityColorHelper.Type.Item)
            g_Game.SpriteManager:LoadSprite(baseIcon, self.imgRewardBase)
        end
    end
end

function ActivityVillageCompetition:UpdateBtns()
    local isInAlliance = ModuleRefer.AllianceModule:IsInAlliance()
    local isClaimed = self.taskProvider:GetTaskState() == wds.TaskState.TaskStateFinished
    local canClaim = self.taskProvider:GetTaskState() == wds.TaskState.TaskStateCanFinish
    local category = ModuleRefer.ActivityCenterModule:GetActivityCategory(self.tabId)
    self.btnClaim.gameObject:SetActive(isInAlliance and canClaim and category == ActivityCategory.Hot)
    self.btnSearch.gameObject:SetActive(true)
    self.textHint.gameObject:SetActive(category ~= ActivityCategory.Hot or isClaimed)
    if isInAlliance then
        self.textBtnSearch.text = I18N.Get("city_competition_search_target_city")
    else
        self.textBtnSearch.text = I18N.Get("city_competition_join")
    end

    if isClaimed then
        self.textHint.text = I18N.Get("city_competition_received")
    else
        self.textHint.text = I18N.Get("worldstage_city_competition_event_waiting")
    end
end

function ActivityVillageCompetition:OnTimerTick()
    if self.tick then
        local _, endTimeStamp = ModuleRefer.ActivityCenterModule:GetActivityTabStartEndTime(self.tabId)
        local now = g_Game.ServerTime:GetServerTimestampInSeconds()
        local time = math.clamp(endTimeStamp.Seconds - now, 0, math.huge)
        self.textTimer.text = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(time)

        if time <= 0 then
            self.tick = false
            self.isStageDirty = true
        end
    end

    if self.isStageDirty then
        self:UpdateStage()
    end
end

function ActivityVillageCompetition:OnClickRankReward()
    local tabs = {"sp_chat_icon_copy", "sp_mail_icon_gift", "sp_comp_icon_list"}
    local title = I18N.Get("alliance_WorldEvent_rule")

    local content1List = {}
    table.insert(content1List, { title = I18N.Get("worldstage_city_competition")})
    table.insert(content1List, { rule = I18N.Get("worldstage_city_competition_des")})
    ---@type CommonPlainTextContent
    local content1 = {list = content1List}
    
    local content2List = {}
    local rewardInfos = ModuleRefer.LeaderboardModule:GetActivityLeaderboardRankReward(self.cfg:RankTable())
    for _, rewardInfo in ipairs(rewardInfos) do
        local from = rewardInfo.from
        local to = rewardInfo.to
        local reward = rewardInfo.reward
        local rule = "city_competition_rank_num"
        if from == to then
            rule = I18N.GetWithParams(rule, from)
        elseif to > 0 then
            rule = I18N.GetWithParams(rule, ("%d-%d"):format(from, to))
        else
            rule = I18N.GetWithParams(rule, ("%d-"):format(from))
        end
        table.insert(content2List, { rule = rule})
        table.insert(content2List, { reward = reward})
    end
    ---@type CommonPlainTextContent
    local content2 = {list = content2List}
    
    local content3 = {leaderboardId = self.cfg:RankTable()}
    local data = {}
    data.tabs = tabs
    data.contents = { content1, content2, content3}
    data.title = I18N.Get("alliance_WorldEvent_rule")
    g_Game.UIManager:Open(UIMediatorNames.CommonPlainTextInfoMediator, data)
end

function ActivityVillageCompetition:OnClickSearch()
    local isInAlliance = ModuleRefer.AllianceModule:IsInAlliance()
    if not isInAlliance then
        ---@type CommonConfirmPopupMediatorParameter
        local data = {}
        data.title = I18N.Get("")
        data.content = I18N.Get("city_competition_tips_jion")
        data.confirmText = I18N.Get("city_competition_join")
        data.cancelText = I18N.Get("p_btn_cancel_lb")
        data.onConfirm = function ()
            if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.Global_alliance) then
                g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
            else
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("city_competition_unlock_alliance"))
            end
            return true
        end
        data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
    else
        local succ = ModuleRefer.ActivityVillageCompetitionModule:GotoNeareastVillageByLevel(self.lvl or 1)
        if succ then
            self:GetParentBaseUIMediator():CloseSelf()
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("city_competition_no_target"))
        end
    end
end

function ActivityVillageCompetition:OnClickClaim()
    self.taskProvider:OnClaim()
end

return ActivityVillageCompetition