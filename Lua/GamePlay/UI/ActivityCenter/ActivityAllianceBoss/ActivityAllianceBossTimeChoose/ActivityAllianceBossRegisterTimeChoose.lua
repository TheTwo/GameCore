local BaseUIComponent = require("BaseUIComponent")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
local ActivityAllianceBossRegisterStateHelper = require("ActivityAllianceBossRegisterStateHelper")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local TimeFormatter = require("TimeFormatter")
local EventConst = require("EventConst")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
---@class ActivityAllianceBossRegisterTimeChoose : BaseUIComponent
local ActivityAllianceBossRegisterTimeChoose = class('ActivityAllianceBossRegisterTimeChoose', BaseUIComponent)

local I18N_KEY = ActivityAllianceBossConst.I18N_KEY

---@class ActivityAllianceBossRegisterTimeChooseParam
---@field battleId number
---@field uiRole number
---@field uiState number
---@field battleData wds.AllianceActivityBattleInfo

function ActivityAllianceBossRegisterTimeChoose:OnCreate()
    self.goArrow = self:GameObject("p_arrow")
    self.goList = self:GameObject("p_list")
    self.btnSelect = self:Button('child_dropdown', Delegate.GetOrCreate(self, self.OnBtnSelectClick))
    self.stextLabelSelectTime = self:Text('p_text_time', I18N_KEY.LABEL_SELECT_TIME)
    self.textSelectedTime = self:Text('p_text_time_detail')
    self.btnCancel = self:Button('p_btn_cancel', Delegate.GetOrCreate(self, self.OnBtnCancelClick))
    self.textBtnCancel = self:Text('p_text_cancel', I18N_KEY.BTN_CANCEL)
    self.luaTimeCellTemplate = self:LuaBaseComponent("p_item")
    self.timeCellList = {}
end

function ActivityAllianceBossRegisterTimeChoose:OnShow()
    g_Game.EventManager:AddListener(EventConst.ON_ACTIVITY_ALLIANCE_BOSS_REGISTER_TIME_SELCET, Delegate.GetOrCreate(self, self.OnTimeCellClick))
end

function ActivityAllianceBossRegisterTimeChoose:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_ACTIVITY_ALLIANCE_BOSS_REGISTER_TIME_SELCET, Delegate.GetOrCreate(self, self.OnTimeCellClick))
    self:ClearTimeCells()
end

function ActivityAllianceBossRegisterTimeChoose:ClearTimeCells()
    for _, v in ipairs(self.timeCellList) do
        UIHelper.DeleteUIComponent(v)
    end
end

---@param param ActivityAllianceBossRegisterTimeChooseParam
function ActivityAllianceBossRegisterTimeChoose:OnFeedData(param)
    self.battleId = param.battleId
    self.uiRole = param.uiRole
    self.uiState = param.uiState
    self.battleData = param.battleData

    self.isListShow = false
    self:InitSelectedTime()
    self:UpdateBtns()
end

function ActivityAllianceBossRegisterTimeChoose:InitSelectedTime()
    self.battleCfg = ConfigRefer.AllianceBattle:Find(self.battleId)
    self.selectedActvityTemplateId = self.battleData.ChosenActivity
    ---@type ActivityAllianceBossRegisterTimeChooseCellParam[]
    self.timeCellData = {}
    self:ClearTimeCells()

    local timePeriodsCount = self.battleCfg:BattleActivityLength()
    self.luaTimeCellTemplate:SetVisible(true)
    for i = 1, timePeriodsCount do
        local activityTemplateId = self.battleCfg:BattleActivity(i)
        local timeStr = self:GetTimeStr(activityTemplateId)
        self.timeCellData[i] = {
            activityTemplateId = activityTemplateId,
            timeStr = timeStr,
        }
    end
    table.sort(self.timeCellData, self.TimeCellDataSorter)
    for i = 1, timePeriodsCount do
        self.timeCellList[i] = UIHelper.DuplicateUIComponent(self.luaTimeCellTemplate)
        self.timeCellList[i]:FeedData(self.timeCellData[i])
    end
    self.luaTimeCellTemplate:SetVisible(false)

    if not self.selectedActvityTemplateId or self.selectedActvityTemplateId == 0 then
        self.selectedActvityTemplateId = self:GetFirstAvaliableActivityTemplateId()
    end

    self.textSelectedTime.text = self:GetTimeStr(self.selectedActvityTemplateId)
