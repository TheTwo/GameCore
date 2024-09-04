---@class BasePopupBundleListDataProvider
local BasePopupBundleListDataProvider = class("BasePopupBundleListDataProvider")

function BasePopupBundleListDataProvider:ctor()
end

---@return BasePopupBundleListCellParameter[]
function BasePopupBundleListDataProvider:GetCellDatas()
    return {}
end

function BasePopupBundleListDataProvider:GetTitle()
    return string.Empty
end

return BasePopupBundleListDataProvider