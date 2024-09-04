
---@class AllianceBehemothOnMap
---@field new fun():AllianceBehemothOnMap
local AllianceBehemothOnMap = class('AllianceBehemothOnMap')

function AllianceBehemothOnMap:ctor(building)
    self:UpdateBuilding(building)
end

---@param building wds.MapBuildingBrief
function AllianceBehemothOnMap:UpdateBuilding(building)
    self._building = building
end

function AllianceBehemothOnMap:GetVanishTime()
    return self._building.BehemothTroop.VanishTime
end

return AllianceBehemothOnMap