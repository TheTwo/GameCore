local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
---@class AllianceBehemothBattleConfirmBtnFuncProvider
local AllianceBehemothBattleConfirmBtnFuncProvider = class('AllianceBehemothBattleConfirmBtnFuncProvider')

AllianceBehemothBattleConfirmBtnFuncProvider.DisableType = {
    NoTroopReady = 1,
    NotInRange = 2,
    ReadyPlayer = 3,
}

AllianceBehemothBattleConfirmBtnFuncProvider.EnableType = {
    StartBattle = 1,
    ReadyBattle = 2,
}

---@param btn CS.UnityEngine.UI.Button
---@param cage wds.BehemothCage
function AllianceBehemothBattleConfirmBtnFuncProvider:ctor(btn, cage)
    self.btnConfirm = btn
    self.cage = cage
    self.disableFuncMap = {
        [AllianceBehemothBattleConfirmBtnFuncProvider.DisableType.NoTroopReady] = self.DisableBtnFuncNoTroopReady,
        [AllianceBehemothBattleConfirmBtnFuncProvider.DisableType.NotInRange] = self.DisableBtnFuncNotInRange,
        [AllianceBehemothBattleConfirmBtnFuncProvider.DisableType.ReadyPlayer] = self.DisableBtnFuncReadyPlayer,
    }
    self.enableFuncMap = {
        [AllianceBehemothBattleConfirmBtnFuncProvider.EnableType.StartBattle] = self.EnableBtnFuncStartBattle,
        [AllianceBehemothBattleConfirmBtnFuncProvider.EnableType.ReadyBattle] = self.EnableBtnFuncReadyBattle,
    }
end

function AllianceBehemothBattleConfirmBtnFuncProvider:Release()
    self.cage = nil
    self.btnConfirm = nil
    self.disableFuncMap = nil
end

function AllianceBehemothBattleConfirmBtnFuncProvider:DisableBtnFuncNoTroopReady()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("*没有出战成员"))
end

function AllianceBehemothBattleConfirmBtnFuncProvider:DisableBtnFuncNotInRange(hasAuthority)
    if hasAuthority then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_dragtips_open"))
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_dragtips_entercage"))
    end
end

function AllianceBehemothBattleConfirmBtnFuncProvider:DisableBtnFuncReadyPlayer()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_tips_waitopen"))
end

function AllianceBehemothBattleConfirmBtnFuncProvider:OnBtnDisableClick(type, ...)
    if self.disableFuncMap[type] then
        self.disableFuncMap[type](self, ...)
    end
end

function AllianceBehemothBattleConfirmBtnFuncProvider:OnBtnEnableClick(type, ...)
    if self.enableFuncMap[type] then
        self.enableFuncMap[type](self, ...)
    end
end

function AllianceBehemothBattleConfirmBtnFuncProvider:EnableBtnFuncStartBattle(...)
    ---@type CommonConfirmPopupMediatorParameter
    local param = {}
    param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    param.confirmLabel = I18N.Get("confirm")
    param.cancelLabel = I18N.Get("cancle")
    param.content = I18N.Get("alliance_behemoth_pop_open")
    param.onConfirm = function()
        ModuleRefer.AllianceModule.Behemoth:StartBehemothBattleNow(nil, self.cage.ID)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
end

function AllianceBehemothBattleConfirmBtnFuncProvider:EnableBtnFuncReadyBattle(...)
    ModuleRefer.AllianceModule.Behemoth:ReadyBehemothBattleNow(self.btnConfirm.transform, self.cage.ID)
end

return AllianceBehemothBattleConfirmBtnFuncProvider