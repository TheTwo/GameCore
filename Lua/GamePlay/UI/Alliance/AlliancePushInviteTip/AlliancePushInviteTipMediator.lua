--- scene:scene_league_toast_join

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceModuleDefine = require("AllianceModuleDefine")

local BaseUIMediator = require("BaseUIMediator")

---@class AlliancePushInviteTipMediatorParameter
---@field allianceInfo wds.AllianceBasicInfo

---@class AlliancePushInviteTipMediator:BaseUIMediator
---@field new fun():AlliancePushInviteTipMediator
---@field super BaseUIMediator
local AlliancePushInviteTipMediator = class('AlliancePushInviteTipMediator', BaseUIMediator)

function AlliancePushInviteTipMediator:OnCreate(param)
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaBaseComponent("child_league_logo")
    self._p_text_league_name = self:Text("p_text_league_name")
    self._p_text_info = self:Text("p_text_info")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_btn_join = self:Button("p_btn_join", Delegate.GetOrCreate(self, self.OnClickJoin))
    self._p_text = self:Text("p_text")
end

---@param param AlliancePushInviteTipMediatorParameter
function AlliancePushInviteTipMediator:OnOpened(param)
    self._parameter = param
    self._child_league_logo:FeedData(param.allianceInfo.Flag)
    self._p_text_league_name.text = ("[%s]%s"):format(param.allianceInfo.Abbr, param.allianceInfo.Name)
    self._p_text_info.text = param.allianceInfo.LeaderName
    if self._parameter.allianceInfo.JoinSetting == AllianceModuleDefine.JoinNeedApply then
        self._p_text.text = I18N.Get("apply")
    else
        self._p_text.text = I18N.Get("join")
    end
end

function AlliancePushInviteTipMediator:OnClickJoin()
    if ModuleRefer.AllianceModule:IsInAlliance() then
        self:CloseSelf()
        return
    end
    local allianceName = self._parameter.allianceInfo.Name
    local needApply = self._parameter.allianceInfo.JoinSetting
    ModuleRefer.AllianceModule:JoinOrApplyAlliance(self._p_btn_join.transform ,self._parameter.allianceInfo.ID, function(cmd, isSuccess, rsp)
        if needApply == AllianceModuleDefine.JoinNeedApply then
            if isSuccess then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("apply_toast", allianceName))
            end
        end
        self:CloseSelf()
    end)
end

function AlliancePushInviteTipMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.CloseSelf))
end

function AlliancePushInviteTipMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.CloseSelf))
end

return AlliancePushInviteTipMediator