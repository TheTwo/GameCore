local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local TimerUtility = require('TimerUtility')
local NoviceConst = require('NoviceConst')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local ProtocolId = require('ProtocolId')
local DBEntityPath = require('DBEntityPath')
local UIHelper = require('UIHelper')
local FunctionClass = require('FunctionClass')
local UIMediatorNames = require('UIMediatorNames')
local TaskListSortHelper = require('TaskListSortHelper')
---@class NoviceTaskMediator : BaseUIMediator
local NoviceTaskMediator = class('NoviceTaskMediator', BaseUIMediator)
---@sence scene_novice_task_list

local PAGE_SCROLL_INTERVAL = 10 -- seconds

local TabBottomTexts = NoviceConst.I18NKeys.TABS

local TaskDescTexts = NoviceConst.I18NKeys.TASK_TITLES

local TVImgs = {
    'sp_activity_novice_base_tv_01',
    'sp_activity_novice_base_tv_01',
    'sp_activity_novice_base_tv_01',
    'sp_activity_novice_base_tv_02',
    'sp_activity_novice_base_tv_03',
}

local TVVxType = {
    CS.FpAnimation.CommonTriggerType.Custom1,
    CS.FpAnimation.CommonTriggerType.Custom1,
    CS.FpAnimation.CommonTriggerType.Custom1,
    CS.FpAnimation.CommonTriggerType.Custom2,
    CS.FpAnimation.CommonTriggerType.Custom3,
}

local RewardProcessUpdateFrom = {
    Manual = 1,
    ServerCallback = 2,
}

local TableTaskCellType = {
    TextCell = 0,
    ItemCell = 1,
}

function NoviceTaskMediator:ctor()
    self.curPageIndex = 0
    self.pageScrollTimer = nil
    self.tabDay = 1
    self.tabTypeIndex = 1
    self.actCfg = nil
    self.rewardTypes = nil
    self.rewardOpenStateCache = nil
    self.scrollPage2SpIndex = nil
    self.isTaskProcessDirty = false
end

function NoviceTaskMediator:OnCreate()
    self.pageviewcontrollerScroll = self:BindComponent('p_scroll', typeof(CS.PageViewController))
    self.curPageIndex = 0
    self:DragEvent('p_scroll', Delegate.GetOrCreate(self, self.OnBeginDrag), nil, Delegate.GetOrCreate(self, self.OnEndDrag))
    self.pageScrollTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.AutoScrollPage),
                                                        PAGE_SCROLL_INTERVAL, -1)

    --- group left ---

    self.pageNum = ModuleRefer.NoviceModule:GetSpecialRewardNum()
    self.pageTemplate = self:LuaBaseComponent('p_page')
    self.pages = {self.pageTemplate}

    self.pageviewcontrollerScroll.pageCount = self.pageNum

    self.scrollDotTemplate = self:LuaBaseComponent('p_dot')
    self.scrollDots = {self.scrollDotTemplate}

    for i = 2, self.pageNum do
        self.pages[i] = UIHelper.DuplicateUIComponent(self.pageTemplate)
        self.scrollDots[i] = UIHelper.DuplicateUIComponent(self.scrollDotTemplate)
    end

    self.tableReward = self:TableViewPro('p_table_reward')
    self.rectTableReward = self:RectTransform('p_table_reward')
    self.textProgressReward = self:Text('p_text_progress_reward', NoviceConst.I18NKeys.REWARD_TIP)
    self.sliderProgress = self:Slider('p_progress')
    self.rectProgress = self:RectTransform('p_progress')
    self.textScore = self:Text('p_text_lv')

    self.imgTv = self:Image('p_img_tv')

    --- end of group left ---
    --- group right ---

    self.textTask = self:Text('p_text_task')
    self.textTimeActivity = self:Text('p_text_time_activity')

    self.btnInfo = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnInfoClicked))

    self.tableTask = self:TableViewPro('p_table_task')

    self.tableBottom = self:TableViewPro('p_table_bottom')
    self.tableSubTabs = self:TableViewPro('p_table_tab_2')

    --- end of group right ---

    self.btnBack = self:LuaObject('child_common_btn_back')
    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

