local BaseUIMediator = require ('BaseUIMediator')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local UIHeroLocalData = require('UIHeroLocalData')
local I18N = require('I18N')
local TimeFormatter = require('TimeFormatter')
local TimerUtility = require('TimerUtility')
local UIMediatorNames = require('UIMediatorNames')
local ReceiveOptRewardParameter = require('ReceiveOptRewardParameter')
local TaskOperationParameter = require("PlayerTaskOperationParameter")
local ModuleRefer = require('ModuleRefer')
local HeroType = require('HeroType')
local HeroUIUtilities = require('HeroUIUtilities')
local UIHelper = require("UIHelper")
---@class UIOneDayMediator : BaseUIMediator

local UIOneDayMediator = class('UIOneDayMediator', BaseUIMediator)

function UIOneDayMediator:OnCreate()
    ---scene_activity_1day
    self.imgImgHero = self:Image('p_img_hero')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.textDetail = self:Text('p_text_detail', I18N.Get("activity_24h_free_hero_2"))
    self.textTitle = self:Text('p_text_title', I18N.Get("activity_24h_free_hero_1"))
    self.imgTitle = self:Image('p_img_title')
    self.textName = self:Text('p_text_name')
    -- self.imgIconQuality = self:Image('p_icon_quality') --暂时弃用
    self.textQuality = self:Text('p_text_quality')
    self.goGroupTime = self:GameObject('p_group_time')
    self.goBtn = self:GameObject('p_btn')
    self.textTip = self:Text('p_text_tip', I18N.Get("activity_24h_free_hero_3"))
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.textTask = self:Text('p_text_content')
    self.btnVideo = self:Button('p_btn_video', Delegate.GetOrCreate(self, self.OnBtnVideoClicked))
    self.textVideo = self:Text('p_text_video', I18N.Get('first_pay_hero_skill'))

    self.obtainTaskId = ConfigRefer.ConstMain:ObtainOneDayTask()
    self.obtainTaskName = ModuleRefer.QuestModule:GetTaskNameByID(self.obtainTaskId)
end

function UIOneDayMediator:OnOpened()
    local curLang = g_Game.LocalizationManager:GetCurrentLanguage()
    local heroId = ConfigRefer.ConstMain:OptRewardHeroId()
    local heroCfg = ConfigRefer.Heroes:Find(heroId)
    local index = heroCfg:Quality() + 1
    -- g_Game.SpriteManager:LoadSprite(UIHeroLocalData.QUALITY_IMAGE[index], self.imgIconQuality)
    self.textName.text = I18N.Get(heroCfg:Name())
    self.textTask.text = 'p_text_content'
    self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index - 1))
    self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index - 1))
    local obtainTaskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.obtainTaskId)
    local isObtainTaskFinished = self.obtainTaskId > 0 and obtainTaskState == wds.TaskState.TaskStateCanFinish

    self.textTitle.gameObject:SetActive(curLang ~= 'en')
    self.imgTitle.gameObject:SetActive(curLang == 'en')

    local buttonGet = {}
    buttonGet.onClick = Delegate.GetOrCreate(self, self.GetHero)
    buttonGet.disableClick = Delegate.GetOrCreate(self, self.DisableGetHero)

    if isObtainTaskFinished then
        buttonGet.buttonText = I18N.Get("activity_24h_free_hero_4")
    else
        buttonGet.buttonText = I18N.Get("survival_rules_task_goto")
    end

    self.compChildCompB:OnFeedData(buttonGet)
    self.compChildCompB:SetEnabled(isObtainTaskFinished)

    if self.obtainTaskName then
        self.textTask.text = I18N.Get('activity_24h_free_hero_3')
    end
end

function UIOneDayMediator:SetTimer(timeText)
    local timeTexts = TimeFormatter.SimpleFormatTime(timeText)
    local sp = string.split(timeTexts, ':')
    self.textTime.text = sp[1]
    self.textTime1.text = sp[2]
    self.textTime2.text = sp[3]
end

function UIOneDayMediator:ZeroTimer()
    self.textTime.text = "00"
    self.textTime1.text = "00"
    self.textTime2.text = "00"
end

function UIOneDayMediator:StopTimer()
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
    end
    self.tickTimer = nil
end

function UIOneDayMediator:OnClose()
    self:StopTimer()
end

function UIOneDayMediator:DisableGetHero()
    self:CloseSelf()
    g_Game.UIManager:Open(UIMediatorNames.SEClimbTowerMainMediator)
end

function UIOneDayMediator:GetHero()
    local obtainTaskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.obtainTaskId)
    if obtainTaskState == wds.TaskState.TaskStateCanFinish then
        local operationParameter = TaskOperationParameter.new()
        operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
        operationParameter.args.CID = self.obtainTaskId
        g_Logger.Log('UIOneDayMediator:obtainTaskId:' .. tostring(self.obtainTaskId))
        operationParameter:Send(self.goBtn.transform)
    end
    self:CloseSelf()
end

function UIOneDayMediator:OnBtnDetailClicked(args)
    self:CloseSelf()
    ModuleRefer.HeroModule:SetHeroSelectType(HeroType.Heros)
    g_Game.UIManager:Open(UIMediatorNames.UIHeroMainUIMediator, {id = ConfigRefer.ConstMain:OptRewardHeroId()})
end

function UIOneDayMediator:OnBtnCloseClicked(args)
    self:CloseSelf()
end

function UIOneDayMediator:OnBtnVideoClicked(args)
    local data = {}
    for i = 1, ConfigRefer.ConstMain:FirstFreeHeroSkillsDemoLength() do
        local demoId = ConfigRefer.ConstMain:FirstFreeHeroSkillsDemo(i)
        local demoCfg = ConfigRefer.GuideDemo:Find(demoId)
        local demo = {
            imageId = demoCfg:Pic(),
            videoId = demoCfg:Video(),
            title = demoCfg:Title(),
            desc = demoCfg:Desc(),
        }
        table.insert(data, demo)
    end
    g_Game.UIManager:Open(UIMediatorNames.GuideDemoUIMediator, {data = data})
end


return UIOneDayMediator