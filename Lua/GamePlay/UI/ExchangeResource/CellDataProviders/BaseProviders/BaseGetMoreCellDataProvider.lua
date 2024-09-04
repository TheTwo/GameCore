---@class BaseGetMoreCellDataProvider
local BaseGetMoreCellDataProvider = class("BaseGetMoreCellDataProvider")

function BaseGetMoreCellDataProvider:ctor()
    self.holder = nil
end

function BaseGetMoreCellDataProvider:SetHolder(holder)
    self.holder = holder
end

function BaseGetMoreCellDataProvider:GetHolder()
    return self.holder
end

---@return number
function BaseGetMoreCellDataProvider:GetStatusIndex()
    return 2
end

---@return string
function BaseGetMoreCellDataProvider:GetName()
    return string.Empty
end

---@return string
function BaseGetMoreCellDataProvider:GetIcon()
    return string.Empty
end

---@return ItemIconData
function BaseGetMoreCellDataProvider:GetIconData()
    return {}
end

---@return string
function BaseGetMoreCellDataProvider:GetDesc()
    return string.Empty
end

---@return string
function BaseGetMoreCellDataProvider:GetBubbleText()
    return string.Empty
end

function BaseGetMoreCellDataProvider:GetGotoText()
    return string.Empty
end

function BaseGetMoreCellDataProvider:GetExchangeBtnText()
    return string.Empty
end

---@return boolean
function BaseGetMoreCellDataProvider:ShowBubble()
    return false
end

function BaseGetMoreCellDataProvider:ShouldOverrideStatus()
    return false
end

--- 这些函数只有当ShouldOverrideStatus()返回true时生效 ---

function BaseGetMoreCellDataProvider:ShowGoto()
    return false
end

function BaseGetMoreCellDataProvider:ShowExchange()
    return false
end

function BaseGetMoreCellDataProvider:ShowPay()
    return false
end

-------------------------------------------------------

---@return boolean
function BaseGetMoreCellDataProvider:CanExchage()
    return false
end

function BaseGetMoreCellDataProvider:IsItemCell()
    return false
end

function BaseGetMoreCellDataProvider:IsSupplyCell()
    return false
end

function BaseGetMoreCellDataProvider:OnBubbleClick(args)
end

function BaseGetMoreCellDataProvider:OnGoto(args)
end

function BaseGetMoreCellDataProvider:OnUse(args)
end

function BaseGetMoreCellDataProvider:OnPay(args)
end

function BaseGetMoreCellDataProvider:OnExchange(args)
end

function BaseGetMoreCellDataProvider:ShouldTickUpdate()
    return false
end

return BaseGetMoreCellDataProvider