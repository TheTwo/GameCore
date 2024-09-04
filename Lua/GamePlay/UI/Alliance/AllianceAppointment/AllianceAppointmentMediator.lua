--- scene:scene_league_popup_appointment

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local TimerUtility = require("TimerUtility")
local AllianceModuleDefine = require("AllianceModuleDefine")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local BistateButton = require("BistateButton")
local ConfigTimeUtility = require("ConfigTimeUtility")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceAppointmentMediator:BaseUIMediator
---@field new fun():AllianceAppointmentMediator
---@field super BaseUIMediator
local AllianceAppointmentMediator = class('AllianceAppointmentMediator', BaseUIMediator)

function AllianceAppointmentMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type number
    self._playerFacebookId = nil
    ---@type number
    self._playerRank = nil
    ---@type number
    self._selectedRank = nil
end

function AllianceAppointmentMediator:OnCreate(param)
    ---@type CommonPopupBackComponent
    self._child_popup_base_m = self:LuaObject("child_popup_base_m")
    self._p_table = self:TableViewPro("p_table")
    self._p_table:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnRankSelected))
    self._p_text_hint = self:Text("p_text_hint")
    ---@type BistateButton
    self._child_comp_btn_a = self:LuaObject("child_comp_btn_b")
end

function AllianceAppointmentMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.CloseSelf))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_RANK_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceRankChanged))
end

---@param playerData wds.AllianceMember
function AllianceAppointmentMediator:OnOpened(playerData)
    ---@type CommonBackButtonData
    local btnData = {
        title = I18N.Get("position_appoint")
    }
    self._child_popup_base_m:FeedData(btnData)
    ---@type BistateButtonParameter
    local confirmBtnData = {}
    confirmBtnData.buttonText = I18N.Get("confirm")

    confirmBtnData.onClick = Delegate.GetOrCreate(self, self.OnClickBtnConfirm)
    confirmBtnData.disableClick = Delegate.GetOrCreate(self, self.OnClickBtnConfirmDisable)
    confirmBtnData.buttonState = BistateButton.BUTTON_TYPE.BROWN
    self._child_comp_btn_a:FeedData(confirmBtnData)
    if self:OnAllianceRankChanged() then
        return
    end
    if not playerData then
        TimerUtility.DelayExecuteInFrame(function()
            self:CloseSelf()
        end)
        return
    end

    self._playerIsAFK = ModuleRefer.AllianceModule:IsAllianceMemberAFK(playerData)
    self._playerIsNotActive = ModuleRefer.AllianceModule:IsAllianceMemberNotActive(playerData)
    self._playerIsSwitchLeaderTarget = ModuleRefer.AllianceModule:IsAllianceMemberSwitchLeaderTarget(playerData)
    self._playerName = playerData.Name
    self._playerFacebookId = playerData.FacebookID
    self._playerTitle = playerData.Title
    self._playerRank = playerData.Rank
    self._p_table:UnSelectAll()
    self._p_table:Clear()
    local startRank
    if ModuleRefer.AllianceModule:IsAllianceLeader() and playerData.Rank == AllianceModuleDefine.OfficerRank then
        startRank = ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank
    else
        startRank = ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank - 1
    end
    local selectedData
    for i = startRank, 1, -1 do
        local c,m = ModuleRefer.AllianceModule:GetMyAllianceRank2Number(i)
        ---@type AllianceAppointmentCellData
        local cellData = {
            Rank = i,
            IsCurrent = i == playerData.Rank,
            currentCount = c,
            maxCount = m,
        }
        if cellData.IsCurrent then
            selectedData = cellData
        end
        self._p_table:AppendData(cellData)
    end
    if selectedData then
        self._p_table:SetToggleSelect(selectedData)
    end
end

function AllianceAppointmentMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_RANK_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceRankChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.CloseSelf))
end

function AllianceAppointmentMediator:OnAllianceRankChanged(_, _)
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SetMemberRank) then
        TimerUtility.DelayExecuteInFrame(function()
            self:CloseSelf()
        end)
        return true
    end
    return false
end

