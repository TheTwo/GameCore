local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityManageCenterTab:BaseTableViewProCell
local CityManageCenterTab = class('CityManageCenterTab', BaseTableViewProCell)

function CityManageCenterTab:OnCreate()
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn = self:LuaObject("child_tab_left_btn")
end

---@param data CityManageCenterTabData
function CityManageCenterTab:OnFeedData(data)
    self.data = data
    ---@type CommonChildTabLeftBtnParameter
    local tabData = {
        index = data.index,
        onClick = data:GetOnClick(),
        btnName = data:GetButtonName(),
    }
    self._child_tab_left_btn:FeedData(tabData)
end

return CityManageCenterTab