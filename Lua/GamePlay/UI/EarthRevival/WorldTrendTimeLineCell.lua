local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimeFormatter = require('TimeFormatter')
local UIHelper = require('UIHelper')
local WorldTrendDefine = require('WorldTrendDefine')
local EarthRevivalDefine = require('EarthRevivalDefine')
local UIMediatorNames = require("UIMediatorNames")
local ReceiveWorldStageRewardParameter = require("ReceiveWorldStageRewardParameter")
local TimerUtility = require("TimerUtility")
local ColorConsts = require("ColorConsts")

---@class WorldTrendTimeLineCell : BaseTableViewProCell
local WorldTrendTimeLineCell = class('WorldTrendTimeLineCell', BaseTableViewProCell)

---@class WorldTrendTimeLineCellParam
---@field stage number
---@field isOpen boolean
---@field lastStage number
---@field index number
---@field isLastShowStage boolean

function WorldTrendTimeLineCell:OnCreate()
    self.textStageNum = self:Text('p_text_number')
    self.goComplete = self:GameObject('p_complete')
    self.textComplete = self:Text('p_text_complete', "worldstage_wancheng")
    self.goIconNow = self:GameObject('p_icon_now')

    self.textStageName = self:Text('p_text_time')
    self.textFinishTime = self:Text('p_text_time_finish')

    self.goSystems = self:GameObject('p_systems')
    self.textSystemsTitle = self:Text('p_text_new_systems', "worldstage_xinxitong")
    self.tableviewproNewSystem = self:TableViewPro("p_table_systems")

    self.btnPhoto = self:Button('p_btn_photo', Delegate.GetOrCreate(self, self.OnClickPhoto))
    self.imgBackground_1 = self:Image('p_img_world_1')
    self.imgBackground_2 = self:Image('p_img_world_2')
    self.textStageDesc = self:Text('p_text_story')
    self.goPhoto = self:GameObject('photo')
    self.goPhotoChoose = self:GameObject('p_photo_choose')
    self.statusPhoto = self:StatusRecordParent("photo")

    self.goGroupInfo = self:GameObject('p_group_info')
    self.textTask = self:Text('p_text_task')
    self.tableviewproRewards = self:TableViewPro("p_table_rewards")
    self.compTableRewardCanvasGroup = self:BindComponent('p_table_rewards', typeof(CS.UnityEngine.CanvasGroup))
    self.goStatusClaim = self:GameObject('p_status_claim')
    self.btnClaim = self:Button('p_btn_claim', Delegate.GetOrCreate(self, self.OnClickClaim))
    self.goStatusLock = self:GameObject('p_status_lock')
    self.goStatusClaimed = self:GameObject('p_status_claimed')
    self.textStatusClaimed = self:Text('p_text_claimed', "worldstage_yilingqu")
    self.animReward = self:AnimTrigger('vx_trigger_reward')

    self.goTrends = self:GameObject("p_item_choose")
    self.textWorldTrendsTitle = self:Text('p_text_trends', "worldstage_fenzhi")
    self.btnWorldTrendDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnClickWorldTrendDetail))

    self.sliderBranch_1 = self:Slider("p_pb_01")
    self.goWin_1 = self:GameObject("p_icon_win_01")
    self.goLose_1 = self:GameObject("p_icon_lose_01")
    self.textBranchContent_1 = self:Text("p_text_answer_01")
    self.btnAnswer_1 = self:Button("p_btn_answer_01", Delegate.GetOrCreate(self, self.OnClickAnswer_1))
    self.btnReward_1 = self:Button("p_btn_reward_status_01", Delegate.GetOrCreate(self, self.OnClickRewardIcon_1))
    self.imgReward_1 = self:Image("p_icon_01")
    self.statusReward_1 = self:StatusRecordParent("p_trend_1")
    self.imgSlider_1 = self:Image("p_fill_01")

    self.sliderBranch_2 = self:Slider("p_pb_02")
    self.goWin_2 = self:GameObject("p_icon_win_02")
    self.goLose_2 = self:GameObject("p_icon_lose_02")
    self.textBranchContent_2 = self:Text("p_text_answer_02")
    self.btnAnswer_2 = self:Button("p_btn_answer_02", Delegate.GetOrCreate(self, self.OnClickAnswer_2))
    self.btnReward_2 = self:Button("p_btn_reward_status_02", Delegate.GetOrCreate(self, self.OnClickRewardIcon_2))
    self.imgReward_2 = self:Image("p_icon_02")
    self.statusReward_2 = self:StatusRecordParent("p_trend_2")
    self.imgSlider_2 = self:Image("p_fill_02")

    self.goLineLeft = self:GameObject("p_line_left")
    self.goLineRight = self:GameObject("p_line_right")
