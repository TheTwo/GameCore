local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class SEClimbTowerSectionRewardTipsCellData
---@field itemIconData ItemIconData

---@class SEClimbTowerSectionRewardTipsCell:BaseTableViewProCell
---@field new fun():SEClimbTowerSectionRewardTipsCell
---@field super BaseTableViewProCell
local SEClimbTowerSectionRewardTipsCell = class('SEClimbTowerSectionRewardTipsCell', BaseTableViewProCell)

function SEClimbTowerSectionRewardTipsCell:OnCreate()
    ---@type BaseItemIcon
    self.commonItemIcon = self:LuaObject('child_item_standard_s_1')
end

---@param data SEClimbTowerSectionRewardTipsCellData
function SEClimbTowerSectionRewardTipsCell:OnFeedData(data)
    self.commonItemIcon:FeedData(data.itemIconData)
end

return SEClimbTowerSectionRewardTipsCell