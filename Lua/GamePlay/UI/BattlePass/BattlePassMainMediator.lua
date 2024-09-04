local BaseUIMediator = require("BaseUIMediator")
local I18N = require("I18N")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local BattlePassConst = require("BattlePassConst")
local DBEntityPath = require("DBEntityPath")
local TimerUtility = require("TimerUtility")
local UIHelper = require("UIHelper")
local PlayerTaskOperationParameter = require("PlayerTaskOperationParameter")
local EventConst = require("EventConst")
local OnChangeHelper = require("OnChangeHelper")
local NotificationType = require("NotificationType")
local TimeFormatter = require("TimeFormatter")
local ActivityRewardType = require("ActivityRewardType")
---@class BattlePassMainMediator:BaseUIMediator
local BattlePassMainMediator = class("BattlePassMainMediator", BaseUIMediator)
---@sence scene_battlepass_main

local TAB_TYPES = {
    TASK = 1,
    REWARD = 2,
}

local UPDATE_MASK = {
    PROGRESS = 1,
    BTNS = 1 << 1,
    ALL = 0xFFFF,
}

local PAGE_SCROLL_INTERVAL = 5 -- seconds
local I18N_KEYS = BattlePassConst.I18N_KEYS

function BattlePassMainMediator:OnCreate()
    self.pageviewcontrollerScroll = self:BindComponent('p_scroll', typeof(CS.PageViewController))
    self.rectScroll = self:RectTransform('p_scroll')
    self.curPageIndex = 0
    self:DragEvent('p_scroll', Delegate.GetOrCreate(self, self.OnBeginDrag), nil, Delegate.GetOrCreate(self, self.OnEndDrag))

    self.pageTemplate = self:LuaBaseComponent('p_page')
    self.scrollDotTemplate = self:LuaBaseComponent('p_dot')

    -- group tab
    self.btnTask = self:Button('p_btn_task', Delegate.GetOrCreate(self, self.OnBtnTaskClicked))
    self.goBtnTaskSelected = self:GameObject('p_img_sclect_task')
    self.textTaskSelect = self:Text('p_text_task_select', I18N_KEYS.TAB_TASK_TITLE)
    self.textTask = self:Text('p_text_task_n', I18N_KEYS.TAB_TASK_TITLE)
    self.reddotTask = self:LuaObject('child_reddot_default_task')

    self.btnReward = self:Button('p_btn_reward', Delegate.GetOrCreate(self, self.OnBtnRewardClicked))
    self.goBtnRewardSelected = self:GameObject('p_img_sclect_reward')
    self.textRewardSelect = self:Text('p_text_task_reward', I18N_KEYS.TAB_REWARD_TITLE)
    self.textReward = self:Text('p_text_reward_n', I18N_KEYS.TAB_REWARD_TITLE)
    self.reddotReward = self:LuaObject('child_reddot_default_reward')

    -- left group
    self.pageViewController = self:BindComponent('p_scroll', typeof(CS.PageViewController))
    self.textHint = self:Text('p_text_hint')

    -- right group
    --- level
    self.textLevel = self:Text('p_text_level')
    self.progressBarExp = self:Slider('p_progress')
    self.rectProgress = self:RectTransform('p_progress')
    self.luaBtnPurchaseLvl = self:LuaObject('p_btn_purchase_level')
    self.textExp = self:Text('p_text_exp', 'p_text_exp')
    self.textExpLimit = self:Text('p_text_exp_limit', I18N_KEYS.WEEKLY_LIMIT)

    --- Reward & Task
    self.luaReward = self:LuaObject('p_reward')
    self.luaTask = self:LuaObject('p_task')

    --- btn
    self.btnUnlockAdvancedReward = self:Button('p_btn_purchase_better', Delegate.GetOrCreate(self, self.OnBtnUnlockAdvancedRewardClicked))
    self.textUnlockAdvancedReward = self:Text('p_text_e', I18N_KEYS.PAY_BTN)
    self.btnRechargePoints = self:Button('p_btn_recharge_points')

    self.luaBtnClaimAll = self:LuaObject('child_comp_btn_b')

    self.statusCtrlerBtnClaimAll = self:StatusRecordParent('child_comp_btn_b')
    self.goVxBtnClaimAll = self:GameObject('vfx_effect_btn_liuguang_long')

    --- top
    self.btnDetail = self:Button('p_btn_detail')
    self.textTimeTitle = self:Text('p_text_remaining_time', I18N_KEYS.REMAIN_TIME_TXT)
    self.textTimeNum = self:Text('p_text_time', I18N_KEYS.REMAIN_TIME)

    -- back
    self.luaBtnBack = self:LuaObject('child_common_btn_back')

    self.tabCtrler = {
        [TAB_TYPES.TASK] = {
            goSelected = self.goBtnTaskSelected,
            goUnselected = self.textTask.gameObject,
            page = self.luaTask,
        },
        [TAB_TYPES.REWARD] = {
            goSelected = self.goBtnRewardSelected,
            goUnselected = self.textReward.gameObject,
            page = self.luaReward,
        },
    }