end

function WorldTrendTimeLineCell:OnShow()
end

function WorldTrendTimeLineCell:OnHide()
    -- if(self.SetStageDescSeq) then
    --     self.SetStageDescSeq:Kill()
    --     self.SetStageDescSeq = nil
    -- end
end

function WorldTrendTimeLineCell:OnClose()
    if(self.SetStageDescSeq) then
        self.SetStageDescSeq:Kill()
        self.SetStageDescSeq = nil
    end
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
        self.tickTimer = nil
    end
end

---@param param WorldTrendTimeLineCellParam
function WorldTrendTimeLineCell:OnFeedData(param)
    if not param then
        return
    end
    self.isOpen = param.isOpen
    self.curStage = param.stage
    self.lastStage = param.lastStage
    self.index = param.index
    self.isLastShowStage = param.isLastShowStage or false
    ---@type WorldStageConfigCell
    local stageConfig = ConfigRefer.WorldStage:Find(self.curStage)
    self.stageConfig = stageConfig
    if not stageConfig then
        return
    end
    self.goIconNow:SetActive(self.curStage == ModuleRefer.WorldTrendModule:GetCurStage().Stage)
    if self.isOpen then
        self:InitStageOpenCell()
    else
        self:InitStageCloseCell()
    end
end

function WorldTrendTimeLineCell:InitStageOpenCell()
    if not self.stageConfig then
        return
    end

    local stage = tonumber(self.stageConfig:Stage())

    self.textStageName.text = I18N.Get(self.stageConfig:Name())
    ---@type wds.WorldStageNode
    local curStageInfo = ModuleRefer.WorldTrendModule:GetStageInfo(self.curStage)
    if not curStageInfo then
        return
    end

    local startTime = curStageInfo.StartTime.Seconds
    local startTimeStr = TimeFormatter.TimeToDateTimeStringUseFormat(startTime, "MM.dd")
    self.textStageNum.text = startTimeStr

    local finishTime = curStageInfo.EndTime.Seconds
    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local isHistory = ModuleRefer.WorldTrendModule:IsHistoryStage(self.curStage)
    local isComplete = curTime >= finishTime or isHistory
    local finishTimeStr = nil
    self.textFinishTime.gameObject:SetActive(true)
    if isComplete then
        finishTimeStr = TimeFormatter.TimeToDateTimeStringUseFormat(finishTime, "yyyy.MM.dd HH:mm:ss")
        self.textFinishTime.text = I18N.GetWithParams("worldstage_jieshusj", finishTimeStr)
    else
        self.stageRemainTime = math.floor(finishTime - curTime)
        self.textFinishTime.text = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(self.stageRemainTime)
        if not self.tickTimer then
            self.tickTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.TickSecond), 1, -1)
        end
        self.goComplete:SetActive(false)
    end

    self.tableviewproNewSystem:Clear()
    if self.stageConfig:UnlockSystemsLength() > 0 then
        for i = 1, self.stageConfig:UnlockSystemsLength() do
            self.tableviewproNewSystem:AppendData(self.stageConfig:UnlockSystems(i))
        end
        self.textSystemsTitle:SetVisible(true)
        self.goSystems:SetActive(true)
    else
        self.goSystems:SetActive(false)
    end

    self.goPhoto:SetActive(true)
    self.goPhotoChoose:SetActive(false)
    self.statusPhoto:ApplyStatusRecord(0)
    if self.lastStage > 0 then
        local lastStageConfig = ConfigRefer.WorldStage:Find(self.lastStage)
        --上一阶段有分支
        if lastStageConfig and lastStageConfig:BranchesLength() > 1 and self.stageConfig:BranchKingdomTasksLength() > 1 then
            local lastBranchID_1, lastBranchID_2 = ModuleRefer.WorldTrendModule:GetGlobalBranchID(self.lastStage)
            if lastBranchID_1 == self.curStage then
                self.statusPhoto:ApplyStatusRecord(1)
            elseif lastBranchID_2 == self.curStage then
                self.statusPhoto:ApplyStatusRecord(2)
            end
        end
    end

    if self.stageConfig:StageBackgroundLength() > 0 then
        g_Game.SpriteManager:LoadSprite(self.stageConfig:StageBackground(1), self.imgBackground_1)
        self.imgBackground_1:SetVisible(true)
        self.imgBackground_2:SetVisible(false)
    end
    self.textStageDesc.text = I18N.Get(self.stageConfig:StageDesc())
    self:SetStageDesc()
    self.timelineCanOpen = true

    self.goGroupInfo:SetActive(true)
    local isTaskComplete = false
    if self.stageConfig:KingdomTasksLength() > 0 and self.stageConfig:KingdomTasks(1) then
        local taskStr = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(self.stageConfig:KingdomTasks(1))
        self.textTask.text = I18N.Get("worldstage_jieduanrw2")..taskStr
        local taskState = ModuleRefer.WorldTrendModule:GetKingdomTaskState(self.stageConfig:KingdomTasks(1))
        isTaskComplete = not taskState == wds.TaskState.TaskStateReceived
    else
        self.textTask.text = I18N.Get("worldstage_jieshulq")
        isTaskComplete = true
    end
    self:InitStageRewards()
    if isComplete then
        self.goComplete:SetActive(isTaskComplete)
    end

    if self.stageConfig:BranchKingdomTasksLength() > 1 then
        self.branchID_1, self.branchID_2 = ModuleRefer.WorldTrendModule:GetGlobalBranchID(self.curStage)
        self:InitBranchTask_1(self.stageConfig:BranchKingdomTasks(1), self.branchID_1)
        self:InitBranchTask_2(self.stageConfig:BranchKingdomTasks(2), self.branchID_2)
        self:BranchCompare()
        self.goTrends:SetActive(true)
        self.goLineLeft:SetActive(true)
        self.goLineRight:SetActive(isComplete)
    else
        self.goLineLeft:SetActive(false)
        self.goLineRight:SetActive(false)
        self.goTrends:SetActive(false)
    end
