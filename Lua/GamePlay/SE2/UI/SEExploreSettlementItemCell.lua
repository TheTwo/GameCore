local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class SEExploreSettlementItemCellData
---@field itemConfig ItemConfigCell
---@field count number

---@class SEExploreSettlementItemCell:BaseTableViewProCell
---@field new fun():SEExploreSettlementItemCell
---@field super BaseTableViewProCell
local SEExploreSettlementItemCell = class('SEExploreSettlementItemCell', BaseTableViewProCell)

function SEExploreSettlementItemCell:OnCreate(param)
    ---@type BaseItemIcon
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
end

---@param data SEExploreSettlementItemCellData
function SEExploreSettlementItemCell:OnFeedData(data)
    ---@type ItemIconData
    local itemData = {}
    itemData.configCell = data.itemConfig
    itemData.count = data.count
    itemData.hideBtnDelete = true
    self._child_item_standard_s:FeedData(itemData)
end

return SEExploreSettlementItemCell