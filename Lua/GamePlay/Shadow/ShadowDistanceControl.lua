local CameraConst = require('CameraConst')
local KingdomMapUtils = require('KingdomMapUtils')
local RenderPiplineUtil = CS.RenderPiplineUtil

---@class ShadowDistanceControl
local ShadowDistanceControl = class("ShadowDistanceControl")

function ShadowDistanceControl.SetEnable(enabled)
    ShadowDistanceControl.enabled = enabled
end


function ShadowDistanceControl.RefreshShadow(camera, newCameraSize, sizeList, shadowDistanceList, shadowCascadeSizeThreshold)
    if not ShadowDistanceControl.enabled then
        return RenderPiplineUtil.GetShadowDistance()
    end
    
    local cameraLodData = KingdomMapUtils.GetKingdomScene().cameraLodData
    local lod = cameraLodData.lod
    ---@type CS.UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset
    local shadowDistance = 0

    if lod >= CameraConst.MOUNTAIN_ONLY_LOD then
        RenderPiplineUtil.SetShadowDistanceWithCamera(shadowDistance, camera)
        return shadowDistance
    end

    local sizeCount = #sizeList
    local shadowCount = #shadowDistanceList
    if newCameraSize <= sizeList[1] then
        shadowDistance = shadowDistanceList[1]
        RenderPiplineUtil.SetShadowDistanceWithCamera(shadowDistanceList[1], camera)
        return shadowDistance
    elseif newCameraSize >= sizeList[sizeCount] then
        shadowDistance = shadowDistanceList[sizeCount]
        RenderPiplineUtil.SetShadowDistanceWithCamera(shadowDistanceList[sizeCount], camera)
        return shadowDistance
    end

    for i = 1, sizeCount do
        local size = sizeList[i]
        if i <= shadowCount - 1 and newCameraSize > size then
            local t = (newCameraSize - size) / (sizeList[i + 1] - size)
            shadowDistance = math.lerp(shadowDistanceList[i], shadowDistanceList[i + 1], t)
            RenderPiplineUtil.SetShadowDistanceWithCamera(shadowDistance, camera)
        end
    end

    if shadowCascadeSizeThreshold ~= nil and newCameraSize < shadowCascadeSizeThreshold then
        RenderPiplineUtil.SetCascade2Split(CameraConst.MapShadowCascadeSplit2 / shadowDistance)
    end

    return shadowDistance
end

function ShadowDistanceControl.ChangeShadowCascades(shadowCascades)
    RenderPiplineUtil.SetShadowCascadeCount(shadowCascades)
end

function ShadowDistanceControl.ChangeCascade2Split(value, distance)
    RenderPiplineUtil.SetCascade2Split(value / distance)
end

function ShadowDistanceControl.GetParam()
    return RenderPiplineUtil.GetShadowDistance(), RenderPiplineUtil.GetShadowCascadeCount(), RenderPiplineUtil.GetCascade2Split()
end

return ShadowDistanceControl