end

function BattlePassMainMediator:SwitchToTab(tabType)
    self.tabType = tabType
    for k, v in pairs(self.tabCtrler) do
        v.goSelected:SetActive(k == tabType)
        v.page:SetVisible(k == tabType)
        v.goUnselected:SetActive(k ~= tabType)
    end
    self:UpdateData({
        updateMask = UPDATE_MASK.BTNS,
    })
end

function BattlePassMainMediator:OnShow(param)
    self.cfgId = ModuleRefer.BattlePassModule:GetCurOpeningBattlePassId()
    self.pageLength = #ModuleRefer.BattlePassModule:GetDisplayRewardIndex(self.cfgId)
    self.pageNum = self.pageLength
    self.pageTemplate:SetVisible(true)
    self.scrollDotTemplate:SetVisible(true)
    self.pages = {}
    self.scrollDots = {}
    self.haveClaimed = false
    for i = 1, self.pageLength do
        self.pages[i] = UIHelper.DuplicateUIComponent(self.pageTemplate)
        self.scrollDots[i] = UIHelper.DuplicateUIComponent(self.scrollDotTemplate)
    end

    self.pageTemplate:SetVisible(false)
    self.scrollDotTemplate:SetVisible(false)

    self.pageviewcontrollerScroll.onPageChanged = Delegate.GetOrCreate(self, self.OnPageChanged)
    self.pageviewcontrollerScroll.onPageChanging = Delegate.GetOrCreate(self, self.OnPageChanged)

    local hasTaskNotify = ModuleRefer.BattlePassModule:IsAnyTaskRewardCanClaim(self.cfgId)
    if hasTaskNotify then
        self:SwitchToTab(TAB_TYPES.TASK)
    else
        self:SwitchToTab(TAB_TYPES.REWARD)
    end

    self.luaBtnPurchaseLvl:FeedData({
        buttonText = I18N.Get(I18N_KEYS.BUY_LVL),
        disableButtonText = I18N.Get(I18N_KEYS.LVL_MAX),
        onClick = Delegate.GetOrCreate(self, self.OnBtnPurchaseLvlClicked),
    })

    self.luaBtnClaimAll:FeedData({
        buttonText = I18N.Get(I18N_KEYS.CLAIM_ALL),
        onClick = Delegate.GetOrCreate(self, self.OnBtnClaimAllClicked),
        onPressDown = Delegate.GetOrCreate(self, self.OnBtnClaimAllPressDown),
        onPressUp = Delegate.GetOrCreate(self, self.OnBtnClaimAllPressUp),
    })

    self:UpdateData({
        updateMask = UPDATE_MASK.ALL,
    })
    -- self.btnRechargePoints.gameObject:SetActive(false)

    self.pageScrollTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.AutoScrollPage),
                                                        PAGE_SCROLL_INTERVAL, -1)

    self.luaBtnBack:FeedData(
        {title = I18N.Get(I18N_KEYS.TITLE),}
    )

    self:SetScrollDotsShow(self.curPageIndex + 1)
    for i = 1, self.pageNum do
        local data = {}
        -- data.nodeIndex = ModuleRefer.BattlePassModule:GetDisplayRewardIndex(self.cfgId)[i]
        data.itemId = ModuleRefer.BattlePassModule:GetDisplayRewardItems(self.cfgId)[i] or 0
        self.pages[i]:FeedData(data)
    end

    local taskNotifyNode = ModuleRefer.NotificationModule:GetDynamicNode(
        BattlePassConst.NOTIFY_NAMES.TASK, NotificationType.BATTLEPASS_TASK)
    ModuleRefer.NotificationModule:AttachToGameObject(taskNotifyNode, self.reddotTask.go, self.reddotTask.redDot)

    local rewardNotifyNode = ModuleRefer.NotificationModule:GetDynamicNode(
        BattlePassConst.NOTIFY_NAMES.REWARD, NotificationType.BATTLEPASS_REWARD)
    ModuleRefer.NotificationModule:AttachToGameObject(rewardNotifyNode, self.reddotReward.go, self.reddotReward.redDot)
    self:SecondTicker()

    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath, Delegate.GetOrCreate(self, self.OnDataChanged))
    g_Game.EventManager:AddListener(EventConst.BATTLEPASS_TASK_REWARD_CLAIM, Delegate.GetOrCreate(self, self.OnClaimTaskReward))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecondTicker))
