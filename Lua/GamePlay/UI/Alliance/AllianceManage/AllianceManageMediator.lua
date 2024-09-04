--- scene:scene_league_manage

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
local ConfigRefer = require("ConfigRefer")
local ConfigTimeUtility = require("ConfigTimeUtility")
local DBEntityPath = require("DBEntityPath")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local Utils = require("Utils")
local UIMediatorNames = require('UIMediatorNames')
local BaseUIMediator = require("BaseUIMediator")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")

---@class AllianceManageMediatorParameter
---@field backNoAni boolean
---@field entryTab number
---@field entryTabParam any

---@class AllianceManageMediator:BaseUIMediator
---@field new fun():AllianceManageMediator
---@field super BaseUIMediator
local AllianceManageMediator = class('AllianceManageMediator', BaseUIMediator)

function AllianceManageMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type BaseUIComponent[]
    self._tableComponents = {}
    ---@type CS.FpAnimation.FpAnimationCommonTrigger[]
    self._tableAnimations = {}
    self._currentAllianceId = nil
    self._selectedTabIndex = nil
    self._backNoAni = false
end

function AllianceManageMediator:OnCreate(param)
    ---@type CommonChildTabLeftBtn[]
    self._child_tabs = {}
    ---@type CommonChildTabLeftBtn[]
    self._runtimeTables = {}
    for i = 1, 4 do
        self._child_tabs[i] = self:LuaObject("child_tab_left_btn_" .. tostring(i))
    end
    
    ---@type AllianceManageGroupLog
    self._p_group_log = self:LuaObject("p_group_log")
    ---@type AllianceManageGroupSetting
    self._p_group_setting = self:LuaObject("p_group_setting")
    ---@type AllianceManageGroupList
    self._p_group_leaguelist = self:LuaObject("p_group_leaguelist")
    ---@type AllianceManageGroupDissolve
    self._p_group_dissolve = self:LuaObject("p_group_dissolve")
    ---@type AllianceManageGroupLeave
    self._p_group_leave = self:LuaObject("p_group_leave")
    self._p_group_leave:SetHost(self)
    
    self._p_tips_time = self:GameObject("p_tips_time")
    if self._p_tips_time then
        self._p_tips_time:SetVisible(false)
    end
    ---@type CommonTimer
    self._child_time_tab = self:LuaObject("child_time_tab")
    if self._child_time_tab then
        self._child_time_tab:SetVisible(false)
    end
    
    ---@type CommonBackButtonComponent
    self._child_common_btn_back = self:LuaObject("child_common_btn_back")

    self._p_text_notice = self:Text("p_text_notice","Alliance_notice_release")
    self._p_btn_notice = self:Button("p_btn_notice", Delegate.GetOrCreate(self, self.OnClickBtnNotice))
    self.reddot = self:LuaObject("child_reddot_default")
    if self._p_btn_notice then
        self._p_btn_notice:SetVisible(false)
    end
end

function AllianceManageMediator:SetNotificationReddot()
    -- ModuleRefer.NotificationModule:RemoveFromGameObject(self.reddot.go, false)
    -- local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.Notice, NotificationType.ALLIANCE_MAIN_NOTICE)
    -- ModuleRefer.NotificationModule:AttachToGameObject(node, self.reddot.go, self.reddot.redTextGo, self.reddot.redText)
end

function AllianceManageMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.TickCloseTab))
end

function AllianceManageMediator:OnHide(param)
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.TickCloseTab))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function AllianceManageMediator:CanUseDissolve()
    return true
end

