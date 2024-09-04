---scene: scene_child_activity_landform
local BaseUIComponent = require("BaseUIComponent")
local ConfigRefer = require("ConfigRefer")
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local ActivityTimerHolder = require("ActivityTimerHolder")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local ActivityCategory = require("ActivityCategory")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local I18N = require("I18N")
local NotificationType = require("NotificationType")
---@class ActivityLandform : BaseUIComponent
local ActivityLandform = class("ActivityLandform", BaseUIComponent)

function ActivityLandform:ctor()
end

function ActivityLandform:OnCreate()
    self.statusCtrler = self:StatusRecordParent("p_status_content")
    -- 标题/描述/详情
    self.textTitle = self:Text("p_text_title", "landexplore_name")
    self.btnDetail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnDetailBtnClick))
    self.textDesc = self:Text("p_text_describe")

    -- 预告状态
    self.imgLandformPreview = self:Image("p_img_landform")
    self.textTimerLabel = self:Text("p_text_start", "landexplore_contant_opensoon")
    self.textTimerDayPreview = self:Text("p_text_count_down_1", "0d")
    self.textTimerHourPreview = self:Text("p_text_count_down_2", "00")
    self.textTimerMinutePreview = self:Text("p_text_count_down_3", "00")

    self.btnPreview = self:Button("child_comp_btn_a_l", Delegate.GetOrCreate(self, self.OnPreviewBtnClick))
    self.textBtnPreview = self:Text("p_text", "landexplore_btn_view_circles")

    -- 开启状态
    self.textTimerDayOpen = self:Text("p_text_count_down_4", "0d")
    self.textTimerHourOpen = self:Text("p_text_count_down_5", "00")
    self.textTimerMinuteOpen = self:Text("p_text_count_down_6", "00")

    self.imgLandformOpen = self:Image("p_img_landform_open")
    self.textView = self:Text("p_text_view", "landexplore_btn_view_circles")
    self.btnView = self:Button("p_btn_view", Delegate.GetOrCreate(self, self.OnViewBtnClick))

    self.sliderProgressScore = self:Slider("p_progress_score")
    self.textTotalScore = self:Text("p_text_total_score")

    self.luaItemTask = self:LuaBaseComponent("p_item_way")
    ---@type LuaReusedComponentPool
    self.poolItemTask = LuaReusedComponentPool.new(self.luaItemTask)

    self.tableReward = self:TableViewPro("p_table_reward")

    self.rectProgress = self:RectTransform("p_progress_score")

    self.luaReddot = self:LuaObject("child_reddot_default")
end

function ActivityLandform:OnShow()
    ---@type ActivityTimerHolder
    self.previewTimerHolder = ActivityTimerHolder.new(self.textTimerDayPreview, self.textTimerHourPreview, self.textTimerMinutePreview)
    self.previewTimerHolder:SetDisplayMode(ActivityTimerHolder.DisplayMode.Single)
    self.previewTimerHolder:Setup()

    ---@type ActivityTimerHolder
    self.openTimerHolder = ActivityTimerHolder.new(self.textTimerDayOpen, self.textTimerHourOpen, self.textTimerMinuteOpen)
    self.openTimerHolder:SetDisplayMode(ActivityTimerHolder.DisplayMode.Single)
    self.openTimerHolder:Setup()

    g_Game.EventManager:AddListener(EventConst.LAND_EXPLORE_REWARD_CLAIM, Delegate.GetOrCreate(self, self.UpdateProgress))
end

function ActivityLandform:OnHide()
    self.previewTimerHolder:Release()
    self.openTimerHolder:Release()

    self.previewTimerHolder = nil
    self.openTimerHolder = nil

    g_Game.EventManager:RemoveListener(EventConst.LAND_EXPLORE_REWARD_CLAIM, Delegate.GetOrCreate(self, self.UpdateProgress))
end

---@param data {tabId: number}
function ActivityLandform:OnFeedData(data)
    self.tabId = (data or {}).tabId
    self.tabCfg = ConfigRefer.ActivityCenterTabs:Find(self.tabId)
    self.actCfg = ConfigRefer.ActivityRewardTable:Find(self.tabCfg:RefActivityReward())
    if not self.actCfg then
        g_Logger.ErrorChannel("ActivityVillageCompetition", "未关联到ActivityRewardTable, 活动tabId: %d", self.tabId)
        return
    end
    self.cfg = ConfigRefer.LandExplore:Find(self.actCfg:RefConfig())
    if not self.cfg then
        g_Logger.ErrorChannel("ActivityVillageCompetition", "未关联到LandExplore, 活动tabId: %d", self.tabId)
        return
    end

    local stage = ModuleRefer.ActivityCenterModule:GetActivityCategory(self.tabId)
    if stage == ActivityCategory.Preview then
        self:ToPreviewStage()
    else
        self:ToOpenStage()
    end

    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(ModuleRefer.LandformTaskModule.NotifyActivityRootUniqueName, NotificationType.LANDFORM_TASK_MAIN)
    ModuleRefer.NotificationModule:AttachToGameObject(node, self.luaReddot.go, self.luaReddot.redDot)

    self:UpdateUI()
