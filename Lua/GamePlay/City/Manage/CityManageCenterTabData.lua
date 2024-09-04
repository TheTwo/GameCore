---@class CityManageCenterTabData
---@field new fun():CityManageCenterTabData
local CityManageCenterTabData = class("CityManageCenterTabData")
local Delegate = require("Delegate")

---@param param CityManageCenterUIParameter
---@param index number
function CityManageCenterTabData:ctor(param, index)
    self.param = param
    self.index = index
end

function CityManageCenterTabData:GetOnClick()
    return Delegate.GetOrCreate(self.param, self.param.OnTabClick)
end

function CityManageCenterTabData:GetButtonName()
    return self.param:GetButtonName(self.index)
end

return CityManageCenterTabData