--- scene:scene_common_popup_confirm ---

local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local Delegate = require("Delegate")
local I18N = require("I18N")
local InputFieldWithCheckStatus = require("InputFieldWithCheckStatus")
local UIMediatorNames = require("UIMediatorNames")
local UIHelper = require("UIHelper")
local Utils = require("Utils")

local BaseUIMediator = require("BaseUIMediator")

---@class CommonConfirmPopupMediatorParameter
---@field context any
---@field styleBitMask CommonConfirmPopupMediatorDefine.Style @nil-default CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
---@field title string
---@field content string
---@field contentDescribe string
---@field toggle boolean
---@field toggleDescribe string
---@field toggleClick fun(context:any,check:boolean):boolean
---@field onConfirm fun(context:any):boolean|fun(context:any,inputStatus:InputFieldWithCheckStatus.Status,inputValue:string):boolean
---@field onCancel fun(content:any):boolean
---@field onClose fun(content:any):boolean
---@field forceExecuteOnClose boolean
---@field confirmLabel string
---@field cancelLabel string
---@field inputParameter {initText:string, checkFunc:fun(text:string,callback:fun(text:string,pass:boolean),simpleErrorOverride:fun(msgId:number,errorCode:number,jsonTable:table):boolean), contentType:CS.UnityEngine.UI.InputField.ContentType}
---@field resourceParameter CommonResourceRequirementComponentParameter
---@field items CommonPairsQuantityParameter[]

---@class CommonConfirmPopupMediator:BaseUIMediator
---@field new fun():CommonConfirmPopupMediator
---@field super BaseUIMediator
local CommonConfirmPopupMediator = class('CommonConfirmPopupMediator', BaseUIMediator)

function CommonConfirmPopupMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type CommonConfirmPopupMediatorParameter
    self._parameter = nil
    self._useInputCheck = false
    self._lastInputStatus = nil
end

function CommonConfirmPopupMediator:OnCreate(param)
    -- self._p_title = self:Text("p_title")
    -- self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnClickClose))
    ---@type CommonPopupBackSmallComponent
    self._p_back = self:LuaObject('child_popup_base_s')
    self._p_text_confirm_detail = self:LuaObject('p_text_confirm_detail')
    self._p_text_detail_2 = self:Text("p_text_detail_2")
    self._p_remind = self:Transform("p_remind")
    self._child_toggle = self:Toggle("child_toggle", Delegate.GetOrCreate(self, self.OnToggleValueChanged))
    self._p_text_hint = self:Text("p_text_hint")
    self._p_group_btn_b = self:Transform("p_group_btn_b")
    self._p_btn_confirm_b = self:Button("p_btn_confirm_b", Delegate.GetOrCreate(self, self.OnClickConfirm))
    self._p_btn_confirm_b_lb = self:Text("p_btn_confirm_b_lb")

    self._p_group_btn_a = self:Transform("p_group_btn_a")
    self._p_btn_confirm_a = self:Button("p_btn_confirm_a", Delegate.GetOrCreate(self, self.OnClickConfirm))
    self._p_btn_confirm_a_lb = self:Text("p_text")

    self._p_btn_warning = self:Button("p_btn_warning", Delegate.GetOrCreate(self, self.OnClickConfirm))
    self._p_text_warning = self:Text("p_text_warning")

    self._p_btn_cancel = self:Button("p_btn_cancel", Delegate.GetOrCreate(self, self.OnClickCancel))
    self._p_btn_cancel_lb = self:Text("p_btn_cancel_lb")

    self._p_input_abbr = self:Transform("p_input_abbr")
    self._p_btn_detail_input_error = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickBtnErrorDetail))

    self.goTableResources = self:GameObject('p_table_resources')
    self.tableviewproTableResources = self:TableViewPro('p_table_resources')

    ---@type CommonResourceRequirementComponent
    self._child_resource_a = self:LuaObject("child_resource_a")
    ---@type CommonResourceRequirementComponent
    self._child_resource_b = self:LuaObject("child_resource_b")
end

---@param param CommonConfirmPopupMediatorParameter
function CommonConfirmPopupMediator:OnOpened(param)
    self._parameter = param
    self._onCloseExecuted = false
    self:UpdateUI()
end

