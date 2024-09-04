local Utils = require("Utils")

---@class CityTileAssetSafeAreaDoorComp
---@field doorAnimator CS.UnityEngine.Animator
local CityTileAssetSafeAreaDoorComp = sealedClass("CityTileAssetSafeAreaDoorComp")

function CityTileAssetSafeAreaDoorComp:OnEnable()
    if self._doorOpenStatus == nil then return end
    if Utils.IsNull(self.doorAnimator) then return end
    self.doorAnimator:SetBool("open", self._doorOpenStatus)
end

function CityTileAssetSafeAreaDoorComp:SetOpenStatus(open)
    if self._doorOpenStatus == open then
        return
    end
    self._doorOpenStatus = open
    if Utils.IsNull(self.doorAnimator) then return end
    self.doorAnimator:SetBool("open", self._doorOpenStatus)
end

return CityTileAssetSafeAreaDoorComp