end

function BattlePassMainMediator:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath, Delegate.GetOrCreate(self, self.OnDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.BATTLEPASS_TASK_REWARD_CLAIM, Delegate.GetOrCreate(self, self.OnClaimTaskReward))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondTicker))

    TimerUtility.StopAndRecycle(self.pageScrollTimer)
    self.pageScrollTimer = nil
    self.pageviewcontrollerScroll.onPageChanged = nil
    self.pageviewcontrollerScroll.onPageChanging = nil

    for i = 1, self.pageLength do
        UIHelper.DeleteUIComponent(self.pages[i])
        UIHelper.DeleteUIComponent(self.scrollDots[i])
    end

    if self.vxTimer then
        TimerUtility.StopAndRecycle(self.vxTimer)
        self.vxTimer = nil
    end
end

function BattlePassMainMediator:SecondTicker()
    local remainTime = ModuleRefer.BattlePassModule:GetRemainTime(self.cfgId)
    local time = TimeFormatter.GetTimeTableInDHMS(remainTime)
    if time.day > 0 then
        self.textTimeNum.text = I18N.GetWithParams(BattlePassConst.I18N_KEYS.REMAIN_TIME_D_H, time.day, time.hour)
    else
        self.textTimeNum.text = I18N.GetWithParams(BattlePassConst.I18N_KEYS.REMAIN_TIME_H_M, time.hour, time.minute)
    end
end

function BattlePassMainMediator:OnDataChanged(_, changedTable)
    self:UpdateData({
        updateMask = UPDATE_MASK.ALL,
    })
    local actId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.BattlePass)
    local originalData = (changedTable.Remove or {})[actId].BattlePassParam
    local currentData = (changedTable.Add or {})[actId].BattlePassParam
    local openState = (changedTable.Add or {})[actId].Open
    if false == openState then
        self:CloseSelf()
        return
    end
    if originalData and currentData then
        local originalLevel = originalData.Level
        local currentLevel = currentData.Level
        if originalLevel ~= currentLevel then
            g_Game.UIManager:Open(UIMediatorNames.BattlePassLvlUpMediator, {
                originalLvl = originalLevel,
                currentLvl = currentLevel,
            })
        end
    end
end

function BattlePassMainMediator:OnClaimTaskReward()
    self:UpdateData({
        updateMask = UPDATE_MASK.BTNS,
    })
end

function BattlePassMainMediator:UpdateData(param)
    local updateMask = param.updateMask
    if updateMask & UPDATE_MASK.PROGRESS ~= 0 then
        self:UpdateProgress()
    end
    if updateMask & UPDATE_MASK.BTNS ~= 0 then
        self:UpdateBtns()
    end
end

