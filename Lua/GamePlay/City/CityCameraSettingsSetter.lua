---@class CityCameraSettingsSetter
local CityCameraSettingsSetter = class("CityCameraSettingsSetter")

---@param settings CS.Kingdom.BasicCameraSettings
---@param basicCamera BasicCamera
---@param lodData CameraLodData
---@param planeData CameraPlaneData
function CityCameraSettingsSetter.Set(settings, basicCamera, lodData, planeData)
    basicCamera.slidingTolerance = settings:GetValue("slidingTolerance")
    basicCamera.maxSlidingTolerance = settings:GetValue("maxSlidingTolerance")
    basicCamera.damping = settings:GetValue("damping")

    planeData.minFrustumLengthUnderGround = settings:GetValue("minFrustumLengthUnderGround")
    planeData.maxFrustumLengthUnderGround = settings:GetValue("maxFrustumLengthUnderGround")
    planeData.lod1Near = settings:GetValue("lod1Near")
    planeData:UpdateNearFarPlanes()
end

return CityCameraSettingsSetter