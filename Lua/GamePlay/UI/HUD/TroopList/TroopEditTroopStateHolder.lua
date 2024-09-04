local HUDTroopStateHolder = require("HUDTroopStateHolder")
local Delegate = require("Delegate")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local CheckTroopTrusteeshipStateDefine = require("CheckTroopTrusteeshipStateDefine")
local HUDTroopUtils = require("HUDTroopUtils")
local TimeFormatter = require("TimeFormatter")
local SlgUtils = require("SlgUtils")
---@class TroopEditTroopStateHolder : HUDTroopStateHolder
local TroopEditTroopStateHolder = class('TroopEditTroopStateHolder', HUDTroopStateHolder)

function TroopEditTroopStateHolder:ctor(cell, presetIndex, locked, empty)
    HUDTroopStateHolder.ctor(self, cell, presetIndex, locked, empty)

    self.p_group_left_base = self.cell:Transform("p_group_troop_status")
    self.p_explore = self.cell:Transform("p_group_troop_status")

    self.p_btn_back = self.cell:Button("p_btn_back", Delegate.GetOrCreate(self, self.OnBackClick))
end

function TroopEditTroopStateHolder:OnBackClick()
    ModuleRefer.TroopModule:RecallTroopPreset(self.index)
end

function TroopEditTroopStateHolder:Show()
    self.p_group_left_base:SetVisible(true)
    self.p_explore:SetVisible(true)
    self:Setup()
end

function TroopEditTroopStateHolder:Hide()
    self.p_group_left_base:SetVisible(false)
    self.p_explore:SetVisible(false)
    self:Release()
end

function TroopEditTroopStateHolder:UpdateUIBySlgData()
    local troopInfo = HUDTroopUtils.GetTroopInfo(self.index)
    if troopInfo then
        if (HUDTroopUtils.GetTroopStates(troopInfo) or {}).Attacking then
            self.p_group_left_base:SetVisible(false)
            self.p_explore:SetVisible(false)
            return
        end
        local showTime = HUDTroopUtils.ShouldShowTroopMoveTime(troopInfo)
        local state = HUDTroopUtils.GetTroopMoveState(troopInfo)
        local destination = HUDTroopUtils.GetTroopMoveDestination(troopInfo)
        local player = ModuleRefer.PlayerModule:GetPlayer()
        if destination == player.Basics.Name then
            destination = I18N.Get("My_city")
        end
        self.p_text_destination.text = destination
        self.p_text_status.text = state

        local isAssembling = troopInfo.preset.Status == wds.TroopPresetStatus.TroopPresetInSignUp
        or troopInfo.preset.Status == wds.TroopPresetStatus.TroopPresetTeamInTrusteeship
        if showTime then
            local endTime = HUDTroopUtils.GetTroopoMoveEndTime(troopInfo)
            local timestamp = g_Game.ServerTime:GetServerTimestampInSeconds()
            local duration = endTime - timestamp
            duration = math.max(duration, 0)
            self.p_text_progress.text = TimeFormatter.SimpleFormatTime(duration)
        else
            if troopInfo.preset.Status == wds.TroopPresetStatus.TroopPresetInSignUp then
                self.p_text_progress.text = I18N.Get("formation_gvealert")
            elseif troopInfo.preset.Status == wds.TroopPresetStatus.TroopPresetTeamInTrusteeship then
                self.p_text_progress.text = I18N.Get("troop_status_8")
            else
                self.p_text_progress.text = HUDTroopUtils.GetTroopNonMoveState(troopInfo)
            end
        end

        self.p_group_left_base:SetVisible(true)
        self.p_explore:SetVisible(true)
        self.p_btn_back.gameObject:SetActive(not HUDTroopUtils.GetTroopStates(troopInfo).BackToCity and not isAssembling)
        return
    end
end

return TroopEditTroopStateHolder