end

function WorldTrendTimeLineCell:InitStageCloseCell()
    if not self.stageConfig then
        return
    end
    local stage = tonumber(self.stageConfig:Stage())
    if stage < 10 then
        self.textStageNum.text = string.format("0%d", stage)
    else
        self.textStageNum.text = I18N.Get(self.stageConfig:Stage())
    end

    self.textFinishTime.gameObject:SetActive(false)
    self.textStageName.text = I18N.Get(self.stageConfig:Name())
    self.goComplete:SetActive(false)

    local lastStageConfig = ConfigRefer.WorldStage:Find(self.lastStage)
    local isLastStageOpen = ModuleRefer.WorldTrendModule:IsOpenStage(self.lastStage)
    -- if lastStageConfig and lastStageConfig:BranchesLength() > 1 or not isLastStageOpen then
    --     self.textStageName.text = I18N.Get("WorldStage_wenhao")
    -- else
    --     self.textStageName.text = I18N.Get(self.stageConfig:Name())
    -- end
    self.textStageName.text = I18N.Get("WorldStage_wenhao")

    self.tableviewproNewSystem:Clear()
    if self.stageConfig:UnlockSystemsLength() > 0 then
        for i = 1, self.stageConfig:UnlockSystemsLength() do
            self.tableviewproNewSystem:AppendData(self.stageConfig:UnlockSystems(i))
        end
        self.textSystemsTitle:SetVisible(true)
        self.goSystems:SetActive(true)
    else
        self.goSystems:SetActive(false)
    end

    -- local lastStageIsCurStage = ModuleRefer.WorldTrendModule:IsCurStage(self.lastStage)
    -- --上一阶段正在进行中且有分支
    if lastStageConfig and lastStageConfig:BranchesLength() > 1 then
        self.goPhoto:SetActive(false)
        self.goPhotoChoose:SetActive(true)
    else
        self.goPhoto:SetActive(true)
        self.statusPhoto:ApplyStatusRecord(0)
        self.goPhotoChoose:SetActive(false)
        if self.stageConfig:StageBackgroundLength() > 0 then
            g_Game.SpriteManager:LoadSprite(self.stageConfig:StageBackground(1), self.imgBackground_1)
            self.imgBackground_1:SetVisible(true)
            self.imgBackground_2:SetVisible(false)
        end
        self.textStageDesc.text = I18N.Get("WorldStage_wenhao")
    end
    self.timelineCanOpen = false

    self.goGroupInfo:SetActive(false)
    if self.stageConfig:BranchKingdomTasksLength() > 1 and not self.isLastShowStage then
        self:InitCloseBranchTask_1()
        self:InitCloseBranchTask_2()
        self.goTrends:SetActive(true)
        self.goLineLeft:SetActive(true)
        self.goLineRight:SetActive(false)
    else
        self.goLineLeft:SetActive(false)
        self.goLineRight:SetActive(false)
        self.goTrends:SetActive(false)
    end

    local startTime = ModuleRefer.WorldTrendModule:GetStageOpenTime(self.curStage)
    local startTimeStr = TimeFormatter.TimeToDateTimeStringUseFormat(startTime, "MM.dd")
    self.textStageNum.text = startTimeStr