function CommonConfirmPopupMediator:OnClose()
    if self._parameter and self._parameter.onClose and self._parameter.forceExecuteOnClose and not self._onCloseExecuted then
        self._parameter.onClose(self._parameter.context)
    end
end

function CommonConfirmPopupMediator:UpdateUI()
	self._parameter.styleBitMask = self._parameter.styleBitMask or CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    local parameter = self._parameter

    --self._p_title.text = parameter.title
    self._p_text_confirm_detail:FeedData({text = parameter.content})
    self._p_text_detail_2.text = parameter.contentDescribe

    local style = self._parameter.styleBitMask
    local showExit = (style & CommonConfirmPopupMediatorDefine.Style.ExitBtn) ~= 0
    local showBtnGroupA = ((style & CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel) ~= 0) or ((style & CommonConfirmPopupMediatorDefine.Style.WarningAndCancel) ~= 0)
    local groupAShowConfirm = (style & CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel) ~= 0
    local groupAShowWarning = (style & CommonConfirmPopupMediatorDefine.Style.WarningAndCancel) ~= 0
    local showBtnGroupB = (style & CommonConfirmPopupMediatorDefine.Style.Confirm) ~= 0
    local showToggle = (style & CommonConfirmPopupMediatorDefine.Style.Toggle) ~= 0
    local showResource = (style & CommonConfirmPopupMediatorDefine.Style.WithResource) ~= 0
    local showItems = (style & CommonConfirmPopupMediatorDefine.Style.WithItems) ~= 0
    self._useInputCheck = (style & CommonConfirmPopupMediatorDefine.Style.WithInputCheck) ~= 0
    self._onChangedCheck = parameter.onChangedCheck
    self._onBeginCheck = parameter.onBeginCheck

    self._lastInputStatus = nil
    if showBtnGroupA then
        self._p_btn_confirm_a_lb.text = parameter.confirmLabel or I18N.Get("citizen_btn_start")
        if Utils.IsNotNull(self._p_text_warning) then
            self._p_text_warning.text = parameter.confirmLabel or I18N.Get("citizen_btn_start")
        end
        self._p_btn_cancel_lb.text = parameter.cancelLabel or I18N.Get("citizen_btn_cancel")
    end
    self._p_btn_confirm_a:SetVisible(groupAShowConfirm)
    if Utils.IsNotNull(self._p_text_warning) then
        self._p_btn_warning:SetVisible(groupAShowWarning)
    else
        self._p_btn_confirm_a:SetVisible(groupAShowWarning)
    end
    if showBtnGroupB then
        self._p_btn_confirm_b_lb.text = parameter.confirmLabel or I18N.Get("citizen_btn_start")
    end
    if showToggle then
        self._child_toggle:SetIsOnWithoutNotify(parameter.toggle)
        self._p_text_hint.text = parameter.toggleDescribe
    end
    if showResource and parameter.resourceParameter then
        if showBtnGroupA then
            self._child_resource_a:SetVisible(true)
            self._child_resource_b:SetVisible(false)
            ---@type CommonResourceRequirementComponentParameter
            local resParameter = {}
            for i, v in pairs(parameter.resourceParameter) do
                resParameter[i] = v
            end
            resParameter.iconComponent = "p_icon_capsule"
            resParameter.numberComponent = "p_text"
            resParameter.normalColor = CS.UnityEngine.Color.white
            resParameter.notEnoughColor = CS.UnityEngine.Color.red
            self._child_resource_a:FeedData(resParameter)
        elseif showBtnGroupB then
            self._child_resource_a:SetVisible(false)
            self._child_resource_b:SetVisible(true)
            ---@type CommonResourceRequirementComponentParameter
            local resParameter = {}
            for i, v in pairs(parameter.resourceParameter) do
                resParameter[i] = v
            end
            resParameter.iconComponent = "p_icon_capsule"
            resParameter.numberComponent = "p_text"
            resParameter.normalColor = CS.UnityEngine.Color.white
            resParameter.notEnoughColor = CS.UnityEngine.Color.red
            self._child_resource_b:FeedData(resParameter)
        end
    else
        self._child_resource_a:SetVisible(false)
        self._child_resource_b:SetVisible(false)
    end
    -- self._p_btn_close:SetVisible(showExit)
    self._p_group_btn_a:SetVisible(showBtnGroupA)
    self._p_group_btn_b:SetVisible(showBtnGroupB)
    self._p_remind:SetVisible(showToggle)
    self._p_input_abbr:SetVisible(self._useInputCheck)

    if self._inputCheck then
        self._inputCheck:RemoveEvents()
        self._inputCheck:SetCheckFunction(nil)
        self._inputCheck:Release()
        self._inputCheck = nil
    end
    if self._useInputCheck then
        self._inputCheck = InputFieldWithCheckStatus.new(self,"p_input_abbr")
        self._inputCheck:SetStatusTrans("p_status_a_abbr", "p_status_b_abbr", "p_status_c_abbr")
        self._inputCheck:InitContent(parameter.inputParameter.initText)
        self._inputCheck:AddEvents()
        self._inputCheck:SetCheckFunction(parameter.inputParameter.checkFunc)
        if self._onChangedCheck then
            self._inputCheck:SetCustomOnInputChanged(parameter.inputParameter.checkFunc)
        end
        if self._onBeginCheck then
            self._inputCheck:ManualCheck(parameter.inputParameter.checkFunc)
        end
        if parameter.inputParameter.contentType then
            self._inputCheck:SetInputContentType(parameter.inputParameter.contentType)
        end
    end

    ---@type CommonBackButtonData
    local backData = {
        title = parameter.title,
        hideClose = not showExit,
        onClose = Delegate.GetOrCreate(self, self.OnClickClose)
    }
    self._p_back:FeedData(backData)
    if showItems then
        self.goTableResources:SetActive(true)
        self.tableviewproTableResources:Clear()
        for _, item in ipairs(self._parameter.items) do
            if item.useColor1 == nil then
                item.useColor1 = true
            end
            self.tableviewproTableResources:AppendData(item)
        end
    else
        self.goTableResources:SetActive(false)
    end
