---@class CommonConfirmPopupMediatorDefine
local CommonConfirmPopupMediatorDefine = {}

---@class CommonConfirmPopupMediatorDefine.Style
CommonConfirmPopupMediatorDefine.Style = {
    ExitBtn = 1,
    Confirm = 1 << 1,
    ConfirmAndCancel = 1 << 2,
    Toggle = 1 << 3,
    WithInputCheck = 1 << 4,
    WithResource = 1 << 5,
    WithItems= 1 << 6,
    WarningAndCancel= 1 << 7,
}

return CommonConfirmPopupMediatorDefine

