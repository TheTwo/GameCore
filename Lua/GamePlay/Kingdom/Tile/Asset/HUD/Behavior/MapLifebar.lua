---prefabName:ui3d_progress_territory
---@class MapLifebar
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field new fun():MapLifebar
---@field p_rotation CS.U2DFacingCamera
---@field p_progress CS.UnityEngine.Transform
---@field Frame CS.U2DSpriteMesh
---@field p_bar CS.U2DSlider
local MapLifebar = class("MapLifebar")

---@param pos CS.UnityEngine.Vector3
function MapLifebar:SetLocalPosition(pos)
    self.p_rotation.transform.localPosition = pos
end

function MapLifebar:SetCamera(camera)
    self.p_rotation.FacingCamera = camera
end

function MapLifebar:SetProgress(progress)
    local fixValue = math.clamp01(progress)
    self.p_bar.progress = fixValue
end

function MapLifebar:SetProgressWithEmptyFill(progress)
    local fixValue = math.clamp01(progress)
    self.p_bar.progress = fixValue
end

return MapLifebar