end

function WorldTrendTimeLineCell:SetStageDesc()
    if(self.SetStageDescSeq) then
        self.SetStageDescSeq:Kill()
        self.SetStageDescSeq = nil
    end

    self.SetStageDescSeq = CS.DG.Tweening.DOTween.Sequence()
    self.SetStageDescSeq:InsertCallback(0.1, function()
        local fullText = I18N.Get(self.stageConfig:StageDesc())
        self.textStageDesc.text = fullText
        UIHelper.SetStringEllipsis(self.textStageDesc, fullText)
        -- self.textStageDescLong.text = fullText
    end
    )
end

function WorldTrendTimeLineCell:InitStageRewards()
    -- ModuleRefer.EarthRevivalModule:AttachToGroupMapRedDot(self.reddot.go)

    self.state = ModuleRefer.WorldTrendModule:GetStageState(self.curStage)
    local rewardList = ModuleRefer.QuestModule.GetItemGroupInfoById(self.stageConfig:Reward())
    if rewardList then
        self.tableviewproRewards:Clear()
        self.rewardData = {}
        for _, reward in ipairs(rewardList) do
            local data = {}
            data.configCell = ConfigRefer.Item:Find(reward:Items())
            data.count = reward:Nums()
            data.showTips = true
            data.received = self.state == WorldTrendDefine.BRANCH_STATE.Rewarded
            table.insert(self.rewardData, data)
            self.tableviewproRewards:AppendData(data)
        end
    end
    self:RefreshRewardStatus()
end

function WorldTrendTimeLineCell:RefreshRewardStatus()
    if not self.state then
        return
    end
    if self.state == WorldTrendDefine.BRANCH_STATE.CanReward then
        self.goStatusClaim:SetActive(true)
        self.goStatusLock:SetActive(false)
        self.goStatusClaimed:SetActive(false)
        ModuleRefer.WorldTrendModule:AddCanRewardStage(self.index)
        self.compTableRewardCanvasGroup.alpha = 1
        self.animReward:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    elseif self.state == WorldTrendDefine.BRANCH_STATE.Rewarded then
        self.goStatusClaim:SetActive(false )
        self.goStatusLock:SetActive(false)
        self.goStatusClaimed:SetActive(true)
        ModuleRefer.WorldTrendModule:RemoveCanRewardStage(self.index)
        self.compTableRewardCanvasGroup.alpha = 1
        self.animReward:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    else
        self.goStatusClaim:SetActive(false)
        self.goStatusLock:SetActive(true)
        self.goStatusClaimed:SetActive(false)
        self.compTableRewardCanvasGroup.alpha = 0.5
        self.animReward:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        -- self.reddot:SetVisible(false)
    end
end

function WorldTrendTimeLineCell:InitBranchTask_1(taskID, branchID)
    if not self.stageConfig then
        return
    end
    local config = ConfigRefer.WorldStage:Find(branchID)
    if not config then
        return
    end
    self.branchTaskID_1 = taskID
    local cur, total = ModuleRefer.WorldTrendModule:GetKingdomTaskSchedule(taskID)
    if total > 0 then
        self.branchProgress_1 = cur / total
    else
        self.branchProgress_1 = 0
    end
    self.sliderBranch_1.value = self.branchProgress_1
    self.textBranchContent_1.text = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(taskID)
    if not string.IsNullOrEmpty(config:BranchResultsIcon()) then
        self.imgReward_1:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(config:BranchResultsIcon(), self.imgReward_1)
    else
        self.imgReward_1:SetVisible(false)
    end
    self.rewardTips_1 = I18N.Get(config:BranchResultDesc())
    if config:BranchGuideDemo() > 0 then
        self.video1 = config:BranchGuideDemo()
    else
        self.video1 = nil
    end
    self.goWin_1:SetActive(false)
    self.goLose_1:SetActive(false)
    self.isCloseBranchTask_1 = false
