---@class CityLegoBuffRouteMapUIParameter
---@field new fun():CityLegoBuffRouteMapUIParameter
local CityLegoBuffRouteMapUIParameter = class("CityLegoBuffRouteMapUIParameter")

---@param city City
---@param legoBuilding CityLegoBuilding
function CityLegoBuffRouteMapUIParameter:ctor(city, legoBuilding)
    self.city = city
    self.legoBuilding = legoBuilding
end

return CityLegoBuffRouteMapUIParameter