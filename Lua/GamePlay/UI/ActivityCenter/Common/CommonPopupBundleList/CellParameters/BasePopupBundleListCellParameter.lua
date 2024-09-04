---@class BasePopupBundleListCellParameter
local BasePopupBundleListCellParameter = class("BasePopupBundleListCellParameter")

function BasePopupBundleListCellParameter:ctor()
end

---@return string
function BasePopupBundleListCellParameter:GetName()
    return string.Empty
end

---@return ItemIconData[]
function BasePopupBundleListCellParameter:GetRewards()
    return {}
end

---@return string
function BasePopupBundleListCellParameter:GetFreeButtonEnableText()
    return string.Empty
end

---@return string
function BasePopupBundleListCellParameter:GetFreeButtonDisableText()
    return string.Empty
end

---@return string
function BasePopupBundleListCellParameter:GetPurchaseButtonText()
    return string.Empty
end

---@return string, number, number
function BasePopupBundleListCellParameter:GetPurchaseButtonItemInfo()
    return nil
end

---@return string
function BasePopupBundleListCellParameter:GetSoldOutText()
    return string.Empty
end

---@return CommonDiscountTagParam
function BasePopupBundleListCellParameter:GetDiscountTagParam()
    return {}
end

---如果使用红点系统管理红点，实现此方法
---@return NotificationNode
function BasePopupBundleListCellParameter:GetNotificationNode()
    return nil
end

---如果手动管理红点，实现此方法
---@return boolean
function BasePopupBundleListCellParameter:HasNotify()
    return false
end

---@return boolean
function BasePopupBundleListCellParameter:IsSoldOut()
    return false
end

---@return boolean
function BasePopupBundleListCellParameter:CanShowFreeBtn()
    return false
end

---@return boolean
function BasePopupBundleListCellParameter:IsFreeButtonEnable()
    return false
end

function BasePopupBundleListCellParameter:OnClickFreeButtonEnable()
end

function BasePopupBundleListCellParameter:OnClickFreeButtonDisable()
end

function BasePopupBundleListCellParameter:OnClickPurchaseButton()
end

return BasePopupBundleListCellParameter