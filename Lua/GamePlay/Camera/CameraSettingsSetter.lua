---@class CameraSettingsSetter
local CameraSettingsSetter = class("CameraSettingsSetter")

---@param settings CS.Kingdom.BasicCameraSettings
---@param basicCamera BasicCamera
---@param lodData CameraLodData
---@param planeData CameraPlaneData
function CameraSettingsSetter.Set(settings, basicCamera, lodData, planeData)
    basicCamera.slidingTolerance = settings:GetValue("slidingTolerance")
    basicCamera.maxSlidingTolerance = settings:GetValue("maxSlidingTolerance")
    basicCamera.damping = settings:GetValue("damping")
    basicCamera.strength = settings:GetValue("strength")
    basicCamera.smoothing = settings:GetValue("smoothing")
    basicCamera.deltaFactor = settings:GetValue("deltaFactor")

    lodData.mapCameraEnterSize = settings:GetValue("mapCameraEnterSize")
    lodData.mapCameraEnterNear = settings:GetValue("mapCameraEnterNear")
    lodData.mapCameraEnterFar = settings:GetValue("mapCameraEnterFar")
    settings:SetFloatTable("mapCameraSizeList", lodData.mapCameraSizeList)
    settings:SetFloatTable("mapShadowDistanceList", lodData.mapShadowDistanceList)
    lodData.altitudeCurve = settings:GetCurve("altitudeCurve")

    planeData.nearToFarDistance = settings:GetValue("nearToFarDistance")
    planeData.lod1Near = settings:GetValue("lod1Near")
    planeData:UpdateNearFarPlanes()
end

return CameraSettingsSetter