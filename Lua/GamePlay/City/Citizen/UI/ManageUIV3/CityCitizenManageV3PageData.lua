---@class CityCitizenManageV3PageData
---@field new fun():CityCitizenManageV3PageData
local CityCitizenManageV3PageData = class("CityCitizenManageV3PageData")

---@param filter fun(citizenData:CityCitizenData):boolean|nil
---@param priority number
---@param icon string
---@param workCfg CityCitizenWorkCfg|nil
---@param showWorkPower boolean|nil
---@param showWorkProperty boolean|nil
function CityCitizenManageV3PageData:ctor(filter, priority, icon)
    self.filter = filter
    self.priority = priority
    self.icon = icon
end

return CityCitizenManageV3PageData