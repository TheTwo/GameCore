---scene: scene_league_popup_reserve
local BaseUIMediator = require("BaseUIMediator")
local I18N = require("I18N")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
local ActivityAllianceBossRegisterStateHelper = require("ActivityAllianceBossRegisterStateHelper")
---@class ActivityBehemothTimeChooseMediator : BaseUIMediator
local ActivityBehemothTimeChooseMediator = class("ActivityBehemothTimeChooseMediator", BaseUIMediator)

local I18N_KEY = ActivityAllianceBossConst.I18N_KEY

function ActivityBehemothTimeChooseMediator:ctor()
    self.chosenActivity = 0
end

function ActivityBehemothTimeChooseMediator:OnCreate()
    ---@see CommonPopupBackMediumComponent
    self.luaBackGround = self:LuaObject("child_popup_base_m")
    self.textTitle = self:Text("p_text", "alliance_behemoth_challenge_state12")
    self.tableTime = self:TableViewPro("p_table_time")
    ---@see BistateButton
    self.luaBtn = self:LuaObject("child_comp_btn_b")
end

---@param param ActivityAllianceBossRegisterTimeChooseParam
function ActivityBehemothTimeChooseMediator:OnOpened(param)
    self.battleId = param.battleId
    self.uiRole = param.uiRole
    self.uiState = param.uiState
    self.battleData = param.battleData
    g_Game.EventManager:AddListener(EventConst.ON_ACTIVITY_ALLIANCE_BOSS_REGISTER_TIME_SELCET, Delegate.GetOrCreate(self, self.OnTimeCellClick))
    self:InitTimeDatas()
    self:InitBtn()

    ---@type CommonBackButtonData
    local data = {}
    data.title = I18N.Get("alliance_behemoth_challenge_state6")
    self.luaBackGround:FeedData(data)
end

function ActivityBehemothTimeChooseMediator:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.ON_ACTIVITY_ALLIANCE_BOSS_REGISTER_TIME_SELCET, Delegate.GetOrCreate(self, self.OnTimeCellClick))
end

function ActivityBehemothTimeChooseMediator:InitTimeDatas()
    self.battleCfg = ConfigRefer.AllianceBattle:Find(self.battleId)
    ---@type ActivityAllianceBossRegisterTimeChooseCellParam[]
    self.timeCellData = {}

    local timePeriodsCount = self.battleCfg:BattleActivityLength()
    for i = 1, timePeriodsCount do
        local activityTemplateId = self.battleCfg:BattleActivity(i)
        local timeStr = self:GetTimeStr(activityTemplateId)
        self.timeCellData[i] = {
            activityTemplateId = activityTemplateId,
            timeStr = timeStr,
        }
    end
    table.sort(self.timeCellData, self.TimeCellDataSorter)
    for _, v in ipairs(self.timeCellData) do
        self.tableTime:AppendData(v)
    end
    for _, v in ipairs(self.timeCellData) do
        if ActivityAllianceBossRegisterStateHelper.GetTimeState(v.activityTemplateId) == ActivityAllianceBossRegisterStateHelper.TimeStates.Before then
            v.select = true
            self.chosenActivity = v.activityTemplateId
            break
        end
    end
end

function ActivityBehemothTimeChooseMediator:InitBtn()
    ---@type BistateButtonParameter
    local data = {}
    data.buttonText = I18N.Get("se_pvp_yes")
    data.disableButtonText = I18N.Get("se_pvp_yes")
    data.onClick = Delegate.GetOrCreate(self, self.OnClick)
    data.disableClick = Delegate.GetOrCreate(self, self.OnDisableClick)
    self.luaBtn:FeedData(data)
    self.luaBtn:SetEnabled(self.uiRole > ActivityAllianceBossConst.ROLE.R3)
end

function ActivityBehemothTimeChooseMediator.TimeCellDataSorter(a, b)
    local aStartTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(a.activityTemplateId)
    local bStartTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(b.activityTemplateId)
    return aStartTime.Seconds < bStartTime.Seconds
end

function ActivityBehemothTimeChooseMediator:OnTimeCellClick(activityTemplateId)
    self.chosenActivity = activityTemplateId
end

function ActivityBehemothTimeChooseMediator:OnClick()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(self.chosenActivity)
    if curTime > endTime.ServerSecond then
        return
    end
    local date = TimeFormatter.ToDateTime(startTime.ServerSecond)
    ---@type CommonConfirmPopupMediatorParameter
    local commonConfirmParam = {}
    commonConfirmParam.title = I18N.Get(I18N_KEY.CONFIRM_TITLE)
    commonConfirmParam.content = I18N.GetWithParams(I18N_KEY.CONFIRM_REGISTER_CONTENT, string.format(" %d/%02d/%02d %d:%02d",
    date.Year, date.Month, date.Day, date.Hour, date.Minute))
    commonConfirmParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    commonConfirmParam.onConfirm = function (context)
        local transform = self.luaBtn.CSComponent.gameObject.transform
        ModuleRefer.AllianceModule:ActivateAllianceActivityBattle(transform, self.battleData.ID, nil, nil, self.chosenActivity)
        self:CloseSelf()
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, commonConfirmParam)
end

function ActivityBehemothTimeChooseMediator:OnDisableClick()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_challengeactivity_tips_managereservation"))
end

function ActivityBehemothTimeChooseMediator:GetTimeStr(activityTemplateId)
    local startTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityTemplateId)
    local sDateTime = TimeFormatter.ToDateTime(startTime.Seconds)
    local timeStr = string.format("UTC %d/%02d/%02d %02d:%02d",
        sDateTime.Year, sDateTime.Month, sDateTime.Day, sDateTime.Hour, sDateTime.Minute)
    return timeStr
end

return ActivityBehemothTimeChooseMediator
