local BaseTableViewProCell = require('BaseTableViewProCell')
---@class GiftCompItemCell : BaseTableViewProCell
local GiftCompItemCell = class('GiftCompItemCell',BaseTableViewProCell)

function GiftCompItemCell:ctor()
end

function GiftCompItemCell:OnCreate(param)
    ---@see StarItemIcon
    self.luaStarItem = self:LuaObject('child_item_star_s')
end

---@param data StarItemIconData
function GiftCompItemCell:OnFeedData(data)
    if self.luaStarItem then
        self.luaStarItem:FeedData(data)
    end
end

return GiftCompItemCell