end

---@param a ActivityAllianceBossRegisterTimeChooseCellParam
---@param b ActivityAllianceBossRegisterTimeChooseCellParam
---@return boolean
function ActivityAllianceBossRegisterTimeChoose.TimeCellDataSorter(a, b)
    local aStartTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(a.activityTemplateId)
    local bStartTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(b.activityTemplateId)
    return aStartTime.Seconds < bStartTime.Seconds
end

function ActivityAllianceBossRegisterTimeChoose:UpdateBtns()
    local shouldShowCancelBtn = self.uiRole == ActivityAllianceBossConst.ROLE.R4 and
        (self.uiState == ActivityAllianceBossConst.BATTLE_STATE.NOT_READY_BATTLE or
            self.uiState == ActivityAllianceBossConst.BATTLE_STATE.READY_BATTLE) and
            not ActivityAllianceBossRegisterStateHelper.IsTimeReached(self.selectedActvityTemplateId)
    self.btnCancel.gameObject:SetActive(shouldShowCancelBtn)

    local shouldShowSelectBtn = self.uiRole == ActivityAllianceBossConst.ROLE.R4 and
        self.uiState == ActivityAllianceBossConst.BATTLE_STATE.UNREGISTER
    self.btnSelect.gameObject:SetActive(shouldShowSelectBtn)
end

function ActivityAllianceBossRegisterTimeChoose:OnBtnSelectClick()
    self.isListShow = not self.isListShow
    self.goList:SetActive(self.isListShow)
end

function ActivityAllianceBossRegisterTimeChoose:OnBtnCancelClick()
    ---@type CommonConfirmPopupMediatorParameter
    local commonConfirmParam = {}
    commonConfirmParam.title = I18N_KEY.CONFIRM_TITLE
    if ActivityAllianceBossRegisterStateHelper.IsTimeReached(self.selectedActvityTemplateId) then
        commonConfirmParam.content = 'alliance_challengeactivity_pop_cancel'
    else
        commonConfirmParam.content = 'alliance_challengeactivity_pop_cancel'
    end
    commonConfirmParam.onConfirm = function (context)
        ModuleRefer.AllianceModule:CancelAllianceActivityBattle(self.btnCancel.transform, self.battleData.ID)
        return true
    end
    commonConfirmParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, commonConfirmParam)
end

function ActivityAllianceBossRegisterTimeChoose:OnTimeCellClick(activityTemplateId)
    self.selectedActvityTemplateId = activityTemplateId
    self.textSelectedTime.text = self:GetTimeStr(self.selectedActvityTemplateId)
    self.isListShow = false
    self.goList:SetActive(self.isListShow)
end

function ActivityAllianceBossRegisterTimeChoose:GetTimeStr(activityTemplateId)
    local startTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityTemplateId)
    local sDateTime = TimeFormatter.ToDateTime(startTime.Seconds)
    local timeStr = string.format("UTC %d/%02d/%02d %d:%02d",
        sDateTime.Year, sDateTime.Month, sDateTime.Day, sDateTime.Hour, sDateTime.Minute)
    return timeStr
end

function ActivityAllianceBossRegisterTimeChoose:GetFirstAvaliableActivityTemplateId()
    if self.timeCellData and #self.timeCellData > 0 then
        for _, v in ipairs(self.timeCellData) do
            local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(v.activityTemplateId)
            if endTime.Seconds > g_Game.ServerTime:GetServerTimestampInSeconds() then
                return v.activityTemplateId
            end
        end
    end
    local timePeriodsCount = self.battleCfg:BattleActivityLength()
    for i = 1, timePeriodsCount do
        local activityTemplateId = self.battleCfg:BattleActivity(i)
        local startTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityTemplateId)
        if startTime.Seconds > g_Game.ServerTime:GetServerTimestampInSeconds() then
            return activityTemplateId
        end
    end
    return self.battleCfg:BattleActivity(1)
end

return ActivityAllianceBossRegisterTimeChoose