function NoviceTaskMediator:OnOpened()

end

function NoviceTaskMediator:OnShow()
    self.pageviewcontrollerScroll.onPageChanged = Delegate.GetOrCreate(self, self.OnPageChanged)
    self.pageviewcontrollerScroll.onPageChanging = Delegate.GetOrCreate(self, self.OnPageChanged)
    self.btnBack:FeedData({
        title = I18N.Get(NoviceConst.I18NKeys.TITLE),
        backBtnFunc = Delegate.GetOrCreate(self, self.OnBtnExitClicked)}
    )
    self.tabDay = math.min(self:GetThisDay(), NoviceConst.MAX_DAY)
    self.actCfg = ConfigRefer.ActivityReward:Find(NoviceConst.ActivityId)
    self.rewardTypes = ModuleRefer.NoviceModule:GetRewardTypes()
    self.rewardOpenStateCache = ModuleRefer.NoviceModule:GetAllRewardOpenStatusCache()
    self.scrollPage2SpIndex = {}
    local j = 1
    for i, rewardType in ipairs(self.rewardTypes) do
        if rewardType == NoviceConst.RewardType.High then
            self.scrollPage2SpIndex[j] = i
            j = j + 1
        end
    end

    for i = 1, self.pageNum do
        local param = {}
        param.spIndex = self.scrollPage2SpIndex[i]
        param.score = self.actCfg:RewardRequireItemCount(param.spIndex)
        self.pages[i]:FeedData(param)
    end

    self:UpdateDateList()
    self:UpdateTabTypeList()
    self:UpdateLeftTime()
    self:UpdateRewardProgress(RewardProcessUpdateFrom.Manual)
    self:SetTVImg(self.curPageIndex + 1)
    self:SetScrollDotsShow(self.curPageIndex + 1)

    g_Game.EventManager:AddListener(EventConst.ON_SELECT_NOVICE_TASK_TAB, Delegate.GetOrCreate(self, self.OnTaskTabClicked))
    g_Game.EventManager:AddListener(EventConst.ON_SELECT_NOVICE_TASK_SUB_TAB, Delegate.GetOrCreate(self, self.OnTaskSubTabClicked))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.ReceiveActivityReward, Delegate.GetOrCreate(self, self.OnReceiveActivityReward))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerActivityReward.Data.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerActivityRewardChange))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.SetTaskProcessDirty))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TaskProcessSecondTicker))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.UpdateLeftTime))
    ModuleRefer.InventoryModule:AddCountChangeListener(ModuleRefer.NoviceModule:GetScoreItemId(), Delegate.GetOrCreate(self, self.UpdateRewardProgress))
end

function NoviceTaskMediator:OnHide()
    TimerUtility.StopAndRecycle(self.pageScrollTimer)
    self.pageviewcontrollerScroll.onPageChanged = nil
    self.pageviewcontrollerScroll.onPageChanging = nil

    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_NOVICE_TASK_TAB, Delegate.GetOrCreate(self, self.OnTaskTabClicked))
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_NOVICE_TASK_SUB_TAB, Delegate.GetOrCreate(self, self.OnTaskSubTabClicked))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.ReceiveActivityReward, Delegate.GetOrCreate(self, self.OnReceiveActivityReward))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerActivityReward.Data.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerActivityRewardChange))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.SetTaskProcessDirty))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TaskProcessSecondTicker))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.UpdateLeftTime))
    ModuleRefer.InventoryModule:RemoveCountChangeListener(ModuleRefer.NoviceModule:GetScoreItemId(), Delegate.GetOrCreate(self, self.UpdateRewardProgress))
end

function NoviceTaskMediator:GetThisDay()
    return ModuleRefer.NoviceModule:GetCurrentDay()
end

