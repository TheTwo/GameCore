local BaseUIMediator = require("BaseUIMediator")
local I18N = require("I18N")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local InputFieldWithCheckStatus = require("InputFieldWithCheckStatus")
local ClientDataKeys = require("ClientDataKeys")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local TimeFormatter = require("TimeFormatter")
local UpdateRecruitTimeParameter = require("UpdateRecruitTimeParameter")
---@class AllianceRecruitSettingMediator:BaseUIMediator
---@field super BaseUIMediator
local AllianceRecruitSettingMediator = class("AllianceRecruitSettingMediator", BaseUIMediator)

---@class AllianceRecruitSettingMediatorParam
---@field showSend boolean

function AllianceRecruitSettingMediator:ctor()
    AllianceRecruitSettingMediator.super.ctor(self)
    self._inSendCd = false
end

function AllianceRecruitSettingMediator:OnCreate()
    ---@see CommonPopupBackSmallComponent
    self.luaBackGround = self:LuaObject("child_popup_base_s")
    self.textHint = self:Text("p_text_hint", "alliance_recruit_default_tips")
    self.textLimit = self:Text("p_text_limit")
    self.inputWelcome = InputFieldWithCheckStatus.new(self, "p_input_welcome")
    self.inputWelcome:SetStatusTrans("p_status_a_abbr", "p_status_b_abbr", "p_status_c_abbr")
    self.inputWelcome:SetCheckFunction(ModuleRefer.AllianceModule.CheckAllianceRecruitMsg)
    self.textSave = self:Text("p_text_save", "alliance_recruit_Shout_save")
    self.btnSave = self:Button("p_btn_save", Delegate.GetOrCreate(self, self.OnBtnSaveClicked))
    self.textSend = self:Text("p_text_send", "alliance_recruit_Shout_send")
    self.btnSend = self:Button("p_btn_send", Delegate.GetOrCreate(self, self.OnBtnSendClicked))
    self.btnInfo = self:Button("p_btn_info", Delegate.GetOrCreate(self, self.OnBtnInfoClicked))
end

---@param param AllianceRecruitSettingMediatorParam
function AllianceRecruitSettingMediator:OnOpened(param)
    if not param then
        param = {}
    end
    if (param or {}).showSend == nil then
        param.showSend = true
    end
    self.inputWelcome:SetCustomOnInputChanged(Delegate.GetOrCreate(self, self.OnInputChanged))
    self.inputWelcome:SetCustomOnBeginCheck(Delegate.GetOrCreate(self, self.OnBeginCheck))
    self.inputWelcome:SetCustomOnEndCheck(Delegate.GetOrCreate(self, self.OnEndCheck))
    self.inputWelcome:SetCharacterLimit(ConfigRefer.AllianceConsts:AllianceRecruitMsgLenMax())
    self.inputWelcome:InitContent(ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.AllianceRecruitMsg) or I18N.Get("alliance_recruit_default_Shout"))
    self.inputWelcome:AddEvents()
    self.btnSend.gameObject:SetActive(param.showSend)
    self.luaBackGround:FeedData({title = "alliance_recruit_Shout_chat_title"})
    self.startTick = false
end

function AllianceRecruitSettingMediator:OnShow()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    self:OnTick(0)
end

function AllianceRecruitSettingMediator:OnHide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function AllianceRecruitSettingMediator:OnClose()
    self.inputWelcome:SetCustomOnInputChanged(nil)
    self.inputWelcome:SetCustomOnBeginCheck(nil)
    self.inputWelcome:SetCustomOnEndCheck(nil)
    self.inputWelcome:RemoveEvents()
    self.inputWelcome:Release()
end

function AllianceRecruitSettingMediator:OnInputChanged()
    local len = utf8.len(self.inputWelcome._input.text)
    local maxLen = ConfigRefer.AllianceConsts:AllianceRecruitMsgLenMax()
    self.textLimit.text = string.format("%d/%d", len, (maxLen or 0))
    if len > maxLen then
        self.inputWelcome._input.text = string.sub(self.inputWelcome._input.text, 1, maxLen)
    end
end

function AllianceRecruitSettingMediator:OnBeginCheck()
    self:SetAllowSave(false)
    self:SetAllowSend(false)
end

function AllianceRecruitSettingMediator:OnEndCheck(pass)
    self:SetAllowSave(pass)
    self:SetAllowSend(pass and not self._inSendCd)
end

function AllianceRecruitSettingMediator:OnBtnSaveClicked()
    ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.AllianceRecruitMsg, self.inputWelcome._input.text)
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("newformation_savesuccess"))
end

function AllianceRecruitSettingMediator:OnBtnSendClicked()
    local sendMsg = UpdateRecruitTimeParameter.new()
    local lockTrans = {self.btnSend.transform, self.btnSave.transform}
    sendMsg:SendOnceCallback(lockTrans, nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            local sessionId = ModuleRefer.ChatModule:GetWorldSession().SessionId
            ---@type AllianceRecruitMsgParam
            local data = {}
            data.allianceId = ModuleRefer.AllianceModule:GetAllianceId()
            data.content = self.inputWelcome._input.text
            ModuleRefer.ChatModule:SendAllianceRecruitMsg(sessionId, data)
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_recruit_Shout_tips"))
            ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.AllianceRecruitMsg, data.content)
            self:CloseSelf()
        end
    end)
end

function AllianceRecruitSettingMediator:OnBtnInfoClicked()
    ---@type TextToastMediatorParameter
    local data = {}
    data.clickTransform = self.btnInfo.transform
    data.content = I18N.Get("alliance_recruit_Shout_rule")
    ModuleRefer.ToastModule:ShowTextToast(data)
end

function AllianceRecruitSettingMediator:SetAllowSave(allow)
    self.btnSave.interactable = allow
    UIHelper.SetGray(self.btnSave.gameObject, not allow)
end

function AllianceRecruitSettingMediator:SetAllowSend(allow)
    self.btnSend.interactable = allow
    UIHelper.SetGray(self.btnSend.gameObject, not allow)
end

function AllianceRecruitSettingMediator:OnTick(dt)
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceBasicInfo()
    local canSendTime = allianceInfo and allianceInfo.RecruitTime.ServerSecond
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local inSendCd = not canSendTime or canSendTime > nowTime
    if self._inSendCd ~= inSendCd then
        self._inSendCd = inSendCd
        if not self._inSendCd then
            self.textSend.text = I18N.Get("alliance_recruit_Shout_send")
        end
    end
    if self._inSendCd then
        local leftTime = canSendTime - nowTime
        self.textSend.text = TimeFormatter.SimpleFormatTime(leftTime)
    end
    local inputStatus, content = self.inputWelcome:GetInputContent()
    if inputStatus == InputFieldWithCheckStatus.Status.Pass or (inputStatus == InputFieldWithCheckStatus.Status.Init and not string.IsNullOrEmpty(content)) then
        self:SetAllowSave(true)
        self:SetAllowSend(not self._inSendCd)
    elseif inputStatus ~= InputFieldWithCheckStatus.Status.Checking then
        self:SetAllowSave(false)
        self:SetAllowSend(false)
    end
end

return AllianceRecruitSettingMediator