function BattlePassMainMediator:UpdateProgress()
    local curLevel = ModuleRefer.BattlePassModule:GetLevelByCfgId(self.cfgId)
    local exp = ModuleRefer.BattlePassModule:GetExpByCfgId(self.cfgId)
    local neededExp = ModuleRefer.BattlePassModule:GetLevelNeededExp(self.cfgId, curLevel + 1)
    if neededExp == 1 then
        neededExp = ModuleRefer.BattlePassModule:GetLevelNeededExp(self.cfgId, curLevel)
        exp = neededExp
    end
    local weekExp = ModuleRefer.BattlePassModule:GetWeekExpByCfgId(self.cfgId)
    local expLimit = ModuleRefer.BattlePassModule:GetWeekExpLimitByCfgId(self.cfgId)
    self.textLevel.text = I18N.GetWithParams("battle_pass_lvl", curLevel)
    self.textExp.text = string.format('%d/%d', exp, neededExp)
    self.textExpLimit.text = I18N.GetWithParams(I18N_KEYS.WEEKLY_LIMIT, weekExp, expLimit)
    self.luaBtnPurchaseLvl:SetEnabled(curLevel < ModuleRefer.BattlePassModule:GetMaxLevelByCfgId(self.cfgId))
    if neededExp == 0 then
        self.progressBarExp.value = 1
    else
        self.progressBarExp.value = exp / neededExp
    end
end

function BattlePassMainMediator:UpdateBtns()
    local isAnyTaskRewardCanClaim = false
    if self.tabType == TAB_TYPES.TASK then
        for _, tabType in pairs(BattlePassConst.TASK_TAB_TYPE) do
            if ModuleRefer.BattlePassModule:IsAnyTaskRewardCanClaimByType(self.cfgId, tabType) then
                isAnyTaskRewardCanClaim = true
                break
            end
        end
        self.luaBtnClaimAll:SetVisible(isAnyTaskRewardCanClaim)
        self.goVxBtnClaimAll:SetActive(isAnyTaskRewardCanClaim)
    elseif self.tabType == TAB_TYPES.REWARD then
        local isAnyNodeRewardCanClaim = ModuleRefer.BattlePassModule:IsAnyNodeRewardCanClaim(self.cfgId)
        local isVip = ModuleRefer.BattlePassModule:IsVIP(self.cfgId)
        self.luaBtnClaimAll:SetVisible(isAnyNodeRewardCanClaim or (not isVip and self.haveClaimed))
        self.goVxBtnClaimAll:SetActive(isAnyNodeRewardCanClaim or (not isVip and self.haveClaimed))
        if not isAnyNodeRewardCanClaim and not isVip and self.haveClaimed then
            self.luaBtnClaimAll:FeedData({
                buttonText = I18N.Get(I18N_KEYS.CONTINUE_CLAIM),
                onClick = Delegate.GetOrCreate(self, self.OnBtnUnlockAdvancedRewardClicked),
                onPressDown = Delegate.GetOrCreate(self, self.OnBtnClaimAllPressDown),
                onPressUp = Delegate.GetOrCreate(self, self.OnBtnClaimAllPressUp),
            })
        elseif isAnyNodeRewardCanClaim then
            self.luaBtnClaimAll:FeedData({
                buttonText = I18N.Get(I18N_KEYS.CLAIM_ALL),
                onClick = Delegate.GetOrCreate(self, self.OnBtnClaimAllClicked),
                onPressDown = Delegate.GetOrCreate(self, self.OnBtnClaimAllPressDown),
                onPressUp = Delegate.GetOrCreate(self, self.OnBtnClaimAllPressUp),
            })
        end
    end
end

function BattlePassMainMediator:OnBtnTaskClicked()
    self:SwitchToTab(TAB_TYPES.TASK)
end

function BattlePassMainMediator:OnBtnRewardClicked()
    self:SwitchToTab(TAB_TYPES.REWARD)
end

function BattlePassMainMediator:OnBtnPurchaseLvlClicked()
    g_Game.UIManager:Open(UIMediatorNames.BattlePassPurchaseLvlMediator)
end

function BattlePassMainMediator:OnBtnUnlockAdvancedRewardClicked()
    g_Game.UIManager:Open(UIMediatorNames.BattlePassUnlockAdvanceMediator)
end

