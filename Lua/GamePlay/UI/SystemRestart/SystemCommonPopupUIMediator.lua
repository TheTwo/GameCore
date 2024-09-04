---Scene Name : ui_common_popup_login
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require("I18N")

---@class SystemCommonPopupUIMediator:BaseUIMediator
local SystemCommonPopupUIMediator = class('SystemCommonPopupUIMediator', BaseUIMediator)

function SystemCommonPopupUIMediator:OnCreate()
    self._p_title = self:Text("p_title")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnClickClose))
    self._p_text_detail = self:Text("p_text_detail")

    self._p_btn_1 = self:Button("p_btn_1", Delegate.GetOrCreate(self, self.OnClickBtn1))
    self._p_text_btn_1 = self:Text("p_text_btn_1") 
    self._p_btn_2 = self:Button("p_btn_2", Delegate.GetOrCreate(self, self.OnClickBtn2))
    self._p_text_btn_2 = self:Text("p_text_btn_2")
end

---@class SystemCommonPopupUIData
---@field title string
---@field content string
---@field styleBitMask number @1<<0:closeBtn, 1<<1:btn1, 1<<2:btn2
---@field confirmBtnText string
---@field onConfirm fun():boolean @return true to close popup
---@field cancelBtnText string
---@field onCancel fun():boolean @return true to close popup
---@field onClose fun():boolean @return true to close popup

---@param param SystemCommonPopupUIData
function SystemCommonPopupUIMediator:OnOpened(param)
    self._p_title.text = param.title or ""
    self._p_text_detail.text = param.content or ""

    local styleBitMask = param.styleBitMask
    self.onConfirm = param.onConfirm
    self.onCancel = param.onCancel
    self.onClose = param.onClose

    self._p_text_btn_1.text = param.confirmBtnText or I18N.Get("citizen_btn_start")
    self._p_text_btn_2.text = param.cancelBtnText or I18N.Get("citizen_btn_cancel")

    self._p_btn_close:SetVisible((styleBitMask & 1) ~= 0)
    self._p_btn_1:SetVisible((styleBitMask & 2) ~= 0 and type(self.onConfirm) == "function")
    self._p_btn_2:SetVisible((styleBitMask & 4) ~= 0 and type(self.onCancel) == "function")
end

function SystemCommonPopupUIMediator:OnClickBtn1()
    if self.onConfirm and self.onConfirm() then
        self:CloseSelf()
    end
end

function SystemCommonPopupUIMediator:OnClickBtn2()
    if self.onCancel and self.onCancel() then
        self:CloseSelf()
    end
end

function SystemCommonPopupUIMediator:OnClickClose()
    if self.onClose then
        if self.onClose() then
            self:CloseSelf()
        end
    else
        self:CloseSelf()
    end
end

return SystemCommonPopupUIMediator