---@class CityLegoBuffToastUIParameter
---@field new fun(oldName, newName, attrCfgId, duration):CityLegoBuffToastUIParameter
local CityLegoBuffToastUIParameter = class("CityLegoBuffToastUIParameter")

function CityLegoBuffToastUIParameter:ctor(oldName, newName, attrCfgId, duration)
    self.oldName = oldName
    self.newName = newName
    self.attrCfgId = attrCfgId
    self.duration = duration or 2
end

function CityLegoBuffToastUIParameter:SetAttrChange(attrCfgId)
    self.attrCfgId = attrCfgId
    return self
end

function CityLegoBuffToastUIParameter:SetDuration(duration)
    self.duration = duration
    return self
end

return CityLegoBuffToastUIParameter