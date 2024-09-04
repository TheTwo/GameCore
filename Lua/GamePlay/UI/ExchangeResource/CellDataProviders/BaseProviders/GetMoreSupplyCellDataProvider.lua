local BaseGetMoreCellDataProvider = require("BaseGetMoreCellDataProvider")
local Utils = require("Utils")
---@class GetMoreSupplyCellDataProvider : BaseGetMoreCellDataProvider
local GetMoreSupplyCellDataProvider = class("GetMoreSupplyCellDataProvider", BaseGetMoreCellDataProvider)

function GetMoreSupplyCellDataProvider:ctor()
    GetMoreSupplyCellDataProvider.super.ctor(self)
    self.items = {}
end

function GetMoreSupplyCellDataProvider:GetStatusIndex()
    return 0
end

function GetMoreSupplyCellDataProvider:OnGoto()
    self:OnSupply()
end

function GetMoreSupplyCellDataProvider:IsSupplyCell()
    return true
end

------------------

function GetMoreSupplyCellDataProvider:SetItemList(itemList)
    Utils.CopyArray(itemList, self.items)
end

function GetMoreSupplyCellDataProvider:GetItemList()
    return self.items
end

---@protected
function GetMoreSupplyCellDataProvider:OnSupply()
end

return GetMoreSupplyCellDataProvider