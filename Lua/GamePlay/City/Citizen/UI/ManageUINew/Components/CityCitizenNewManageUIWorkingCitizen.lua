local BaseUIComponent = require ('BaseUIComponent')

---@class CityCitizenNewManageUIWorkingCitizen:BaseUIComponent
local CityCitizenNewManageUIWorkingCitizen = class('CityCitizenNewManageUIWorkingCitizen', BaseUIComponent)

function CityCitizenNewManageUIWorkingCitizen:OnCreate()
    ---@type CityCitizenNewUICitizenCell
    self._child_item_citizen = self:LuaObject("child_item_citizen")
end

---@param data CityCitizenNewManageUIWorkingCitizenData
function CityCitizenNewManageUIWorkingCitizen:OnFeedData(data)
    self._data = data
    self._child_item_citizen:FeedData(data)
end

return CityCitizenNewManageUIWorkingCitizen