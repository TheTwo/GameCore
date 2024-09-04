local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local DBEntityPath = require('DBEntityPath')
local TimerUtility = require('TimerUtility')
local Utils = require('Utils')
---@class QuestUIMediator : BaseUIMediator
---@field btnBack CommonBackButtonComponent
local QuestUIMediator = class("QuestUIMediator", BaseUIMediator)

function QuestUIMediator:OnCreate()
    ---@type ChapterQuestPageComponent
    self.pageChapter = self:LuaObject('p_mission_scenario')
    ---@type DailyQuestPageComponent
    self.pageDaily = self:LuaObject('p_mission_daily')
    ---@type DevelopmentQuestPageComponent
    self.pageDevelopment = self:LuaObject('p_mission_development');
    self.btnBack = self:Button('p_btn_close', Delegate.GetOrCreate(self,self.OnCloseWin))
    self.btnScenario = self:Button('p_btn_scenario', Delegate.GetOrCreate(self, self.OnBtnScenarioClicked))
    self.goImgSclectScenario = self:GameObject('p_img_sclect_scenario')
    self.btnDay = self:Button('p_btn_day', Delegate.GetOrCreate(self, self.OnBtnDayClicked))
    self.goImgSclectDay = self:GameObject('p_img_sclect_day')
    --self.btnDevelopment = self:Button('p_btn_development', Delegate.GetOrCreate(self, self.OnBtnDevelopmentClicked))
    self.goImgSclectDevelopment = self:GameObject('p_img_sclect_development')
    self.aniTrigger = self:AnimTrigger('vx_trigger')
    --TODO:兼容老版本，新版稳定后删除
    if not self.aniTrigger then
        self.aniTrigger = self:AnimTrigger('fx_trigger')
    end
    self.pageDaily:SetVisible(false)
    self.pageDevelopment:SetVisible(false)
    self.notifyNode1 = self:LuaObject('child_reddot_default_1')
    self.taskProgress = self:Slider("p_task_progress")
    self.notifyNode = self:LuaObject('child_reddot_default')
    self.playAnim = false
end

function QuestUIMediator:OnOpened()
    ModuleRefer.QuestModule.Chapter:CreatePageState()
    ModuleRefer.QuestModule.Chapter:SetInitPageState()
    if self.waitForVxLoaded then
        self.waitForVxLoaded = false
        self.playAnim = true
        TimerUtility.DelayExecuteInFrame(function()
            self.pageChapter:PlayCellInitAnim()
        end, 3, true)
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.OnEnable, function() self:PlayerScenarioShowAnim() end)
    end
end

function QuestUIMediator:OnClose(param)
    ModuleRefer.QuestModule:UpdateFollowQuest()
    g_Game.EventManager:TriggerEvent( EventConst.QUEST_FOLLOW_REFRESH )
end

function QuestUIMediator:OnShow(param)
    self:OnBtnScenarioClicked()
end

function QuestUIMediator:OnBtnScenarioClicked()
    self.pageChapter:SetVisible(true)
    self.pageDaily:SetVisible(false)
    self.pageDevelopment:SetVisible(false)
    self.goImgSclectScenario:SetActive(true)
    self.goImgSclectDay:SetActive(false)
    self.goImgSclectDevelopment:SetActive(false)

    if self.playAnim then
        self.pageChapter:PlayCellInitAnim()
        TimerUtility.DelayExecuteInFrame(function()
            self:PlayerScenarioShowAnim()
        end, 3, true)
    else
        self.waitForVxLoaded = true
    end
end

function QuestUIMediator:PlayerScenarioShowAnim()
    self.pageChapter:PlayCellsShowAnim()
end

function QuestUIMediator:PlayerDayShowAnim()
    self.pageDaily:PlayCellsShowAnim()
end

function QuestUIMediator:OnBtnDevelopmentClicked()
    self.pageChapter:SetVisible(false)
    self.pageDaily:SetVisible(false)
    self.pageDevelopment:SetVisible(true)
    self.goImgSclectScenario:SetActive(false)
    self.goImgSclectDay:SetActive(false)
    self.goImgSclectDevelopment:SetActive(true)
    self.pageDevelopment:PlayCellInitAnim()
    if self.playAnim then
        self:PlayerDevelopmentShowAnim()
    else
        self.playAnim = true
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.OnEnable, function() self:PlayerDevelopmentShowAnim() end)
    end
    g_Game.PlayerPrefsEx:SetInt("IsOpendDevTab".. ModuleRefer.PlayerModule:GetPlayerId(), 1)
    self.notifyNode.redDot:SetActive(false)
end

function QuestUIMediator:PlayerDevelopmentShowAnim()
    self.pageDevelopment:PlayCellsShowAnim()
end

function QuestUIMediator:OnCloseWin()
    self:BackToPrevious()
end

return QuestUIMediator