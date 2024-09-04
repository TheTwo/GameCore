---@class CityLegoFreeDecoration
---@field new fun(legoBuilding, payload):CityLegoFreeDecoration
local CityLegoFreeDecoration = class("CityLegoFreeDecoration")

---@param legoBuilding CityLegoBuilding
---@param payload LegoFreeDecorationInstanceConfigCell
function CityLegoFreeDecoration:ctor(legoBuilding, payload)
    self.legoBuilding = legoBuilding
    self.city = self.legoBuilding.manager.city
    self:UpdatePayload(payload)
end

---@param payload LegoFreeDecorationInstanceConfigCell
function CityLegoFreeDecoration:UpdatePayload(payload)
    local coord = payload:RelPos()
    self.x = coord:X() + self.legoBuilding.x
    self.y = coord:Y()
    self.z = coord:Z() + self.legoBuilding.z
    self.rotation = 0
    self.payload = payload
end

function CityLegoFreeDecoration:UpdatePosition()
    if not self.payload then return end
    local coord = self.payload:RelPos()
    self.x = coord:X() + self.legoBuilding.x
    self.y = coord:Y()
    self.z = coord:Z() + self.legoBuilding.z
end

function CityLegoFreeDecoration:GetCfgId()
    return self.payload:Type()
end

function CityLegoFreeDecoration:GetStyle()
    return self.payload:Style()
end

function CityLegoFreeDecoration:GetWorldPosition()
    return self.city:GetWorldPositionFromCoord(self.x, self.z)
end

function CityLegoFreeDecoration:IsOutside()
    return not self.legoBuilding:InsideRoomBase(self.x, self.z)
end

return CityLegoFreeDecoration