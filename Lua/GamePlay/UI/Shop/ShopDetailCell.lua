local BaseTableViewProCell = require('BaseTableViewProCell')
---@class ShopDetailCell : BaseTableViewProCell
local ShopDetailCell = class('ShopDetailCell', BaseTableViewProCell)

function ShopDetailCell:ctor()
end

function ShopDetailCell:OnCreate()
    self.textDesc = self:Text('')
end

---@param data string
function ShopDetailCell:OnFeedData(data)
    self.textDesc.text = data
end

return ShopDetailCell