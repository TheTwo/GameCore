local ConfigRefer = require("ConfigRefer")
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class GatherInterruptItemCell : BaseTableViewProCell
local GatherInterruptItemCell = class("GatherInterruptItemCell", BaseTableViewProCell)

---@class GatherInterruptItemCellData
---@field id number
---@field count number

function GatherInterruptItemCell:OnCreate()
    ---@type BaseItemIcon
    self.p_child_item = self:LuaObject("p_child_item")
end

---@param data GatherInterruptItemCellData
function GatherInterruptItemCell:OnFeedData(data)
    self.data = data

    ---@type ItemIconData
    local itemData = {}
    itemData.configCell = ConfigRefer.Item:Find(self.data.id)
    itemData.count = self.data.count
    itemData.showCount = true
    itemData.showSelect = false
    self.p_child_item:FeedData(itemData)
end

return GatherInterruptItemCell