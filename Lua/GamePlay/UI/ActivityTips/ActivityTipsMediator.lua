local BaseUIMediator = require('BaseUIMediator')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local ConfigTimeUtility = require('ConfigTimeUtility')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local ActivityTipsMediator = class('ActivityTipsMediator',BaseUIMediator)

function ActivityTipsMediator:OnCreate()
    self.tableviewproTable = self:TableViewPro('p_table')
end

function ActivityTipsMediator:OnOpened()
    self:InitData()
    self:FilterAndSortActivity()
    g_Game.EventManager:AddListener(EventConst.REFRESH_ACTIVITY_NOTICE, Delegate.GetOrCreate(self, self.FilterAndSortActivity))
end

function ActivityTipsMediator:InitData()
    self.activityList = {}
    for _, v in ConfigRefer.ActivityNotice:ipairs() do
        local single = {}
        single.id = v:Id()
        single.name = v:Name()
        single.icon = v:Icon()
        single.tabId = v:RefActivityCenterTabs()
        single.activityNoticeType = v:ActivityNoticeType()
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

function ActivityTipsMediator:FilterAndSortActivity()
    self.scrollList = {}
    self.curAllActivityIds = ""
    for _, activityInfo in ipairs(self.activityList) do
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
                self.curAllActivityIds = self.curAllActivityIds .. activityInfo.id .. ","
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
    table.sort(self.scrollList, sortfunc)
    self.tableviewproTable:Clear()
    for _, v in ipairs(self.scrollList) do
        v.curAllActivityIds = self.curAllActivityIds
        self.tableviewproTable:AppendData(v)
    end
end

function ActivityTipsMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.REFRESH_ACTIVITY_NOTICE, Delegate.GetOrCreate(self, self.FilterAndSortActivity))
end

return ActivityTipsMediator
