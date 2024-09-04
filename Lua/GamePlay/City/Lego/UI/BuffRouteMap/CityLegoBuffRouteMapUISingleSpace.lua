local BaseUIComponent = require ('BaseUIComponent')

---@class CityLegoBuffRouteMapUISingleSpace:BaseUIComponent
local CityLegoBuffRouteMapUISingleSpace = class('CityLegoBuffRouteMapUISingleSpace', BaseUIComponent)

function CityLegoBuffRouteMapUISingleSpace:OnCreate()
    self._p_line_lock = self:GameObject("p_line_lock")
    self._p_line_unlock = self:GameObject("p_line_unlock")
end

---@param data {showLine:boolean}
function CityLegoBuffRouteMapUISingleSpace:OnFeedData(data)
    self._p_line_lock:SetActive(data.showLine)
    self._p_line_unlock:SetActive(data.showLine)
end

return CityLegoBuffRouteMapUISingleSpace