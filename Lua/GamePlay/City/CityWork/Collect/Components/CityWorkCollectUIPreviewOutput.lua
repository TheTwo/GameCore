local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityWorkCollectUIPreviewOutput:BaseTableViewProCell
local CityWorkCollectUIPreviewOutput = class('CityWorkCollectUIPreviewOutput', BaseTableViewProCell)

function CityWorkCollectUIPreviewOutput:OnCreate()
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
end

---@param data ItemConfigCell
function CityWorkCollectUIPreviewOutput:OnFeedData(data)
    self._data = data
    ---@type ItemIconData
    self._itemIconData = self._itemIconData or {}
    self._itemIconData.configCell = data
    self._itemIconData.showCount = false
    self._itemIconData.showTips = true
    self._child_item_standard_s:FeedData(self._itemIconData)
end

return CityWorkCollectUIPreviewOutput