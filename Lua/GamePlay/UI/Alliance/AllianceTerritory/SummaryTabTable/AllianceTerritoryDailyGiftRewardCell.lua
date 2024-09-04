local BaseTableViewProCell = require("BaseTableViewProCell")
local AllianceTerritoryDailyGiftRewardCell = class('AllianceTerritoryDailyGiftRewardCell', BaseTableViewProCell)

function AllianceTerritoryDailyGiftRewardCell:OnCreate(param)
    self.child_item_standard_s = self:LuaObject('child_item_standard_s')
end

function AllianceTerritoryDailyGiftRewardCell:OnFeedData(data)
    self.child_item_standard_s:FeedData(data)
end

return AllianceTerritoryDailyGiftRewardCell