---@param current AllianceAppointmentCellData
function AllianceAppointmentMediator:OnRankSelected(_, current)
    self._selectedRank = current.Rank
    if (current.maxCount >= 0 and current.Rank ~= AllianceModuleDefine.LeaderRank and current.currentCount >= current.maxCount) or current.IsCurrent then
        self._child_comp_btn_a:SetEnabled(false)
    else
        self._child_comp_btn_a:SetEnabled(true)
    end
    if self._selectedRank == AllianceModuleDefine.LeaderRank then
        self._child_comp_btn_a:SetButtonText(I18N.Get("alliance_retire_transferleader"))
        if self._playerIsSwitchLeaderTarget or self._playerIsAFK then
            self._child_comp_btn_a:SetEnabled(false)
        end
    else
        self._child_comp_btn_a:SetButtonText(I18N.Get("confirm"))
    end
end

function AllianceAppointmentMediator:OnClickBtnConfirm()
    if not self._playerFacebookId or not self._selectedRank then
        return
    end
    local playerFacebookId = self._playerFacebookId
    local selectedRank = self._selectedRank
    local playerOriginRank = self._playerRank
    local playerName = self._playerName
    self:CheckWillLoseTitle(function()
        self:CheckIsTargetLeader(function()
            self:DoChangeRank(playerFacebookId, selectedRank, playerOriginRank, playerName)
            return true
        end)
        return true
    end)
end

function AllianceAppointmentMediator:OnClickBtnConfirmDisable()
    if self._selectedRank == AllianceModuleDefine.LeaderRank then
        if not self._playerIsSwitchLeaderTarget and self._playerIsAFK then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_retire_transleader_makesure3_toast"))
        end
    end
end

function AllianceAppointmentMediator:CheckWillLoseTitle(continue)
    if self._playerRank == AllianceModuleDefine.OfficerRank and self._playerTitle > 0 and self._selectedRank ~= AllianceModuleDefine.OfficerRank then
        local popupParameter = {}
        popupParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        popupParameter.content = I18N.Get("official_cancel_appoint")
        popupParameter.confirmLabel = I18N.Get("confirm")
        popupParameter.cancelLabel = I18N.Get("cancle")
        popupParameter.onConfirm = continue
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, popupParameter)
        return
    end
    continue()
end

function AllianceAppointmentMediator:CheckIsTargetLeader(continue)
    if self._selectedRank == AllianceModuleDefine.LeaderRank then
        if self._playerIsAFK then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_retire_transleader_makesure3_toast"))
            return
        end
        local switchTime = ConfigRefer.AllianceConsts:SwitchLeaderWaitTime()
        local hour = ConfigTimeUtility.NsToSeconds(switchTime) / 60 / 60
        local hourToInteger = math.floor(hour + 0.5)
        local hourStr = (hour - hourToInteger >= 0.1) and ("%0.1f"):format(hour) or ("%d"):format(hourToInteger)
        local contentI18
        if self._playerIsNotActive then
            contentI18 = I18N.GetWithParams("alliance_retire_transleader_makesure2", hourStr)
        else
            contentI18 = I18N.GetWithParams("alliance_retire_transleader_makesure", hourStr)
        end
        ---@type CommonConfirmPopupMediatorParameter
        local popupParameter = {}
        popupParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        popupParameter.content = contentI18
        popupParameter.confirmLabel = I18N.Get("confirm")
        popupParameter.cancelLabel = I18N.Get("cancle")
        popupParameter.onConfirm = continue
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, popupParameter)
    else
        continue()
    end
end

function AllianceAppointmentMediator:DoChangeRank(playerFacebookId, selectedRank, oldRank, playerName)
    if selectedRank == AllianceModuleDefine.LeaderRank then
        ModuleRefer.AllianceModule:SwitchLeader(self._child_comp_btn_a.button.transform, playerFacebookId, function(_, isSuccess, _)
            self:CloseSelf()
        end)
    else
        ModuleRefer.AllianceModule:SetAllianceRank(playerFacebookId, selectedRank, function(_, isSuccess, _)
            if isSuccess then
                local toastKey
                if selectedRank > oldRank then
                    toastKey = "promotion_toast"
                else
                    toastKey = "demoted_toast"
                end
                ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams(toastKey, playerName, AllianceModuleDefine.GetRankName(selectedRank)))
            end
            self:CloseSelf()
        end)
    end
end

return AllianceAppointmentMediator