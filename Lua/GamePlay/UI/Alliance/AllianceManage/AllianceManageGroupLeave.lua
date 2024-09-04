local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local Utils = require("Utils")
local CityAttrType = require("CityAttrType")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceManageGroupLeave:BaseUIComponent
---@field new fun():AllianceManageGroupLeave
---@field super BaseUIComponent
local AllianceManageGroupLeave = class('AllianceManageGroupLeave', BaseUIComponent)

function AllianceManageGroupLeave:ctor()
    BaseUIComponent.ctor(self)
    ---@type BaseUIMediator
    self._host = nil
end

---@param host BaseUIMediator
function AllianceManageGroupLeave:SetHost(host)
    self._host = host
end

function AllianceManageGroupLeave:OnCreate(param)
    self._p_text_hint_leave = self:Text("p_text_hint_leave", "alliance_setting_leave_toast")
    self._p_text_hint_detail_1 = self:Text("p_text_hint_detail_1", "alliance_setting_leave_toast1")
    self._p_text_hint_detail_2 = self:Text("p_text_hint_detail_2", "alliance_setting_leave_toast2")
    self._p_text_hint_detail_3 = self:Text("p_text_hint_detail_3", "alliance_setting_leave_toast3")
    self._p_comp_btn_leave = self:Button("p_comp_btn_leave", Delegate.GetOrCreate(self, self.OnClickLeaveBtn))
    self._p_text = self:Text("p_text", "alliance_setting_label5")
    self._p_leader_hint = self:GameObject("p_leader_hint")
    if Utils.IsNotNull(self._p_leader_hint) then
        self._p_leader_hint:SetVisible(false)
    end
end

function AllianceManageGroupLeave:OnClickLeaveBtn()
    if ModuleRefer.AllianceModule:IsInBattleActivityWar() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Temp().toast_in_battle_no_quit)
        return
    end
    local joinCD = ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.JoinAllianceCd)
    local joinCDMinute = joinCD // 60
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    parameter.content = I18N.GetWithParams("alliance_exit_time_cd", joinCDMinute)
    parameter.confirmLabel = I18N.Get("confirm")
    parameter.cancelLabel = I18N.Get("cancle")
    parameter.onConfirm = Delegate.GetOrCreate(self, self.OnConfirmLeaveAlliance)
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
end

function AllianceManageGroupLeave:OnConfirmLeaveAlliance()
    if ModuleRefer.AllianceModule:IsInBattleActivityWar() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Temp().toast_in_battle_no_quit)
        return false
    end
    ModuleRefer.AllianceModule:LeaveAlliance(function(cmd, isSuccess, rsp)
        if isSuccess then
            self._host:CloseSelf()
            g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
        end
    end)
    return true
end

return AllianceManageGroupLeave