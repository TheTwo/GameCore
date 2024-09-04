
local BaseTableViewProCell = require('BaseTableViewProCell')

---@class CommonSingleQuantityCell:BaseTableViewProCell
local CommonSingleQuantityCell = class('CommonSingleQuantityCell',BaseTableViewProCell)

function CommonSingleQuantityCell:OnCreate()
    self.compChildCommonQuantityL = self:LuaObject('p_CommonSingleQuantity')
end

---@param data ItemIconData|CommonPairsQuantityParameter
function CommonSingleQuantityCell:OnFeedData(data)
    self.compChildCommonQuantityL:FeedData(data)
end

return CommonSingleQuantityCell
