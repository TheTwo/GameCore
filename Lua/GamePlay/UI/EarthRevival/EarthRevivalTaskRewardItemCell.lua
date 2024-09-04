local BaseItemIconCell = require('BaseItemIconCell')
---@class EarthRevivalTaskRewardItemCell : BaseItemIconCell
local EarthRevivalTaskRewardItemCell = class('EarthRevivalTaskRewardItemCell', BaseItemIconCell)

---@class EarthRevivalTaskRewardItemCellData : ItemIconData
---@field multiplier number

function EarthRevivalTaskRewardItemCell:OnCreate()
    self.super.OnCreate(self)
    self.goTag = self:GameObject('p_discount')
    self.textTag = self:Text('p_text_discount')
end

---@param data EarthRevivalTaskRewardItemCellData
function EarthRevivalTaskRewardItemCell:OnFeedData(data)
    self.super.OnFeedData(self, data)
    if data.multiplier and data.multiplier > 0 then
        self.goTag:SetActive(true)
        self.textTag.text = string.format('%d%', data.multiplier)
    else
        self.goTag:SetActive(false)
    end
end

return EarthRevivalTaskRewardItemCell