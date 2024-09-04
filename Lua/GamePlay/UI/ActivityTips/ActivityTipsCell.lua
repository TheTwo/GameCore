local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local TimeFormatter = require('TimeFormatter')
local ColorConsts = require('ColorConsts')
local EventConst = require('EventConst')
local FPXSDKBIDefine = require('FPXSDKBIDefine')
local TimerUtility = require('TimerUtility')
local GuideUtils = require('GuideUtils')
local ActivityNoticeType = require('ActivityNoticeType')
local ActivityTipsCell = class('ActivityTipsCell',BaseTableViewProCell)

function ActivityTipsCell:OnCreate(param)
    self.goTypeLeague = self:GameObject('p_type_league')
    self.textLeague = self:Text('p_text_league', "activitynotice_type_alliance")
    self.goTypePersonal = self:GameObject('p_type_personal')
    self.textPersonal = self:Text('p_text_personal', "activitynotice_type_personal")
    self.textTitle = self:Text('p_text_title')
    self.textDesc = self:Text('p_text_desc')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.imgIconActivity = self:Image('p_icon_activity')
    self.goTypeLeague:SetActive(false)
    self.goTypePersonal:SetActive(false)
end

function ActivityTipsCell:OnFeedData(activityInfo)
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
    if activityInfo.activityNoticeType == ActivityNoticeType.ActivityNoticePersonal then
        self.goTypeLeague:SetActive(false)
        self.goTypePersonal:SetActive(true)
    elseif activityInfo.activityNoticeType == ActivityNoticeType.ActivityNoticeAlliance then
        self.goTypeLeague:SetActive(true)
        self.goTypePersonal:SetActive(false)
    else
        self.goTypeLeague:SetActive(false)
        self.goTypePersonal:SetActive(false)
    end
end

function ActivityTipsCell:CountDownTime()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastTime = self.curShowAcitivityInfo.startTimeSeconds - curTime
    if lastTime > 0 then
        self.textDesc.text = UIHelper.GetColoredText(I18N.GetWithParams("activitynotice_countdown_start", TimeFormatter.SimpleFormatTimeWithDayHourSeconds(lastTime)), ColorConsts.quality_white)
        return
    end
    local isOpen = ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(self.curShowAcitivityInfo.acitivityId)
    if isOpen then
        local endTime = self.curShowAcitivityInfo.endTimeSeconds - curTime
        if endTime > 0 then
            self.textDesc.text = UIHelper.GetColoredText(I18N.GetWithParams("activitynotice_countdown_end", TimeFormatter.SimpleFormatTimeWithDayHourSeconds(endTime)), ColorConsts.quality_green)
            return
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.REFRESH_ACTIVITY_NOTICE)
    self.textDesc.text = ""
    if self.countDownTimer then
        TimerUtility.StopAndRecycle(self.countDownTimer)
        self.countDownTimer = nil
    end
end

function ActivityTipsCell:OnClose()
    if self.countDownTimer then
        TimerUtility.StopAndRecycle(self.countDownTimer)
        self.countDownTimer = nil
    end
end

function ActivityTipsCell:OnBtnGotoClicked(args)
    local keyMap = FPXSDKBIDefine.ExtraKey.activity_entrance
    local extraDic = {}
    extraDic[keyMap.activity_id] = self.curShowAcitivityInfo.id
    extraDic[keyMap.all_activity_ids] = self.curShowAcitivityInfo.curAllActivityIds
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.activity_entrance, extraDic)
    if self.curShowAcitivityInfo.gotoId and self.curShowAcitivityInfo.gotoId > 0 then
        GuideUtils.GotoByGuide(self.curShowAcitivityInfo.gotoId, true)
    end
end

return ActivityTipsCell