function NoviceTaskMediator:UpdateLeftTime()
    local totalTimeSec = self.actCfg:LastTime() / 1e9
    local startTimeSec = ModuleRefer.NoviceModule:GetOpenTime()
    local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    local leftTimeSec = math.floor(totalTimeSec - (curTimeSec - startTimeSec))
    leftTimeSec = math.max(0, leftTimeSec)
    local d = leftTimeSec // 86400
    local h = leftTimeSec % 86400 // 3600
    local m = leftTimeSec % 3600 // 60
    local s = leftTimeSec % 60
    self.textTimeActivity.text = I18N.GetWithParamList(NoviceConst.I18NKeys.TIME, {d, string.format('%02d:%02d:%02d', h, m, s)})
end

--- 任务列表部分 ---

function NoviceTaskMediator:SetTaskProcessDirty()
    self.isTaskProcessDirty = true
end

function NoviceTaskMediator:TaskProcessSecondTicker()
    if self.isTaskProcessDirty then
        self.isTaskProcessDirty = false
        self:UpdateTaskList()
    end
end

function NoviceTaskMediator:UpdateTaskList(day, type)
    if day then self.tabDay = day end
    if type then self.tabTypeIndex = type end
    local taskIds = ModuleRefer.NoviceModule:GetTaskIdListByDayAndType(self.tabDay, self.tabTypeIndex)
    TaskListSortHelper.Sort(taskIds)
    self.tableTask:Clear()
    for _, taskId in ipairs(taskIds) do
        self.tableTask:AppendData({taskId = taskId}, TableTaskCellType.TextCell)
        self.tableTask:AppendData({taskId = taskId}, TableTaskCellType.ItemCell)
    end
end

function NoviceTaskMediator:UpdateDateList()
    self.tableBottom:Clear()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local curOpenTaskList = player.PlayerWrapper2.PlayerActivityReward.Data[NoviceConst.ActivityId].CurOpenTaskList
    for i = 1, NoviceConst.MAX_DAY do
        local data = {}
        data.day = i
        data.thisDay = self.tabDay
        data.isLocked = i - 1 > curOpenTaskList
        data.textI18N = TabBottomTexts[i]
        self.tableBottom:AppendData(data)
    end
end

function NoviceTaskMediator:UpdateTabTypeList()
    self.tableSubTabs:Clear()
    for i = 1, NoviceConst.MaxSubTabCount do
        ---@type NoviceTaskSubTabCellData
        local data = {}
        data.index = i
        data.selected = i == self.tabTypeIndex
        data.day = self.tabDay
        self.tableSubTabs:AppendData(data)
    end
end

--- end of 任务列表部分 ---

--- 奖励进度条部分 ---


---@param callFrom RewardProcessUpdateFrom 主要用于解决，策划把积分道具配到宝箱里时，会出现异步冲突导致动画失效的问题
function NoviceTaskMediator:UpdateRewardProgress(callFrom)
    local curScore = self:GetCurrentScore()
    local maxScore = self.actCfg:RewardRequireItemCount(self.actCfg:RewardNormalLength())
    local progressBarWidth = self.rectProgress.rect.width
    local tableWidth = self.rectTableReward.rect.width
    local tableStart = self.tableReward.gameObject.transform.anchoredPosition.x - tableWidth / 2
    local progressStart = self.sliderProgress.gameObject.transform.anchoredPosition.x
    local deltaX = progressStart - tableStart
    local startPosX = deltaX
    self.textScore.text = tostring(curScore)
    self.sliderProgress.value = curScore / maxScore
    self.tableReward:Clear()
    for i = 1, self.actCfg:RewardNormalLength() do
        local data = {}
        data.index = i
        data.score = self.actCfg:RewardRequireItemCount(i)
        data.type = self.rewardTypes[i]
        data.rewardId = self.actCfg:RewardNormal(i)
        data.shouldPlayAnim = false
        data.pos = startPosX + progressBarWidth * data.score / maxScore
        if callFrom then
            data.shouldPlayAnim = self.rewardOpenStateCache[i] ~= ModuleRefer.NoviceModule:GetRewardOpenStatus(i)
            self.rewardOpenStateCache[i] = ModuleRefer.NoviceModule:GetRewardOpenStatus(i)
            if data.shouldPlayAnim then
                self:ShowHeroGet(data.rewardId)
            end
        end
        self.tableReward:AppendData(data)
    end
end