end

function WorldTrendTimeLineCell:InitBranchTask_2(taskID, branchID)
    if not self.stageConfig then
        return
    end
    local config = ConfigRefer.WorldStage:Find(branchID)
    if not config then
        return
    end
    self.branchTaskID_2 = taskID
    local cur, total = ModuleRefer.WorldTrendModule:GetKingdomTaskSchedule(taskID)
    if total > 0 then
        self.branchProgress_2 = cur / total
    else
        self.branchProgress_2 = 0
    end
    self.sliderBranch_2.value = self.branchProgress_2
    self.textBranchContent_2.text = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(taskID)
    if not string.IsNullOrEmpty(config:BranchResultsIcon()) then
        g_Game.SpriteManager:LoadSprite(config:BranchResultsIcon(), self.imgReward_2)
    else
        self.imgReward_2:SetVisible(false)
    end
    self.rewardTips_2 = I18N.Get(config:BranchResultDesc())
    if config:BranchGuideDemo() > 0 then
        self.video2 = config:BranchGuideDemo()
    else
        self.video2 = nil
    end
    self.goWin_2:SetActive(false)
    self.goLose_2:SetActive(false)
    self.isCloseBranchTask_2 = false
end

function WorldTrendTimeLineCell:InitCloseBranchTask_1()
    self.sliderBranch_1.value = 0
    self.textBranchContent_1.text = I18N.Get("WorldStage_wenhao")
    self.rewardTips_1 = I18N.Get("WorldStage_wenhao")
    self.imgReward_1:SetVisible(false)
    self.goWin_1:SetActive(false)
    self.goLose_1:SetActive(false)
    self.isCloseBranchTask_1 = true
end

function WorldTrendTimeLineCell:InitCloseBranchTask_2()
    self.sliderBranch_2.value = 0
    self.textBranchContent_2.text = I18N.Get("WorldStage_wenhao")
    self.rewardTips_2 = I18N.Get("WorldStage_wenhao")
    self.imgReward_2:SetVisible(false)
    self.goWin_2:SetActive(false)
    self.goLose_2:SetActive(false)
    self.isCloseBranchTask_2 = true
end

function WorldTrendTimeLineCell:BranchCompare()
    local isComplete = ModuleRefer.WorldTrendModule:IsHistoryStage(self.curStage)
    if isComplete then
        local isBranch_1_Win = self.branchProgress_1 > self.branchProgress_2
        self.goWin_1:SetActive(isBranch_1_Win)
        self.goLose_1:SetActive(not isBranch_1_Win)
        self.goWin_2:SetActive(not isBranch_1_Win)
        self.goLose_2:SetActive(isBranch_1_Win)

        if isBranch_1_Win then
            self.imgSlider_1.color = UIHelper.TryParseHtmlString(EarthRevivalDefine.EarthRevivalMap_CompleteWinSliderColor)
            self.imgSlider_2.color = UIHelper.TryParseHtmlString(EarthRevivalDefine.EarthRevivalMap_CompleteLoseSliderColor)
            self.textBranchContent_2.color = UIHelper.TryParseHtmlString(ColorConsts.dark_gray)
            self.statusReward_1:ApplyStatusRecord(1)
            self.statusReward_2:ApplyStatusRecord(2)
        else
            self.imgSlider_1.color = UIHelper.TryParseHtmlString(EarthRevivalDefine.EarthRevivalMap_CompleteLoseSliderColor)
            self.imgSlider_2.color = UIHelper.TryParseHtmlString(EarthRevivalDefine.EarthRevivalMap_CompleteWinSliderColor)
            self.textBranchContent_1.color = UIHelper.TryParseHtmlString(ColorConsts.dark_gray)
            self.statusReward_1:ApplyStatusRecord(2)
            self.statusReward_2:ApplyStatusRecord(1)
        end
    else
        self.imgSlider_1.color = UIHelper.TryParseHtmlString(EarthRevivalDefine.EarthRevivalMap_ProcessingSliderColor)
        self.imgSlider_2.color = UIHelper.TryParseHtmlString(EarthRevivalDefine.EarthRevivalMap_ProcessingSliderColor)
        self.statusReward_1:ApplyStatusRecord(0)
        self.statusReward_2:ApplyStatusRecord(0)
        --未结束
        if self.branchProgress_1 < 1 and self.branchProgress_2 < 1 then
            return
        end
        local isBranch_1_Win = self.branchProgress_1 >= 1
        local isBranch_2_Win = self.branchProgress_2 >= 1
        self.goWin_1:SetActive(isBranch_1_Win)
        self.goLose_1:SetActive(not isBranch_1_Win)
        self.goWin_2:SetActive(isBranch_2_Win)
        self.goLose_2:SetActive(not isBranch_2_Win)
    end
