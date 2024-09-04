local BaseUIComponent = require ('BaseUIComponent')
local LuaReusedComponentPool = require("LuaReusedComponentPool")

---@class CityLegoBuffRouteMapUISpace:BaseUIComponent
local CityLegoBuffRouteMapUISpace = class('CityLegoBuffRouteMapUISpace', BaseUIComponent)

---@class CityLegoBuffRouteMapUISpaceData
---@field maxLength number
---@field cfg RoomTagBuffUISpaceColumnConfigCell

function CityLegoBuffRouteMapUISpace:OnCreate()
    self._layout_for_score = self:GameObject("layout_for_score")
    
    self._p_link_layout = self:Transform("p_link_layout")
    self._p_link_line = self:LuaBaseComponent("p_link_line")
    self._line_pool = LuaReusedComponentPool.new(self._p_link_line, self._p_link_layout)
end

---@param data CityLegoBuffRouteMapUISpaceData
function CityLegoBuffRouteMapUISpace:OnFeedData(data)
    self.data = data
    if data.maxLength == 0 then return end

    for i = 1, data.maxLength do
        local comp = self._line_pool:GetItem()
        ---@type CityLegoBuffRouteMapUIConnectLineData
        local data = {
            mask = data.cfg ~= nil and data.cfg:Rows(i) or 0
        }
        comp:FeedData(data)
    end
end

return CityLegoBuffRouteMapUISpace