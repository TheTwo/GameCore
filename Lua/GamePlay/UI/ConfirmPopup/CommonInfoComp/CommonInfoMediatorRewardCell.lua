local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CommonInfoMediatorRewardCell : BaseTableViewProCell
local CommonInfoMediatorRewardCell = class('CommonInfoMediatorRewardCell', BaseTableViewProCell)

function CommonInfoMediatorRewardCell:OnCreate()
    ---@type BaseItemIcon
    self.child_item_standard_s = self:LuaObject('child_item_standard_s')
end

function CommonInfoMediatorRewardCell:OnShow()
end

function CommonInfoMediatorRewardCell:OnHide()
end

function CommonInfoMediatorRewardCell:OnFeedData(param)
    self.child_item_standard_s:FeedData(param)
end

return CommonInfoMediatorRewardCell
