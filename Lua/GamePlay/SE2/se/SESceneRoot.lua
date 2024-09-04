
---@class SESceneRoot
local SESceneRoot = {}

---@private
---@type CS.UnityEngine.Transform
SESceneRoot.sceneTransormRoot = nil

---@private
---@type number
SESceneRoot.sceneClientScale = nil

---@private
---@type number
SESceneRoot.sceneCameraRotY = nil

---@private
---@type number
SESceneRoot.sceneWayPointYOffset = nil

---@param transform CS.UnityEngine.Transform
function SESceneRoot.SetSceneRoot(transform)
    SESceneRoot.sceneTransormRoot = transform
end

---@return CS.UnityEngine.Transform|nil
function SESceneRoot.GetSceneRoot()
    return SESceneRoot.sceneTransormRoot
end

---@param scale number|nil
function SESceneRoot.SetClientScale(scale)
    SESceneRoot.sceneClientScale = scale
end

---@return number
function SESceneRoot.GetClientScale()
    return SESceneRoot.sceneClientScale or 1
end

---@param scale number|nil
function SESceneRoot.SetCameraRotation(y)
    SESceneRoot.sceneCameraRotY = y
end

function SESceneRoot.GetCameraRotation()
    return CS.UnityEngine.Quaternion.Euler(0, SESceneRoot.sceneCameraRotY or 0, 0)
end

---@param value number|nil
function SESceneRoot.SetSceneWayPointYOffset(value)
    SESceneRoot.sceneWayPointYOffset = value
end

---@return number
function SESceneRoot.GetSceneWayPointYOffset()
    return SESceneRoot.sceneWayPointYOffset or 0
end

return SESceneRoot