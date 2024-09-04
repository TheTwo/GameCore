---@class CityCitizenManageV3UIParameter
---@field new fun():CityCitizenManageV3UIParameter
local CityCitizenManageV3UIParameter = class("CityCitizenManageV3UIParameter")

---@param city City
---@param globalFilter fun(citizenData:CityCitizenData):boolean | nil
---@param pages CityCitizenManageV3PageData[]
---@param workCfg CityWorkConfigCell
---@param showWorkPower boolean
---@param showWorkProperty boolean
---@param onCitizenSelect fun(citizenData:CityCitizenData):boolean | nil
---@param allowCancelCitizenWork boolean
function CityCitizenManageV3UIParameter:ctor(city, globalFilter, pages, workCfg, showWorkPower, showWorkProperty, onCitizenSelect, allowCancelCitizenWork)
    self.city = city
    self.globalFilter = globalFilter
    self.pages = pages
    self.workCfg = workCfg
    self.showWorkPower = showWorkPower and self.workCfg ~= nil
    self.showWorkProperty = showWorkProperty and self.workCfg ~= nil
    self.onCitizenSelect = onCitizenSelect
    self.allowCancelCitizenWork = allowCancelCitizenWork
end

return CityCitizenManageV3UIParameter