function NoviceTaskMediator:GetCurrentScore()
    local scoreId = ModuleRefer.NoviceModule:GetScoreItemId()
    local score = ModuleRefer.InventoryModule:GetAmountByConfigId(scoreId)
    return score
end

function NoviceTaskMediator:ShowHeroGet(rewardId)
    local rewardGroup = ConfigRefer.ItemGroup:Find(rewardId)
    local itemId = rewardGroup:ItemGroupInfoList(1):Items()
    if ConfigRefer.Item:Find(itemId):FunctionClass() == FunctionClass.AddHero then
        local heroId = tonumber(ConfigRefer.Item:Find(itemId):UseParam(1))
        g_Game.UIManager:Open(UIMediatorNames.UIOneDaySuccessMediator, {heroId = heroId})
    end
end

function NoviceTaskMediator:GetItemPos()
    local offset = self.sliderProgress.value * self.rectProgress.rect.width
    local uiCamera = g_Game.UIManager:GetUICamera()
    local startUIPos = UIHelper.WorldPos2UIPos(uiCamera, self.sliderProgress.gameObject.transform.position)
    local uiPos = CS.UnityEngine.Vector3(startUIPos.x + offset, startUIPos.y, startUIPos.z)
    local screenPos = UIHelper.UIPos2ScreenPos(uiPos)
    local worldPos = uiCamera:ScreenToWorldPoint(screenPos)
    return worldPos
end

--- end of 奖励进度条部分 ---

--- 滚动展示部分 ---

function NoviceTaskMediator:SetScrollDotsShow(showDotsIndex)
    for i = 1, self.pageNum do
        self.scrollDots[i].Lua:SetDotVisible(i == showDotsIndex)
    end
end

function NoviceTaskMediator:AutoScrollPage()
    local page = self.curPageIndex
    local pageCount = self.pageviewcontrollerScroll.pageCount
    local newPage = (page + 1) % pageCount
    self.pageviewcontrollerScroll:ScrollToPage(newPage)
    self:OnPageChanged(nil, newPage)
end

function NoviceTaskMediator:OnPageChanged(_, newPageIndex)
    self.curPageIndex = newPageIndex
    self:SetScrollDotsShow(newPageIndex + 1)
    self:SetTVImg(newPageIndex + 1)
end

function NoviceTaskMediator:OnBeginDrag()
    self.pageScrollTimer:Reset(Delegate.GetOrCreate(self, self.AutoScrollPage),
                            PAGE_SCROLL_INTERVAL, -1)
end

function NoviceTaskMediator:OnEndDrag()
    self.pageScrollTimer:Start()
end

function NoviceTaskMediator:SetTVImg(page)
    local index = self.scrollPage2SpIndex[page]
    local quality = ModuleRefer.NoviceModule:GetSpeicalRewardConfig(index):Quality()
    -- g_Game.SpriteManager:LoadSprite(TVImgs[quality], self.imgTv)
    self.vxTrigger:PlayAll(TVVxType[quality])
end

--- end of 滚动展示部分 ---

--- 回调 ---

function NoviceTaskMediator:OnBtnExitClicked(args)
    self:BackToPrevious()
end

function NoviceTaskMediator:OnBtnInfoClicked(args)
    ---@type TextToastMediatorParameter
    local param = {}
    param.content = I18N.Get('survival_rules_info')
    param.clickTransform = self.btnInfo.gameObject.transform
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function NoviceTaskMediator:OnReceiveActivityReward(isSuccess, _)
    if not isSuccess then
        return
    end
    self:UpdateRewardProgress(RewardProcessUpdateFrom.ServerCallback)
end

function NoviceTaskMediator:OnPlayerActivityRewardChange(_, changedTable)
    local changedAct = changedTable[NoviceConst.ActivityId]
    if changedAct and table.ContainsKey(changedAct, 'CurOpenTaskList') then
        self:UpdateDateList()
    end
end

function NoviceTaskMediator:OnTaskTabClicked(day, type)
    self:UpdateTaskList(day, type)
    self:UpdateTabTypeList()
end

function NoviceTaskMediator:OnTaskSubTabClicked(day, type)
    self:UpdateTaskList(day, type)
end

return NoviceTaskMediator