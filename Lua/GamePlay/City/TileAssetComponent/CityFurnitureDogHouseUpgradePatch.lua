local Utils = require("Utils")

---@class CityFurnitureDogHouseUpgradePatch
---@field new fun():CityFurnitureDogHouseUpgradePatch
---@field dogTrans CS.UnityEngine.Transform
---@field normalPosTrans CS.UnityEngine.Transform
---@field upgradePosTrans CS.UnityEngine.Transform
---@field dogAnimator CS.UnityEngine.Animator
local CityFurnitureDogHouseUpgradePatch = class('CityFurnitureDogHouseUpgradePatch')

function CityFurnitureDogHouseUpgradePatch:ResetToNormal()
    if Utils.IsNull(self.dogTrans) or Utils.IsNull(self.normalPosTrans) or Utils.IsNull(self.upgradePosTrans) or Utils.IsNull(self.dogAnimator) then
        return
    end
    self.dogTrans.position = self.normalPosTrans.position
    self.dogAnimator:CrossFade("idle", 0.05)
end

function CityFurnitureDogHouseUpgradePatch:SetToUpgrade()
    if Utils.IsNull(self.dogTrans) or Utils.IsNull(self.normalPosTrans) or Utils.IsNull(self.upgradePosTrans) or Utils.IsNull(self.dogAnimator) then
        return
    end
    self.dogTrans.position = self.upgradePosTrans.position
    self.dogAnimator:CrossFade("sit_idle", 0.05)
end

return CityFurnitureDogHouseUpgradePatch