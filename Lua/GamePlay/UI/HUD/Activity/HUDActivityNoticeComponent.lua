local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local BaseUIComponent = require('BaseUIComponent')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local TimeFormatter = require('TimeFormatter')
local ColorConsts = require('ColorConsts')
local Delegate = require('Delegate')
local ConfigTimeUtility = require('ConfigTimeUtility')
local UIMediatorNames = require('UIMediatorNames')
local FPXSDKBIDefine = require('FPXSDKBIDefine')
local NewFunctionUnlockIdDefine = require('NewFunctionUnlockIdDefine')
local TimerUtility = require('TimerUtility')
---@class HUDActivityNoticeComponent : BaseUIMediator
local HUDActivityNoticeComponent = class("HUDActivityNoticeComponent",BaseUIComponent)

function HUDActivityNoticeComponent:ctor(...)
    BaseUIComponent.ctor(self, ...)
end

function HUDActivityNoticeComponent:OnCreate(param)
    self.root = self:GameObject('p_root')
    self.imgIconActivity = self:Image('p_icon_activity')
    self.textTitle = self:Text('p_text_title')
    self.textDesc = self:Text('p_text_desc')
    self.vx_trigger = self:AnimTrigger("vx_trigger")
    self.btnButton = self:Button('p_button', Delegate.GetOrCreate(self, self.OnBtnButtonClicked))
end

function HUDActivityNoticeComponent:OnShow(param)
    self.showIndex = 0
    self:InitData()
    if self.refreshTimer then
        TimerUtility.StopAndRecycle(self.refreshTimer)
        self.refreshTimer = nil
    end
    self:RefreshActivity()
    self.refreshTimer = TimerUtility.IntervalRepeat(function() self:RefreshActivity() end, 5, -1)
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function HUDActivityNoticeComponent:OnHide(param)
    if self.refreshTimer then
        TimerUtility.StopAndRecycle(self.refreshTimer)
        self.refreshTimer = nil
    end
    if self.countDownTimer then
        TimerUtility.StopAndRecycle(self.countDownTimer)
        self.countDownTimer = nil
    end
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
end

function HUDActivityNoticeComponent:InitData()
    self.activityList = {}
    for _, v in ConfigRefer.ActivityNotice:ipairs() do
        local single = {}
        single.id = v:Id()
        single.name = v:Name()
        single.icon = v:Icon()
        single.tabId = v:RefActivityCenterTabs()
        single.priority = v:Priority()
        single.showInScroll = v:ShowInScrollTab()
        single.systemSwitch = v:SystemSwitch()
        single.acitivityId = v:ActivityConfig()
        single.joinTime = v:AddScrollTabDuration()
        single.countDownTime = v:CountDownDuration()
        single.onlyShow = v:OnlyShowWhenOpen()
        single.gotoId = v:Goto()
        self.activityList[#self.activityList + 1] = single
    end
end

function HUDActivityNoticeComponent:FilterAndSortActivity()
    self.scrollList = {}
    self.curAllActivityIds = ""
    for _, activityInfo in ipairs(self.activityList) do
        if activityInfo.showInScroll then
            local unlocked = true
            if activityInfo.systemSwitch and activityInfo.systemSwitch > 0 then
                unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(activityInfo.systemSwitch)
            end
            if unlocked then
                local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityInfo.acitivityId)
                local startTimeSeconds = startTime.Seconds
                local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
                local joinTime = startTimeSeconds - math.max(ConfigTimeUtility.NsToSeconds(activityInfo.joinTime), 0)
                activityInfo.startTimeSeconds = startTimeSeconds
                activityInfo.endTimeSeconds = endTime.Seconds
                local isFinished = false
                if activityInfo.tabId > 0 then
                    isFinished = curTime > startTimeSeconds and not ModuleRefer.ActivityCenterModule:IsActivityTabOpenByTabId(activityInfo.tabId)
                end
                if curTime >= joinTime and curTime < endTime.Seconds and not isFinished then
                    local countDownTime = math.max(ConfigTimeUtility.NsToSeconds(activityInfo.countDownTime), 0)
                    if countDownTime > 0 then
                        local showCountDownTime = startTimeSeconds - countDownTime
                        activityInfo.showCountDownTime = showCountDownTime
                    end
                    self.scrollList[#self.scrollList + 1] = activityInfo
                end
            end
        end
    end
    local sortfunc = function(a, b)
        if a.onlyShow ~= b.onlyShow then
            return a.onlyShow
        elseif a.priority ~= b.priority then
            return a.priority < b.priority
        end
        return a.acitivityId < b.acitivityId
    end
    local onlyShow = {}
    for _, singleInfo in ipairs(self.scrollList) do
        if singleInfo.onlyShow then
            onlyShow[#onlyShow + 1] = singleInfo
        end
    end
    if #onlyShow > 0 then
        self.scrollList = onlyShow
    end
    for _, singleInfo in ipairs(self.scrollList) do
        self.curAllActivityIds = self.curAllActivityIds .. singleInfo.id .. ","
    end
    table.sort(self.scrollList, sortfunc)
end

function HUDActivityNoticeComponent:RefreshActivity()
    self:FilterAndSortActivity()
    local isUnLock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.ACTIVITY_NOTICE)
    local isShow = isUnLock and #self.scrollList > 0
    local playInitAni = false
    if self.root.activeSelf and not isShow then
        self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
        playInitAni = true
    elseif isShow and not self.root.activeSelf then
        playInitAni = true
        local isOnlyShow = self.scrollList[1].onlyShow
        if isOnlyShow then
            self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
        else
            self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
    end
    self.root:SetActive(isShow)
    if #self.scrollList <= 0 then
        return
    end
    local showIndex = self.showIndex + 1
    if showIndex > #self.scrollList then
        showIndex = 1
    end
    self.showIndex = showIndex
    local activityInfo = self.scrollList[showIndex]
    if #self.scrollList > 1 and not playInitAni then
        self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3, function()
            self:RefreshSingleActivity(activityInfo)
            self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4)
        end)
    else
        self:RefreshSingleActivity(activityInfo)
    end
