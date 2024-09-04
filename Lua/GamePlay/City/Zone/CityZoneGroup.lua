---@class CityZoneGroup
---@field new fun():CityZoneGroup
---@field zones table<number, CityZone>
local CityZoneGroup = class("CityZoneGroup")

---@param cell CityZoneGroupConfigCell
function CityZoneGroup:ctor(cell)
    self.configCell = cell
    self.zones = {}
end

---@param zone CityZone
function CityZoneGroup:AddReleatedZone(zone)
    self.zones[zone.id] = zone
end

function CityZoneGroup:IsAllRecovered()
    for k, v in pairs(self.zones) do
        if not v:Recovered() then
            return false
        end
    end
    return true
end

return CityZoneGroup