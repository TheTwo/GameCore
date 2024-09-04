---@class CityOutlineController
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field new fun():CityOutlineController
---@field ConstructionColor CS.UnityEngine.Color
---@field OtherColor CS.UnityEngine.Color
---@field OutlineMat CS.UnityEngine.Material
local CityOutlineController = sealedClass("CityOutlineController")
local Utils = require("Utils")
local ColorId = CS.RenderExtension.ShaderConst._ColorId
local WidthId = CS.UnityEngine.Shader.PropertyToID("_Width")

function CityOutlineController:ctor()
    ---@type CS.UnityEngine.Material
    self._runtimeOutlineMat = nil
end

---@param camera CS.UnityEngine.Camera
function CityOutlineController:SetMainCamera(camera)
    self._runtimeOutlineMat = nil
    if Utils.IsNotNull(camera) then
        ---@type CS.UnityEngine.Experimental.Rendering.Universal.RenderObjects
        local feature = camera:GetCameraRendererFeature(typeof(CS.UnityEngine.Experimental.Rendering.Universal.RenderObjects), "OutLine")
        if Utils.IsNotNull(feature) then
            self._runtimeOutlineMat = feature.settings.overrideMaterial
        end
    end
end

function CityOutlineController:ChangeOutlineColor(color)
    if Utils.IsNull(self._runtimeOutlineMat) then return end
    self._runtimeOutlineMat:SetColor(ColorId, color)
end

function CityOutlineController:GetOutlineColor()
    if Utils.IsNull(self._runtimeOutlineMat) then
        return CS.UnityEngine.Color.clear
    end
    return self._runtimeOutlineMat:GetColor(ColorId)
end

function CityOutlineController:ChangeOutlineWidth(width)
    if Utils.IsNull(self._runtimeOutlineMat) then return end
    self._runtimeOutlineMat:SetFloat(WidthId, width)
end

function CityOutlineController:GetOutlineWidth()
    if Utils.IsNull(self._runtimeOutlineMat) then return 0 end
    return self._runtimeOutlineMat:GetFloat(WidthId)
end

return CityOutlineController