end

function CommonConfirmPopupMediator:OnShow(param)
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CommonConfirmPopupMediator:OnHide(param)
    if self._inputCheck then
        self._inputCheck:RemoveEvents()
        self._inputCheck:SetCheckFunction(nil)
        self._inputCheck:Release()
        self._inputCheck = nil
    end
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CommonConfirmPopupMediator:OnClickConfirm()
    if self._useInputCheck then
        if self._parameter.onConfirm(self._parameter.context, self._inputCheck:GetInputContent()) then
            self:CloseSelf(nil,self._parameter.forceClose)
        end
    else
        if self._parameter.onConfirm(self._parameter.context) then
            self:CloseSelf(nil,self._parameter.forceClose)
        end
    end
end

function CommonConfirmPopupMediator:OnClickCancel()
    if self._parameter.onCancel then
        if self._parameter.onCancel(self._parameter.context) then
            self:CloseSelf(nil,self._parameter.forceClose)
        end
    else
        self:CloseSelf(nil,self._parameter.forceClose)
    end
end

function CommonConfirmPopupMediator:OnClickClose()
    if self._parameter.onClose then
        if self._parameter.onClose(self._parameter.context) then
            self._onCloseExecuted = true
            self:CloseSelf(nil,self._parameter.forceClose)
        end
    else
        self:CloseSelf(nil,self._parameter.forceClose)
    end
end

function CommonConfirmPopupMediator:OnToggleValueChanged(isChecked)
    if self._parameter.toggleClick then
        self._child_toggle:SetIsOnWithoutNotify(self._parameter.toggleClick(self._parameter.context, isChecked))
    end
end

function CommonConfirmPopupMediator:OnClickBtnErrorDetail()
    self:CheckAndShowErrorTip(self._inputCheck, self._p_btn_detail_input_error)
end

---@param input InputFieldWithCheckStatus
---@param target CS.UnityEngine.UI.Button
function CommonConfirmPopupMediator:CheckAndShowErrorTip(input, target)
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

function CommonConfirmPopupMediator:Tick(dt)
    if not self._useInputCheck or not self._inputCheck then
        return
    end
    local status = self._inputCheck:GetStatus()
    if self._lastInputStatus == status then
        return
    end
    self._lastInputStatus = status
    if status ~= InputFieldWithCheckStatus.Status.Pass then
        UIHelper.SetGray(self._p_btn_confirm_a.gameObject, true)
    else
        UIHelper.SetGray(self._p_btn_confirm_a.gameObject, false)
    end
end

return CommonConfirmPopupMediator

