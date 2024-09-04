local Utils = require("Utils")
local RectTransformUtility = CS.UnityEngine.RectTransformUtility

local BaseUIComponent = require("BaseUIComponent")

---@class CommonCanvasRaycastFilter:BaseUIComponent
---@field new fun():CommonCanvasRaycastFilter
---@field super BaseUIComponent
local CommonCanvasRaycastFilter = class('CommonCanvasRaycastFilter', BaseUIComponent)

function CommonCanvasRaycastFilter:ctor()
    BaseUIComponent.ctor(self)
    ---@type CS.UnityEngine.RectTransform
    self._targetRect = nil
    self._isReverse = false
end

---@param sp CS.UnityEngine.Vector2
---@param eventCamera CS.UnityEngine.Camera
function CommonCanvasRaycastFilter:IsRaycastLocationValid(sp, eventCamera)
    if Utils.IsNotNull(self._targetRect) then
        local inRect = RectTransformUtility.RectangleContainsScreenPoint(self._targetRect, sp, eventCamera)
        if inRect then
            return self._isReverse
        else
            return not self._isReverse
        end
    end
    return self._isReverse
end

---@param rect CS.UnityEngine.RectTransform
---@param isReverse boolean
function CommonCanvasRaycastFilter:SetRect(rect, isReverse)
    self._targetRect = rect
    self._isReverse = isReverse or false
end

return CommonCanvasRaycastFilter