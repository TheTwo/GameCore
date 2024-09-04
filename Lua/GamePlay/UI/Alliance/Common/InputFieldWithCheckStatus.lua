local Delegate = require("Delegate")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@class InputFieldWithCheckStatus
---@field new fun(host:BaseUIComponent,name:string):InputFieldWithCheckStatus
local InputFieldWithCheckStatus = class('InputFieldWithCheckStatus')
InputFieldWithCheckStatus.DefaultDelay = 0.5

---@class InputFieldWithCheckStatus.Status
InputFieldWithCheckStatus.Status = {
    Init = 0,
    Pass = 1,
    Fail = 2,
    Checking = 3
}
InputFieldWithCheckStatus.ProcessErrorCode = {
    [26004] = "errCode_26004",
    [26006] = "errCode_26006",
    [26007] = "name_require_toast",
    [26008] = "errCode_26008",
    [26009] = "abbr_require_toast",
    [26010] = "errCode_26010",
    [26063] = "errCode_26063",
    [45001] = "errCode_45001",
	[88004] = "playerinfo_modifyname_tips_4",
	[88005] = "playerinfo_modifyname_txt",
	[88007] = "playerinfo_declaration_tips_1",
	[88009] = "playerinfo_modifyname_tips_2",
	[88010] = "playerinfo_declaration_tips_2",
}

---@param host BaseUIComponent
---@param name string
---@param placeholder string
function InputFieldWithCheckStatus:ctor(host, name, placeholder)
    self._host = host
    self._input = host:InputField(name, Delegate.GetOrCreate(self, self.OnInputChanged), Delegate.GetOrCreate(self, self.OnInputEnd), nil, placeholder)
    self._content = self._input.text
    self._allowEmpty = false
    self._tmpContent = self._content
    self._ignoreCallback = false
    self._triggerCheckDelay = nil
    self._currentStatus = InputFieldWithCheckStatus.Status.Init
    ---@type CS.UnityEngine.GameObject[]
    self._statusGo = {}
    self._typingDelayChecking = false
    ---@type fun(text:string,callback:fun(text:string,pass:boolean),simpleErrorOverride:fun(msgId:number,errorCode:number,jsonTable:table):boolean)
    self._checkingFunction = nil
    self._inputEndFlag = false
    self._timerRegister = false
    self._released = false
    ---@private
    self._lastErrorCode = 0
    self._catchAnyErrorAndUseCodeAsLangKey = true
	self._showErrorAsToast = true
    self._customOnInputChanged = nil
    ---@type fun()
    self._customOnBeginCheck = nil
    ---@type fun(pass:boolean)
    self._customOnEndCheck = nil
end

function InputFieldWithCheckStatus:InitContent(text)
    self._ignoreCallback = true
    self._input.text = text
    self._content = self._input.text
    self._tmpContent = self._content
    self._ignoreCallback = false
end

function InputFieldWithCheckStatus:SetAllowEmpty(allowEmpty)
    self._allowEmpty = allowEmpty
end

function InputFieldWithCheckStatus:SetShowErrorAsToast(value)
	self._showErrorAsToast = value
end

---@param limit number
function InputFieldWithCheckStatus:SetCharacterLimit(limit)
    self._input.characterLimit = limit
end

---@param pass string
---@param fail string
---@param checking string
function InputFieldWithCheckStatus:SetStatusTrans(pass, fail, checking)
    self._statusGo[InputFieldWithCheckStatus.Status.Pass] = self._host:GameObject(pass)
    self._statusGo[InputFieldWithCheckStatus.Status.Fail] = self._host:GameObject(fail)
    self._statusGo[InputFieldWithCheckStatus.Status.Checking] = self._host:GameObject(checking)
end

---@param func fun(text:string,callback:fun(text:string,pass:boolean),simpleErrorOverride:fun(msgId:number,errorCode:number,jsonTable:table):boolean)
function InputFieldWithCheckStatus:SetCheckFunction(func)
    self._checkingFunction = func
end

---@param contentType CS.UnityEngine.UI.InputField.ContentType
function InputFieldWithCheckStatus:SetInputContentType(contentType)
    self._input.contentType = contentType
end

---@param func fun(text:string)
function InputFieldWithCheckStatus:SetCustomOnInputChanged(func)
    self._customOnInputChanged = func
end

---@param func fun()
function InputFieldWithCheckStatus:SetCustomOnBeginCheck(func)
    self._customOnBeginCheck = func
end

---@param func fun(pass:boolean)
function InputFieldWithCheckStatus:SetCustomOnEndCheck(func)
    self._customOnEndCheck = func
end

--手动检查 调一下检查一下
---@param func fun()
function InputFieldWithCheckStatus:ManualCheck(func)
    func(self._tmpContent, Delegate.GetOrCreate(self, self.EndCheck), Delegate.GetOrCreate(self, self.EndCheckServerError))
end

function InputFieldWithCheckStatus:GetStatus()
    return self._currentStatus
end

