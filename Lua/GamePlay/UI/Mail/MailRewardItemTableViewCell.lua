local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class MailRewardItemTableViewCell : BaseTableViewProCell
local MailRewardItemTableViewCell = class('MailRewardItemTableViewCell', BaseTableViewProCell)

function MailRewardItemTableViewCell:OnCreate(param)
    ---@type BaseItemIcon
    self.item = self:LuaObject("child_item_standard_s")
end

function MailRewardItemTableViewCell:OnFeedData(param)
    if (not param) then return end
    self.item:FeedData({
        configCell = param.configCell,
        count = param.count,
        received = param.received,
        showTips = param.showTips,
    })
end

return MailRewardItemTableViewCell;
