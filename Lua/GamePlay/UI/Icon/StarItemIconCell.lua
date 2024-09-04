local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class StarItemIconCell:BaseTableViewProCell
local StarItemIconCell = class('StarItemIconCell', BaseTableViewProCell)

function StarItemIconCell:OnCreate()
    ---@type StarItemIcon
    self._child_item_star_s_editor = self:LuaObject("child_item_star_s_editor")
end

---@param data StarItemIconData
function StarItemIconCell:OnFeedData(data)
    if self._child_item_star_s_editor ~= nil then
        self._child_item_star_s_editor:FeedData(data)
    end
end

return StarItemIconCell