local CameraUtils = {}

---@param ray CS.UnityEngine.Ray
---@param plane CS.UnityEngine.Plane
---@return CS.UnityEngine.Vector3
function CameraUtils.GetHitPointLinePlane(ray, plane)
    local flag, point = CS.RaycastHelper.PlaneRaycast(plane, ray)
    if flag then
        return point
    end
    g_Logger.ErrorChannel("CameraUtils", "GetHitPointLinePlane raycast failed, ray:" .. tostring(ray) .. ", plane:" .. tostring(plane))
    return nil
end

---@param ray CS.UnityEngine.Ray
---@param mask number
---@return CS.UnityEngine.Vector3
function CameraUtils.GetHitPointOnMeshCollider(ray, mask)
    local flag, point = CS.RaycastHelper.PhysicsRaycastRayHitWithMask(ray, CS.System.Single.PositiveInfinity, mask)
    if flag then
        return point
    else
        return nil
    end
end

---Raycast
---@param ray CS.UnityEngine.Ray
---@param maxDistance number
---@param layerMask number
---@return CS.UnityEngine.Transform
function CameraUtils.Raycast(ray,maxDistance, layerMask)
    if ray == nil then
        return nil
    end
    
    local trans = CS.RaycastHelper.PhysicsRaycast(ray, maxDistance , layerMask )
    return trans
end

---RaycastAll
---@param ray CS.UnityEngine.Ray
---@param maxDistance number
---@param layerMask number
---@return number,CS.UnityEngine.GameObject[]
function CameraUtils.RaycastAll(ray,maxDistance,layerMask)
    if ray == nil then
        return nil
    end
    local result, retArray = physics.raycastnonalloc(ray, maxDistance, layerMask)
    return result,retArray
end

---@param camera BasicCamera
---@param centerX number
---@param centerZ number
---@param sizeX number
---@param sizeZ number
---@param marginLeft number
---@param marginRight number
---@param marginBottom number
---@param marginTop number
---@param scale number
function CameraUtils.ClampToBorder(camera, centerX, centerZ, sizeX, sizeZ, marginLeft, marginRight, marginBottom, marginTop, scale)
    if camera == nil then
        return false
    end

    marginLeft = marginLeft or 0
    marginRight = marginRight or 0
    marginBottom = marginBottom or 0
    marginTop = marginTop or 0
    scale = scale or 1

    local lookAt = camera:GetLookAtPosition()
    local halfX = 0.5 * sizeX * scale
    local halfY = 0.5 * sizeZ * scale
    local offsetX, offsetZ = 0, 0
    local lookAtX, lookAtZ = lookAt.x, lookAt.z

    local marinX = (centerX > lookAtX and marginLeft or marginRight) * scale
    local marinZ = (centerZ > lookAtZ and marginBottom or marginTop) * scale

    if math.abs(centerX - lookAtX) > halfX - marinX then
        offsetX = centerX - lookAtX + math.sign(lookAtX - centerX) * (halfX - marinX)
    end
    if math.abs(centerZ - lookAtZ) > halfY - marinZ then
        offsetZ = centerZ - lookAtZ + math.sign(lookAtZ - centerZ) * (halfY - marinZ)
    end

    if offsetX ~= 0 or offsetZ ~= 0 then
        camera:MoveCameraOffset(CS.UnityEngine.Vector3(offsetX, 0, offsetZ))
        return true
    end
    return false

end

---@param touchPosition CS.UnityEngine.Vector3
---@return CS.UnityEngine.Vector3
function CameraUtils.ClampTouchPosition(touchPosition, screenWidth, screenHeight)
    local x = touchPosition.x
    local y = touchPosition.y
    x = math.clamp(x, 0, screenWidth)
    y = math.clamp(y, 0, screenHeight)
    touchPosition.x = x
    touchPosition.y = y
    return touchPosition
end

return CameraUtils