function BattlePassMainMediator:OnBtnClaimAllClicked()
    if self.tabType == TAB_TYPES.TASK then
        local tasks = {}
        for _, tabType in pairs(BattlePassConst.TASK_TAB_TYPE) do
            local taskIds = ModuleRefer.BattlePassModule:GetTasksByTaskType(self.cfgId, tabType)
            for _, taskId in ipairs(taskIds) do
                if ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId) == wds.TaskState.TaskStateCanFinish then
                    table.insert(tasks, taskId)
                end
            end
        end
        local operationParameter = PlayerTaskOperationParameter.new()
        operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetMultiReward
        operationParameter.args.IdArr:AddRange(tasks)
        operationParameter:SendOnceCallback(self.luaBtnClaimAll.CSComponent.gameObject.transform, nil, nil, function (_, isSuccess, _)
            if isSuccess then
                g_Game.EventManager:TriggerEvent(EventConst.BATTLEPASS_TASK_REWARD_CLAIM)
            end
        end)
    else
        ModuleRefer.BattlePassModule:ClaimReward(ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.BattlePass),
        BattlePassConst.REWARD_CLAIM_TYPE.ALL,
            nil, self.luaBtnClaimAll.CSComponent.transform)
        self.haveClaimed = true
    end
end

function BattlePassMainMediator:OnBtnClaimAllPressDown()
    -- self.goVxBtnClaimAll:SetActive(false)
end

function BattlePassMainMediator:OnBtnClaimAllPressUp()
    -- self.vxTimer = TimerUtility.DelayExecute(function()
    --     local isAnyTaskRewardCanClaim = false
    --     if self.tabType == TAB_TYPES.TASK then
    --         for _, tabType in pairs(BattlePassConst.TASK_TAB_TYPE) do
    --             if ModuleRefer.BattlePassModule:IsAnyTaskRewardCanClaimByType(self.cfgId, tabType) then
    --                 isAnyTaskRewardCanClaim = true
    --                 break
    --             end
    --         end
    --         self.goVxBtnClaimAll:SetActive(isAnyTaskRewardCanClaim)
    --     elseif self.tabType == TAB_TYPES.REWARD then
    --         local isAnyNodeRewardCanClaim = ModuleRefer.BattlePassModule:IsAnyNodeRewardCanClaim(self.cfgId)
    --         self.goVxBtnClaimAll:SetActive(isAnyNodeRewardCanClaim)
    --     end
    -- end, 0.2)
end

function BattlePassMainMediator:SetScrollDotsShow(showDotsIndex)
    for i = 1, self.pageNum do
        self.scrollDots[i].Lua:SetDotVisible(i == showDotsIndex)
    end
end

function BattlePassMainMediator:AutoScrollPage()
    local page = self.curPageIndex
    local pageCount = self.pageviewcontrollerScroll.pageCount
    local newPage = (page + 1) % pageCount
    self.pageviewcontrollerScroll:ScrollToPage(newPage)
    self:OnPageChanged(nil, newPage)
end

function BattlePassMainMediator:OnPageChanged(_, newPageIndex)
    self.curPageIndex = newPageIndex
    self:SetScrollDotsShow(newPageIndex + 1)
end

function BattlePassMainMediator:OnBeginDrag()
    self.pageScrollTimer:Reset(Delegate.GetOrCreate(self, self.AutoScrollPage),
                            PAGE_SCROLL_INTERVAL, -1)
end

function BattlePassMainMediator:OnEndDrag()
    self.pageScrollTimer:Start()
end

function BattlePassMainMediator:GetItemPos()
    local offset = self.progressBarExp.value * self.rectProgress.rect.width
    local uiCamera = g_Game.UIManager:GetUICamera()
    local startUIPos = UIHelper.WorldPos2UIPos(uiCamera, self.sliderProgress.gameObject.transform.position)
    local uiPos = CS.UnityEngine.Vector3(startUIPos.x + offset, startUIPos.y, startUIPos.z)
    local screenPos = UIHelper.UIPos2ScreenPos(uiPos)
    local worldPos = uiCamera:ScreenToWorldPoint(screenPos)
    return worldPos
end

return BattlePassMainMediator