end

function WorldTrendTimeLineCell:TickSecond()
    self:UpdateStageRemainTime()
end

function WorldTrendTimeLineCell:UpdateStageRemainTime()
    if not self.stageRemainTime or self.stageRemainTime < 0 then
        if self.tickTimer then
            TimerUtility.StopAndRecycle(self.tickTimer)
            self.tickTimer = nil
        end
        return
    end
    self.stageRemainTime = self.stageRemainTime - 1
    self.textFinishTime.text = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(self.stageRemainTime)
end

function WorldTrendTimeLineCell:OnClickPhoto()
    if not self.timelineCanOpen then
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.WorldTrendTimeLinePopupMediator, self.curStage)
end

function WorldTrendTimeLineCell:OnClickClaim()
    if not self.state then
        return
    end
    if self.state == WorldTrendDefine.BRANCH_STATE.CanReward then
        local parameter = ReceiveWorldStageRewardParameter.new()
        parameter.args.StageId = self.curStage
        parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
            if isSuccess then
                self:OnClaimReward()
            end
        end)
    end
end

function WorldTrendTimeLineCell:OnClickWorldTrendDetail()
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnWorldTrendDetail:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = I18N.Get("WorldStage_zoushism")
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function WorldTrendTimeLineCell:OnClickAnswer_1()
    if self.isCloseBranchTask_1 then
        return
    end
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnAnswer_1:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(self.branchTaskID_1)
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function WorldTrendTimeLineCell:OnClickAnswer_2()
    if self.isCloseBranchTask_2 then
        return
    end
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnAnswer_2:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(self.branchTaskID_2)
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function WorldTrendTimeLineCell:OnClickRewardIcon_1()
    if self.isCloseBranchTask_1 then
        return
    end
    local param = {}
    if self.video1 then
        param.pos = self.btnReward_1.gameObject.transform.position
        param.tips = self.rewardTips_1
        param.video = self.video1
        g_Game.UIManager:Open(UIMediatorNames.WorldTrendToastTextMediator, param)
    else
        param.clickTransform = self.btnReward_1:GetComponent(typeof(CS.UnityEngine.RectTransform))
        param.content = self.rewardTips_1
        ModuleRefer.ToastModule:ShowTextToast(param)
    end
end

function WorldTrendTimeLineCell:OnClickRewardIcon_2()
    if self.isCloseBranchTask_2 then
        return
    end
    local param = {}
    if self.video2 then
        param.pos = self.imgReward_2.gameObject.transform.position
        param.tips = self.rewardTips_2
        param.video = self.video2
        g_Game.UIManager:Open(UIMediatorNames.WorldTrendToastTextMediator, param)
    else
        param.clickTransform = self.btnReward_2:GetComponent(typeof(CS.UnityEngine.RectTransform))
        param.content = self.rewardTips_2
        ModuleRefer.ToastModule:ShowTextToast(param)
    end
end

function WorldTrendTimeLineCell:OnClaimReward()
    self.state = WorldTrendDefine.BRANCH_STATE.Rewarded
    self:RefreshRewardStatus()
    self:UpdateReward()
    ModuleRefer.EarthRevivalModule.taskModule:UpdateReddot()
    ModuleRefer.EarthRevivalModule:RefreshRedDot()
end

function WorldTrendTimeLineCell:UpdateReward()
    if self.rewardData then
        for k, v in ipairs(self.rewardData) do
            v.received = self.state == WorldTrendDefine.TASK_STATE.Rewarded
            self.tableviewproRewards:UpdateData(v)
        end
    end
end

return WorldTrendTimeLineCell