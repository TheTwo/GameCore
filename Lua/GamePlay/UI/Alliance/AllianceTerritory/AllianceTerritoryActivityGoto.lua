local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local TimeFormatter = require('TimeFormatter')
---@class AllianceTerritoryActivityGoto : BaseUIComponent
local AllianceTerritoryActivityGoto = class('AllianceTerritoryActivityGoto', BaseUIComponent)

---@class AllianceTerritoryActivityGotoParameter
---@field activityTabId number

function AllianceTerritoryActivityGoto:ctor()
end

function AllianceTerritoryActivityGoto:OnCreate()
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClick))
    self.imgReward = self:Image('p_img_reward')
    self.textTitle = self:Text('p_title_activity')
    self.textDesc = self:Text('p_text_desc')
end

---@param param AllianceTerritoryActivityGotoParameter
function AllianceTerritoryActivityGoto:OnFeedData(param)
    self.activityTabId = param.activityTabId
    self.textTitle.text = I18N.Get(ConfigRefer.ActivityCenterTabs:Find(self.activityTabId):TitleKey())
    self.imgReward.gameObject:SetActive(ModuleRefer.ActivityCenterModule:HasActivityNotify(self.activityTabId))
    self:TimerTick()
end

function AllianceTerritoryActivityGoto:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TimerTick))
end

function AllianceTerritoryActivityGoto:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TimerTick))
end

function AllianceTerritoryActivityGoto:TimerTick()
    local activityRewardId = ConfigRefer.ActivityCenterTabs:Find(self.activityTabId):RefActivityReward()
    local activityTemplateId = ConfigRefer.ActivityRewardTable:Find(activityRewardId):OpenActivity()
    local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityTemplateId)
    local endTimeSec = endTime.Seconds
    local nowSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    local leftSec = endTimeSec - nowSec
    local time = TimeFormatter.GetTimeTableInDHMS(leftSec)
    if time.day > 0 then
        self.textDesc.text = string.format('<b>' .. I18N.GetWithParams("battlepass_remain_time", time.day, time.hour) .. '</b>')
    else
        self.textDesc.text = string.format('<b>' .. I18N.GetWithParams("battlepass_remain_time_1", time.hour, time.minute).. '</b>')
    end
end

function AllianceTerritoryActivityGoto:OnBtnGotoClick()
    ModuleRefer.ActivityCenterModule:GotoActivity(self.activityTabId)
end

return AllianceTerritoryActivityGoto