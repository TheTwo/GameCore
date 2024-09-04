local BaseUIComponent = require ('BaseUIComponent')

---@class CityLegoBuffRouteMapUIConnectLine:BaseUIComponent
local CityLegoBuffRouteMapUIConnectLine = class('CityLegoBuffRouteMapUIConnectLine', BaseUIComponent)
local Mask = { None = 0, Left = 1, Right = 2, Top = 4, Bottom = 8 }

---@class CityLegoBuffRouteMapUIConnectLineData
---@field mask number

function CityLegoBuffRouteMapUIConnectLine:OnCreate()
    self._p_line_t = self:GameObject("p_line_t")
    self._p_line_r = self:GameObject("p_line_r")
    self._p_line_l = self:GameObject("p_line_l")
    self._p_line_b = self:GameObject("p_line_b")
    self._p_line_c = self:GameObject("p_line_c")
    self._p_icon_nail = self:GameObject("p_icon_nail")
end

---@param data CityLegoBuffRouteMapUIConnectLineData
function CityLegoBuffRouteMapUIConnectLine:OnFeedData(data)
    self._p_line_l:SetActive(data.mask & Mask.Left ~= 0)
    self._p_line_r:SetActive(data.mask & Mask.Right ~= 0)
    
    self._p_line_t:SetActive(data.mask & Mask.Top ~= 0)
    self._p_line_b:SetActive(data.mask & Mask.Bottom ~= 0)
    self._p_icon_nail:SetActive(data.mask ~= Mask.None)
end

return CityLegoBuffRouteMapUIConnectLine