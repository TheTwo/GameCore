--- scene:scene_league_popup_release_notice

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local InputFieldWithCheckStatus = require("InputFieldWithCheckStatus")
local UIMediatorNames = require("UIMediatorNames")
local FPXSDKBIDefine = require("FPXSDKBIDefine")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceReleaseNoticePopupMediator:BaseUIMediator
---@field new fun():AllianceReleaseNoticePopupMediator
---@field super BaseUIMediator
local AllianceReleaseNoticePopupMediator = class('AllianceReleaseNoticePopupMediator', BaseUIMediator)

function AllianceReleaseNoticePopupMediator:ctor()
    BaseUIMediator.ctor(self)
    self._allowSend = false
end

function AllianceReleaseNoticePopupMediator:OnCreate(param)
    ---@type CommonPopupBackComponent
    self._child_popup_base_m = self:LuaObject("child_popup_base_m")
    self._p_input_title = InputFieldWithCheckStatus.new(self, "p_input_title")
    self._p_input_title:SetStatusTrans("p_status_a_title", "p_status_b_title", "p_status_c_title")
    self._p_input_title:SetCheckFunction(ModuleRefer.AllianceModule.CheckAllianceInfoTitle)
    self._p_input_content = InputFieldWithCheckStatus.new(self, "p_input_content")
    self._p_input_content:SetStatusTrans("p_status_a_content", "p_status_b_content", "p_status_c_abbr")
    self._p_input_content:SetCheckFunction(ModuleRefer.AllianceModule.CheckAllianceInfoContent)
    self._p_btn_detail_content = self:Button("p_btn_detail_content", Delegate.GetOrCreate(self, self.OnClickCheckDetailContent))
    self._p_text_title = self:Text("p_text_title", "alliance_notice_release1")
    self._p_text_content = self:Text("p_text_content", "alliance_notice_release2")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")
end

function AllianceReleaseNoticePopupMediator:OnShow(param)
    self:AddEvents()
end

function AllianceReleaseNoticePopupMediator:OnHide(param)
    self:RemoveEvents()
end

function AllianceReleaseNoticePopupMediator:OnOpened(param)
    self._allowSend = false
    ---@type CommonBackButtonData
    local commonBackButtonData = {}
    commonBackButtonData.title = I18N.Get("alliance_notice_release")
    self._child_popup_base_m:FeedData(commonBackButtonData)
    ---@type BistateButtonParameter
    local bistateButtonParameter = {}
    bistateButtonParameter.onClick = Delegate.GetOrCreate(self, self.OnClickBtnSend)
    bistateButtonParameter.buttonText = I18N.Get("confirm")

    self._child_comp_btn_b:FeedData(bistateButtonParameter)
    self._child_comp_btn_b:SetEnabled(self._allowSend)
end

function AllianceReleaseNoticePopupMediator:AddEvents()
    self._p_input_title:AddEvents()
    self._p_input_content:AddEvents()
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
end

function AllianceReleaseNoticePopupMediator:RemoveEvents()
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
    self._p_input_content:RemoveEvents()
    self._p_input_title:RemoveEvents()
end

function AllianceReleaseNoticePopupMediator:OnClose(data)
    self._p_input_content:Release()
    self._p_input_title:Release()
end

function AllianceReleaseNoticePopupMediator:LateTick(dt)
    local allowSend = false
    allowSend = (self._p_input_title:GetStatus() == InputFieldWithCheckStatus.Status.Pass and self._p_input_content:GetStatus() == InputFieldWithCheckStatus.Status.Pass)
    if allowSend ~= self._allowSend then
        self._allowSend = allowSend
        self._child_comp_btn_b:SetEnabled(self._allowSend)
    end
end

function AllianceReleaseNoticePopupMediator:OnClickBtnSend()
    local titleStatus,title = self._p_input_title:GetInputContent()
    local contentStatus,content = self._p_input_content:GetInputContent()
    if titleStatus ~= InputFieldWithCheckStatus.Status.Pass or contentStatus ~= InputFieldWithCheckStatus.Status.Pass then
        return
    end
    ModuleRefer.AllianceModule:SendReleaseAllianceInfo(title, content, self._child_comp_btn_b:Transform(""), function(cmd, isSuccess, rsp)
        if isSuccess then

            local keyMap = FPXSDKBIDefine.ExtraKey.alliance_notice
            local extraMap = {}
            extraMap[keyMap.notice_text] = content
            extraMap[keyMap.alliance_create_date] = nil
            local _, memberCount = ModuleRefer.AllianceModule:GetMyAllianceOnlineMemberCount()
            extraMap[keyMap.alliance_member_num] = memberCount
            ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.alliance_notice, extraMap)

            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_notice_toast"))
            self:CloseSelf()
        end
    end)
end

function AllianceReleaseNoticePopupMediator:OnClickCheckDetailContent()
    self:CheckAndShowErrorTip(self._p_input_content, self._p_btn_detail_content)
end

---@param input InputFieldWithCheckStatus
---@param target CS.UnityEngine.UI.Button
function AllianceReleaseNoticePopupMediator:CheckAndShowErrorTip(input, target)
    local lastErrorCode,lastError = input:GetLastError()
    if not lastErrorCode or lastErrorCode == 0 then
        return
    end
    ---@type CommonTipPopupMediatorParameter
    local tipParameter = {}
    tipParameter.targetTrans = target:GetComponent(typeof(CS.UnityEngine.RectTransform))
    tipParameter.text = I18N.Get(lastError)
    g_Game.UIManager:Open(UIMediatorNames.CommonTipPopupMediator, tipParameter)
end

return AllianceReleaseNoticePopupMediator