---@param param AllianceManageMediatorParameter
function AllianceManageMediator:OnOpened(param)
    self._backNoAni = param and param.backNoAni or false
    local entryTab = param and param.entryTab or 1
    ---@type CommonBackButtonData
    local commonBackButtonComponentParameter = {}
    commonBackButtonComponentParameter.title = I18N.Get("league_hud_set")
    local exitCall = Delegate.GetOrCreate(self, self.OnClickBackBtn)
    commonBackButtonComponentParameter.onClose = function()
        if self._selectedTabIndex then
            local currentTab = self._tableComponents[self._selectedTabIndex]
            if currentTab and currentTab.CheckBeforeExit then
                if not currentTab:CheckBeforeExit(exitCall) then
                    return
                end
            end
        end
        exitCall()
    end
    self._child_common_btn_back:FeedData(commonBackButtonComponentParameter)
    
    self._currentAllianceId = ModuleRefer.AllianceModule:GetAllianceId()
    table.clear(self._tableComponents)
    table.clear(self._runtimeTables)
    
    ---@type CommonChildTabLeftBtnParameter
    local parameter = {}
    parameter.onClickLocked = function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_no_permission_toast"))
    end
    parameter.onClick = Delegate.GetOrCreate(self, self.OnClickTab)
    parameter.isLocked = false
    
    parameter.index = 1
    parameter.btnName = I18N.Get("alliance_setting_label1")
    parameter.titleText = I18N.Get("alliance_setting_label1")
    self._child_tabs[1]:FeedData(parameter)
    self._runtimeTables[1] = self._child_tabs[1]
    self._tableComponents[1] = self._p_group_log
    self._tableAnimations[1] = self._p_group_log:AnimTrigger("")
    parameter.index = 2
    parameter.btnName = I18N.Get("alliance_setting_label2")
    parameter.titleText = I18N.Get("alliance_setting_label2")
    self._child_tabs[2]:FeedData(parameter)
    self._runtimeTables[2] = self._child_tabs[2]
    self._tableComponents[2] = self._p_group_setting
    self._tableAnimations[2] = self._p_group_setting:AnimTrigger("")
    parameter.index = 3
    parameter.btnName = I18N.Get("alliance_setting_label3")
    parameter.titleText = I18N.Get("alliance_setting_label3")
    self._child_tabs[3]:FeedData(parameter)
    self._runtimeTables[3] = self._child_tabs[3]
    self._tableComponents[3] = self._p_group_leaguelist
    self._tableAnimations[3] = self._p_group_leaguelist:AnimTrigger("")
    parameter.index = 4
    if ModuleRefer.AllianceModule:IsAllianceLeader() then
        if self:CanUseDissolve() then
            parameter.btnName = I18N.Get("alliance_setting_label4")
            parameter.titleText = I18N.Get("alliance_setting_label4")
            self._child_tabs[4]:FeedData(parameter)
            self._runtimeTables[4] = self._child_tabs[4]
            self._tableComponents[4] = self._p_group_dissolve
            self._tableAnimations[4] = self._p_group_dissolve:AnimTrigger("")
        else
            self._child_tabs[4]:SetVisible(false)
            self._p_group_dissolve:SetVisible(false)
        end
    else
        parameter.btnName = I18N.Get("alliance_setting_label5")
        parameter.titleText = I18N.Get("alliance_setting_label5")
        self._child_tabs[4]:FeedData(parameter)
        self._runtimeTables[4] = self._child_tabs[4]
        self._tableComponents[4] = self._p_group_leave
        self._tableAnimations[4] = self._p_group_leave:AnimTrigger("")
    end
    if not self._tableComponents[entryTab] then
        entryTab = 1
    end
    self:OnClickTab(entryTab, param.entryTabParam)
    self:SetNotificationReddot()
end

function AllianceManageMediator:OnClickTab(index, param)
    if self._selectedTabIndex and self._selectedTabIndex ~= index then
        local currentTab = self._tableComponents[self._selectedTabIndex]
        if currentTab and currentTab.CheckBeforeExit then
            if not currentTab:CheckBeforeExit(function()
                self:DoChangeTab(index, param)
            end) then
                return
            end
        end
    end
    self:DoChangeTab(index, param)
end

function AllianceManageMediator:DoChangeTab(index, param)
    self:UpdateTitle(I18N.Get("league_hud_set"))
    self._selectedTabIndex = index
    self._delayChangeTabAni = 0
    self._delayChangeCloseTabIndex = nil
    for i = 1, #self._runtimeTables do
        if i == index then
            self:UpdateTitle(self._runtimeTables[i]:GetTitleString())
            self._runtimeTables[i]:SetStatus(0)
            self._tableComponents[i]:SetVisible(true, param)
            local ani = self._tableAnimations[i]
            if Utils.IsNotNull(ani) then
                ani:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
            end
        else
            self._runtimeTables[i]:SetStatus(1)
            if self._tableComponents[i]:IsShow() then
                local ani = self._tableAnimations[i]
                if Utils.IsNotNull(ani) then
                    local l = ani:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom2)
                    if l > self._delayChangeTabAni then
                        self._delayChangeTabAni = l
                    end
                    ani:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
                    if not self._delayChangeCloseTabIndex then
                        self._delayChangeCloseTabIndex = {}
                    end
                    table.insert(self._delayChangeCloseTabIndex, i)
                else
                    self._tableComponents[i]:SetVisible(false)
                end
            else
                self._tableComponents[i]:SetVisible(false)
            end
        end
    end
end

function AllianceManageMediator:TickCloseTab(dt)
    if not self._delayChangeTabAni then
        return
    end
    self._delayChangeTabAni = self._delayChangeTabAni - dt
    if self._delayChangeTabAni <= 0 then
        self._delayChangeTabAni = nil
        if self._delayChangeCloseTabIndex then
            for i, idx in pairs(self._delayChangeCloseTabIndex) do
                if self._tableComponents[idx] then
                    self._tableComponents[idx]:SetVisible(false)
                end
            end
            self._delayChangeCloseTabIndex = nil
        end
    end
end

function AllianceManageMediator:OnLeaveAlliance(allianceId)
    if self._currentAllianceId and self._currentAllianceId == allianceId then
        self:CloseSelf()
    end
end

function AllianceManageMediator:UpdateTitle(title)
    self._child_common_btn_back:UpdateTitle(title)
end

function AllianceManageMediator:OnClickBackBtn()
    self:BackToPrevious(nil, self._backNoAni, self._backNoAni)
end

function AllianceManageMediator:OnClickBtnNotice()
    ---@type AllianceNoticePopupMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceNoticePopupMediator, param)
end

return AllianceManageMediator