---@return InputFieldWithCheckStatus.Status,string @0 - init | 1 - pass | 2 - fail | 3 - checking
function InputFieldWithCheckStatus:GetInputContent()
    return self._currentStatus, self._content
end

function InputFieldWithCheckStatus:OnInputChanged(text)
    if self._ignoreCallback then
        return
    end
    if self._customOnInputChanged then
        self._customOnInputChanged(text, Delegate.GetOrCreate(self, self.EndCheck), Delegate.GetOrCreate(self, self.EndCheckServerError))
    end
    if not self._typingDelayChecking then
        return
    end
    self._tmpContent = text
    if string.IsNullOrEmpty(text) then
        self._triggerCheckDelay = nil
    else
        self._triggerCheckDelay = InputFieldWithCheckStatus.DefaultDelay
    end
end

function InputFieldWithCheckStatus:OnInputEnd(text)
    if self._ignoreCallback then
        return
    end
    self._tmpContent = text
    self._triggerCheckDelay = nil
    self._inputEndFlag = true
end

function InputFieldWithCheckStatus:TimerRun(delta)
    if not self._timerRegister then
        return
    end
    if self._inputEndFlag then
        self._triggerCheckDelay = nil
        self._inputEndFlag = false
        self:DoProcessTempContent()
        return
    end
    if self._triggerCheckDelay then
        self._triggerCheckDelay = self._triggerCheckDelay - delta
        if self._triggerCheckDelay <= 0 then
            self._triggerCheckDelay = nil
            self:DoProcessTempContent()
        end
    end
end

function InputFieldWithCheckStatus:DoProcessTempContent()
    if string.IsNullOrEmpty(self._tmpContent) and not self._allowEmpty then
        self._content = string.Empty
        self:TransToStatus(InputFieldWithCheckStatus.Status.Init)
    else
        self:TransToStatus(InputFieldWithCheckStatus.Status.Checking)
        self:BeginCheck()
    end
end

function InputFieldWithCheckStatus:Release()
    if self._timerRegister then
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TimerRun))
        self._timerRegister = false
    end
    self._released = true
    self._triggerCheckDelay = nil
    self:TransToStatus(InputFieldWithCheckStatus.Status.Init)
    table.clear(self._statusGo)
    self._host = nil
end

---@param status InputFieldWithCheckStatus.Status
function InputFieldWithCheckStatus:TransToStatus(status)
    if self._currentStatus == status then
        return
    end
    self._currentStatus = status
    for k, v in pairs(self._statusGo) do
        if Utils.IsNotNull(v) then
            v:SetVisible(k == status)
        end
    end
    if (Utils.IsNull(self._input)) then return end
    self._input.interactable = (status ~= InputFieldWithCheckStatus.Status.Checking)
end

function InputFieldWithCheckStatus:BeginCheck()
    self._lastErrorCode = 0
    if self._customOnBeginCheck then
        self._customOnBeginCheck()
    end
    if not self._checkingFunction then
        self:EndCheck(self._tmpContent, true)
    else
        self._checkingFunction(self._tmpContent, Delegate.GetOrCreate(self, self.EndCheck), Delegate.GetOrCreate(self, self.EndCheckServerError))
    end
end

---@param text string
---@param pass boolean
function InputFieldWithCheckStatus:EndCheck(text, pass)
    if self._released then
        return
    end
    self._content = text
    if pass then
        self:TransToStatus(InputFieldWithCheckStatus.Status.Pass)
    else
        self:TransToStatus(InputFieldWithCheckStatus.Status.Fail)
    end
    if self._customOnEndCheck then
        self._customOnEndCheck(pass)
    end
end

---@param msgId number
---@param errorCode number
---@param jsonTable table
---@return boolean
function InputFieldWithCheckStatus:EndCheckServerError(msgId,errorCode,jsonTable)
    local error = InputFieldWithCheckStatus.ProcessErrorCode[errorCode]
    if error then
        self._lastErrorCode = errorCode
		if (self._showErrorAsToast) then
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(error))
		end
        return true
    end
    if self._catchAnyErrorAndUseCodeAsLangKey then
        self._lastErrorCode = errorCode
		if (self._showErrorAsToast) then
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(string.format("errCode_%s", errorCode)))
		end
        return true
    end
end

function InputFieldWithCheckStatus:AddEvents()
    self._timerRegister = true
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TimerRun))
end

function InputFieldWithCheckStatus:RemoveEvents()
    self._timerRegister = false
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TimerRun))
end

---@return number,string
function InputFieldWithCheckStatus:GetLastError()
    if self._lastErrorCode then
        local key = InputFieldWithCheckStatus.ProcessErrorCode[self._lastErrorCode]
        if key then
            return self._lastErrorCode,key
        elseif self._catchAnyErrorAndUseCodeAsLangKey then
            return self._lastErrorCode,string.format("errCode_%s", self._lastErrorCode)
        end
    end
    return 0,""
end

return InputFieldWithCheckStatus
