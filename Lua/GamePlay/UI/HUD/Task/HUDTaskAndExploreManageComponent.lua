local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local EventConst = require("EventConst")

local I18N = require("I18N")

---@class HUDTaskAndExploreManageComponent:BaseUIComponent
local HUDTaskAndExploreManageComponent = class('HUDTaskAndExploreManageComponent', BaseUIComponent)

function HUDTaskAndExploreManageComponent:OnCreate()
    self._p_btn_open = self:Button("p_btn_open", Delegate.GetOrCreate(self, self.OnClickOpen))

    self._p_group_toggle = self:GameObject("p_group_toggle")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnClickClose))
    self._p_btn_mission = self:Button("p_btn_mission", Delegate.GetOrCreate(self, self.OnClickShowMainTask))
    self._p_select_mission = self:GameObject("p_select_mission")
    self._p_btn_mission_explore = self:Button("p_btn_mission_explore", Delegate.GetOrCreate(self, self.OnClickShowExploreTask))
    self._p_select_mission_explore = self:GameObject("p_select_mission_explore")

    ---@type HUDNewTaskComponent
    self._child_hud_mission = self:LuaObject("child_hud_mission")
    ---@type HUDExploreComponent
    self._p_hud_mission_explore = self:LuaObject("p_hud_mission_explore")
    self.expanded = true

    self._scroll_ctrler = self:BindComponent('p_scroll_mission', typeof(CS.PageViewController))
end

function HUDTaskAndExploreManageComponent:OnShow()
    local myCity = ModuleRefer.CityModule:GetMyCity()
    local showExplore = myCity ~= nil and (myCity:IsInSingleSeExplorerMode() or myCity:IsInSeBattleMode())
    self:UpdatePanel(showExplore)

    if myCity then
        self.city = myCity
        self.city.stateMachine:AddStateChangedListener(Delegate.GetOrCreate(self, self.OnStateChanged))
    end
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged))
    self._scroll_ctrler.onPageChanged = Delegate.GetOrCreate(self, self.OnPageChanged)
end

function HUDTaskAndExploreManageComponent:OnHide()
    if self.city then
        self.city.stateMachine:RemoveStateChangedListener(Delegate.GetOrCreate(self, self.OnStateChanged))
        self.city = nil
    end
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged))

    self._scroll_ctrler.onPageChanged = nil
end

function HUDTaskAndExploreManageComponent:UpdatePanel(showExplore)
    if showExplore == nil then
        showExplore = self.showExplore
    end

    local myCity = ModuleRefer.CityModule:GetMyCity()
    local hideToggle = myCity ~= nil and (myCity:IsInSingleSeExplorerMode() or myCity:IsInSeBattleMode())
    if self.expanded then
        local pageSwtichEnabled = not hideToggle
        local isAllZoneRecovered = self:IsAllZoneRecoverd()
        if hideToggle then
            if isAllZoneRecovered then
                showExplore = false
            end
        end
        if isAllZoneRecovered then
            pageSwtichEnabled = false
        end
        self._scroll_ctrler.enabled = pageSwtichEnabled
        self._p_btn_open:SetVisible(false)
        if hideToggle then
            self._p_group_toggle:SetActive(false)
        else
            self._p_group_toggle:SetActive(not isAllZoneRecovered)
        end

        self._p_hud_mission_explore:SetVisible(not isAllZoneRecovered)
        if not isAllZoneRecovered then
            self._p_hud_mission_explore:UpdatePanel()
        end
        self._child_hud_mission:SetVisible(not hideToggle)

        if showExplore then
            self._p_select_mission:SetVisible(false)
            self._p_select_mission_explore:SetVisible(true)
        else
            self._p_select_mission:SetVisible(true)
            self._p_select_mission_explore:SetVisible(false)
        end
        self.showExplore = showExplore
    else
        self._child_hud_mission:SetVisible(false)
        self._p_hud_mission_explore:SetVisible(false)
        self._p_btn_open:SetVisible(not hideToggle)
        self._p_group_toggle:SetActive(false)
    end
end

function HUDTaskAndExploreManageComponent:OnClickOpen()
    if self.expanded then
        return
    end
    self.expanded = true
    self:UpdatePanel()
end

function HUDTaskAndExploreManageComponent:OnClickClose()
    if not self.expanded then
        return
    end
    self.expanded = false
    self:UpdatePanel()
end

function HUDTaskAndExploreManageComponent:OnClickShowMainTask()
    self._scroll_ctrler:ScrollToPage(0)
    if self.showExplore then
        self:UpdatePanel(false)
    end
end

function HUDTaskAndExploreManageComponent:OnClickShowExploreTask()
    self._scroll_ctrler:ScrollToPage(1)
    if not self.showExplore then
        self:UpdatePanel(true)
    end
end

function HUDTaskAndExploreManageComponent:OnPageChanged(_, index)
    if index == 0 then
        if self.showExplore then
            self:UpdatePanel(false)
        end
    else
        if not self.showExplore then
            self:UpdatePanel(true)
        end
    end
end

function HUDTaskAndExploreManageComponent:OnStateChanged(from, to)
    local CityStateSeExplorerFocus = require("CityStateSeExplorerFocus")
    local CityStateSeBattle = require("CityStateSeBattle")
    if from ~= nil and (from:is(CityStateSeExplorerFocus) or from:is(CityStateSeBattle)) then
        self:UpdatePanel()
        return
    end
    if to ~= nil and (to:is(CityStateSeExplorerFocus) or to:is(CityStateSeBattle)) then
        self:UpdatePanel()
        return
    end
end

function HUDTaskAndExploreManageComponent:OnZoneStatusChanged()
    local allZoneRecovered = self:IsAllZoneRecoverd()
    if allZoneRecovered then
        self:UpdatePanel(false)
    else
        self:UpdatePanel()
    end
end

function HUDTaskAndExploreManageComponent:IsAllZoneRecoverd()
    local myCity = ModuleRefer.CityModule:GetMyCity()
    if not myCity then return true end
    return myCity.zoneManager:IsAllZoneRecoverd()
end

return HUDTaskAndExploreManageComponent