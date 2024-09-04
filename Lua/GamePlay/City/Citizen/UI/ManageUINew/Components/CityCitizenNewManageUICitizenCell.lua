local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityCitizenNewManagerUICitizenCell:BaseTableViewProCell
local CityCitizenNewManageUICitizenCell = class('CityCitizenNewManageUICitizenCell', BaseTableViewProCell)

function CityCitizenNewManageUICitizenCell:OnCreate()
    ---@type CityCitizenNewUICitizenCell
    self._child_item_citizen = self:LuaObject("child_item_citizen")
end

---@param data CityCitizenNewManageUICitizenCellData
function CityCitizenNewManageUICitizenCell:OnFeedData(data)
    self._data = data
    self._child_item_citizen:FeedData(data)
end

return CityCitizenNewManageUICitizenCell