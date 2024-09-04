local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class SEHudJoyStickBagItemCellData
---@field bagMgr SESceneBagManager
---@field itemId number

---@class SEHudJoyStickBagItemCell:BaseTableViewProCell
---@field new fun():SEHudJoyStickBagItemCell
---@field super BaseTableViewProCell
local SEHudJoyStickBagItemCell = class('SEHudJoyStickBagItemCell', BaseTableViewProCell)

function SEHudJoyStickBagItemCell:ctor()
    SEHudJoyStickBagItemCell.super.ctor(self)
    self._itemHandle = nil
    self._data = nil
    self._itemConfig = nil
end

function SEHudJoyStickBagItemCell:OnCreate(param)
    ---@type BaseItemIcon
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
end

---@param data SEHudJoyStickBagItemCellData
function SEHudJoyStickBagItemCell:OnFeedData(data)
    self:ReleaseLastItemHandle()
    self._data = data
    local mgr = data.bagMgr
    local itemId = data.itemId
    self._itemConfig = ConfigRefer.Item:Find(data.itemId)
    self._itemHandle = mgr:AddCountChangeListener(itemId, Delegate.GetOrCreate(self, self.OnItemCountChanged))
    self:OnItemCountChanged()
end

function SEHudJoyStickBagItemCell:OnRecycle(param)
    self:ReleaseLastItemHandle()
end

function SEHudJoyStickBagItemCell:OnClose(param)
    self:ReleaseLastItemHandle()
end

function SEHudJoyStickBagItemCell:ReleaseLastItemHandle()
    local v = self._itemHandle
    self._itemHandle = nil
    if v then
        v()
    end
end

function SEHudJoyStickBagItemCell:OnItemCountChanged()
    local mgr = self._data.bagMgr
    local itemId = self._data.itemId
    ---@type ItemIconData
    local cellData = {}
    cellData.configCell = self._itemConfig
    cellData.count = mgr:GetAmountByConfigId(itemId)
    cellData.hideBtnDelete = true
    self._child_item_standard_s:FeedData(cellData)
end

return SEHudJoyStickBagItemCell