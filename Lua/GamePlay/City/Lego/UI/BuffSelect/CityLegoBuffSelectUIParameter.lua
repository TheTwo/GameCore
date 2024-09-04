---@class CityLegoBuffSelectUIParameter
---@field new fun():CityLegoBuffSelectUIParameter
local CityLegoBuffSelectUIParameter = class("CityLegoBuffSelectUIParameter")

---@param legoBuilding CityLegoBuilding
function CityLegoBuffSelectUIParameter:ctor(legoBuilding)
    self.legoBuilding = legoBuilding
end

return CityLegoBuffSelectUIParameter