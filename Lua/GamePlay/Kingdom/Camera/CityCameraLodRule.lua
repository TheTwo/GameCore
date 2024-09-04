---@class CityCameraLodRule
---@field new fun():CityCameraLodRule
local CityCameraLodRule = sealedClass("CityCameraLodRule")
local Delegate = require("Delegate")
local QualitySettings = CS.UnityEngine.QualitySettings

---@param basicCamera BasicCamera
function CityCameraLodRule:Initialize(basicCamera)
    self.basicCamera = basicCamera
    self.prevLodMaxLevel = QualitySettings.maximumLODLevel
    self.currentLodMaxLevel = self.prevLodMaxLevel
    self.isLowLevel = self:IsLowLevel()
    if not self.isLowLevel then
        self.basicCamera:AddSizeChangeListener(Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    else
        QualitySettings.maximumLODLevel = 1
    end
end

function CityCameraLodRule:Release()
    if not self.isLowLevel then
        self.basicCamera:RemoveSizeChangeListener(Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    end
    self.isLowLevel = nil
    self.basicCamera = nil
    QualitySettings.maximumLODLevel = self.prevLodMaxLevel
end

function CityCameraLodRule:IsLowLevel()
    return g_Game.PerformanceLevelManager:IsLowLevel()
end

function CityCameraLodRule:OnCameraSizeChanged(old, new)
    local newLodMaxLevel = new > self.basicCamera.settings:GetValue("cityLodSwitchingSize") and 1 or 0
    if newLodMaxLevel ~= self.currentLodMaxLevel then
        self.currentLodMaxLevel = newLodMaxLevel
        QualitySettings.maximumLODLevel = newLodMaxLevel
    end
end

return CityCameraLodRule