end

function ActivityLandform:UpdateUI()
    local landCfg = ModuleRefer.ActivityLandformModule:GetLandformCfg(self.cfg:Id())
    local landIcon = landCfg:Icon()
    -- 预告部分
    g_Game.SpriteManager:LoadSprite(landIcon, self.imgLandformPreview)

    -- 开启部分
    g_Game.SpriteManager:LoadSprite(landIcon, self.imgLandformOpen)
    self:UpdateProgress()
    self:UpdateScoreSourceCard()
    self.textDesc.text = I18N.GetWithParams("landexplore_contant", I18N.Get(landCfg:Name()))
end

function ActivityLandform:UpdateProgress()
    local progressWidth = self.rectProgress.rect.width
    local rewardLength = self.cfg:RewardItemGroupListLength()
    local numDivs = rewardLength
    local divProgress = 0.95 / numDivs
    local divWidth = progressWidth / numDivs
    local maxScore = math.floor(self.cfg:RewardScoreList(rewardLength))
    local normProgress = 0
    local curScore = ModuleRefer.ActivityLandformModule:GetCurScore(self.cfg:Id())
    local scoreList = {0}
    for i = 1, rewardLength do
        local score = self.cfg:RewardScoreList(i)
        table.insert(scoreList, score)
    end
    table.insert(scoreList, maxScore)
    for i = 2, rewardLength + 2 do
        local score = scoreList[i]
        if curScore < score then
            normProgress = ((curScore - scoreList[i - 1]) / (score - scoreList[i - 1])) * divProgress + normProgress
            break
        else
            normProgress = divProgress + normProgress
        end
    end
    self.sliderProgressScore.value = normProgress

    self.tableReward:Clear()
    for i = 1, rewardLength do
        ---@type ActivityLandformRewardCellData
        local data = {}
        data.index = i
        data.landExploreId = self.cfg:Id()
        data.posX = i * divWidth
        data.activityRewardId = self.actCfg:Id()
        self.tableReward:AppendData(data)
    end

    self.textTotalScore.text = curScore
end

function ActivityLandform:UpdateScoreSourceCard()
    self.poolItemTask:HideAll()
    local scoreSourceLength = self.cfg:ScoreSourceListLength()
    for i = 1, scoreSourceLength do
        ---@type ActivityLandformScoreSourceCardData
        local data = {}
        data.landExploreId = self.cfg:Id()
        data.landExploreScoreSourceId = self.cfg:ScoreSourceList(i)
        local item = self.poolItemTask:GetItem()
        item:FeedData(data)
    end
end

function ActivityLandform:ToPreviewStage()
    self:StartPreviewTimer()
    self.openTimerHolder:StopTick()
    self.statusCtrler:ApplyStatusRecord(1)
end

function ActivityLandform:ToOpenStage()
    self:StartOpenTimer()
    self.previewTimerHolder:StopTick()
    self.statusCtrler:ApplyStatusRecord(0)
end

function ActivityLandform:StartPreviewTimer()
    local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityTabStartEndTime(self.tabId)
    self.previewTimerHolder:StartTick(endTime.Seconds)
    self.previewTimerHolder:OnTick()
end

function ActivityLandform:StartOpenTimer()
    local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityTabStartEndTime(self.tabId)
    self.openTimerHolder:StartTick(endTime.Seconds)
    self.openTimerHolder:OnTick()
end

function ActivityLandform:ShowLandInfo()
    local landCfgId = self.cfg:LandType()
    ---@type LandformIntroUIMediatorParam
    local data = {}
    data.entryLandCfgId = landCfgId
    g_Game.UIManager:Open(UIMediatorNames.LandformIntroUIMediator, data)
end

function ActivityLandform:OnPreviewBtnClick()
    self:ShowLandInfo()
end

function ActivityLandform:OnViewBtnClick()
    self:ShowLandInfo()
end

function ActivityLandform:OnDetailBtnClick()
    ModuleRefer.ToastModule:SimpleShowTextToastTip(I18N.Get("landexplore_content_tutorial"), self.btnDetail.transform)
end

return ActivityLandform