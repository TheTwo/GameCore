
---@class AllianceBehemothSummonerInfo
---@field new fun(building:wds.MapBuildingBrief):AllianceBehemothSummonerInfo
local AllianceBehemothSummonerInfo = class('AllianceBehemothSummonerInfo')

---@param building wds.MapBuildingBrief
function AllianceBehemothSummonerInfo:ctor(building)
    ---@type wds.MapBuildingBrief
    self._building = nil
    self:UpdateBuilding(building)
end

---@param building wds.MapBuildingBrief
function AllianceBehemothSummonerInfo:UpdateBuilding(building)
    self._building = building
end

function AllianceBehemothSummonerInfo:GetBuildingEntityId()
    return self._building.EntityID
end

return AllianceBehemothSummonerInfo