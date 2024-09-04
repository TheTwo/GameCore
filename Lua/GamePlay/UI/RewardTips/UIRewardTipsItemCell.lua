local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require("ConfigRefer")

---@class UIRewardTipsItemCell : BaseTableViewProCell
local UIRewardTipsItemCell = class('UIRewardTipsItemCell',BaseTableViewProCell)

function UIRewardTipsItemCell:OnCreate()
    ---@type BaseItemIcon
    self.baseIcon = self:LuaObject("child_item_standard_s")
end

---@param data wds.RewardBoxAttachment
function UIRewardTipsItemCell:OnFeedData(data)
    self.data = data

    self:Refresh()
end

function UIRewardTipsItemCell:Refresh()
    if self.baseIcon then
        local itemCell = ConfigRefer.Item:Find(self.data.ItemID)
        if itemCell then
            self.baseIcon:FeedData(
                {
                    configCell = itemCell,
                    count = self.data.ItemNum,
                    showTips = true,
                    showRecommend = false
                }
            )
        end
    end
end

return UIRewardTipsItemCell