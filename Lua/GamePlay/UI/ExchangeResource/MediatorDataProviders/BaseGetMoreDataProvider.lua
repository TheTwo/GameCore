local Utils = require("Utils")
---@class BaseGetMoreDataProvider
local BaseGetMoreDataProvider = class("BaseGetMoreDataProvider")

---@class GetMoreCellData
---@field provider BaseGetMoreCellDataProvider
---@field cellType number

function BaseGetMoreDataProvider:ctor()
    self.holder = nil
    self.items = {}
end

function BaseGetMoreDataProvider:SetHolder(holder)
    self.holder = holder
end

function BaseGetMoreDataProvider:GetHolder()
    return self.holder
end

function BaseGetMoreDataProvider:SetItemList(itemList)
    Utils.CopyArray(itemList, self.items)
end

function BaseGetMoreDataProvider:GetItemList()
    return self.items
end

---@return string
function BaseGetMoreDataProvider:GetTitle()
    return string.Empty
end

---@return GetMoreCellData[]
function BaseGetMoreDataProvider:GetCellDatas()
    return {}
end

function BaseGetMoreDataProvider:GetProgress()
    return 0
end

function BaseGetMoreDataProvider:GetProgressStr()
    return string.Empty
end

function BaseGetMoreDataProvider:ShowProgress()
    return true
end

function BaseGetMoreDataProvider:OnPay(transform)
end

return BaseGetMoreDataProvider