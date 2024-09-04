
local BaseTableViewProCell = require('BaseTableViewProCell')
---@class UIHeroBreakItemCell : BaseTableViewProCell
local UIHeroBreakItemCell = class('UIHeroBreakItemCell',BaseTableViewProCell)

function UIHeroBreakItemCell:OnCreate(param)
    self.compChildCommonQuantity = self:LuaObject('child_common_quantity_l')
end

---@param data ItemIconData
function UIHeroBreakItemCell:OnFeedData(data)
    self.compChildCommonQuantity:FeedData(data)
end

return UIHeroBreakItemCell