end

function HUDActivityNoticeComponent:RefreshSingleActivity(activityInfo)
    self.curShowAcitivityInfo = activityInfo
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if self.countDownTimer then
        TimerUtility.StopAndRecycle(self.countDownTimer)
        self.countDownTimer = nil
    end
    if activityInfo.showCountDownTime and curTime >= activityInfo.showCountDownTime and curTime < activityInfo.startTimeSeconds then
        self:CountDownTime()
        self.countDownTimer = TimerUtility.IntervalRepeat(function() self:CountDownTime() end, 1, -1)
    elseif curTime < activityInfo.startTimeSeconds then
        self.textDesc.text = I18N.Get('activitynotice_text_start')
    else
        local isOpen = ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(activityInfo.acitivityId)
        if isOpen and curTime < activityInfo.endTimeSeconds then
            self:CountDownTime()
            self.countDownTimer = TimerUtility.IntervalRepeat(function() self:CountDownTime() end, 1, -1)
        else
            self.textDesc.text = ""
        end
    end
    g_Game.SpriteManager:LoadSprite(activityInfo.icon, self.imgIconActivity)
    self.textTitle.text = I18N.Get(activityInfo.name)
end

function HUDActivityNoticeComponent:CountDownTime()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastTime = self.curShowAcitivityInfo.startTimeSeconds - curTime
    if lastTime > 0 then
        self.textDesc.text = UIHelper.GetColoredText(I18N.Get('activitynotice_text_start'), ColorConsts.quality_white)
        return
    end
    local isOpen = ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(self.curShowAcitivityInfo.acitivityId)
    if isOpen then
        local endTime = self.curShowAcitivityInfo.endTimeSeconds - curTime
        if endTime > 0 then
            self.textDesc.text = UIHelper.GetColoredText(I18N.Get('activitynotice_text_end'), ColorConsts.army_green)
            return
        end
    end
    self.textDesc.text = ""
    if self.countDownTimer then
        TimerUtility.StopAndRecycle(self.countDownTimer)
        self.countDownTimer = nil
    end
end

function HUDActivityNoticeComponent:OnBtnButtonClicked(args)
    local keyMap = FPXSDKBIDefine.ExtraKey.activity_notice
    local extraDic = {}
    extraDic[keyMap.activity_id] = self.curShowAcitivityInfo.id
    extraDic[keyMap.all_activity_ids] = self.curAllActivityIds
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.activity_notice, extraDic)
    g_Game.UIManager:Open(UIMediatorNames.ActivityTipsMediator)
end

return HUDActivityNoticeComponent