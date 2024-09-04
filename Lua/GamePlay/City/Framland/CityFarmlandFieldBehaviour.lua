---@class CityFarmlandFieldBehaviour
---@field new fun():CityFarmlandFieldBehaviour
---@field phase1 CS.UnityEngine.GameObject
---@field phase2 CS.UnityEngine.GameObject
---@field phase3 CS.UnityEngine.GameObject
local CityFarmlandFieldBehaviour = sealedClass('CityFarmlandFieldBehaviour')

---@param landInfo wds.CastleLandInfo
function CityFarmlandFieldBehaviour:RefreshFieldModel(landInfo)
    local show1 = true
    local show2 = false
    local show3 = false
    if landInfo then
        if landInfo.state == wds.CastleLandState.CastleLandHarvestable then
            show1 = false
            show2 = false
            show3 = true
        elseif landInfo.state == wds.CastleLandState.CastleLandGrowing then
            show1 = false
            show2 = true
            show3 = false
        end
    end
    self.phase1:SetVisible(show1)
    self.phase2:SetVisible(show2)
    self.phase3:SetVisible(show3)
end

return CityFarmlandFieldBehaviour