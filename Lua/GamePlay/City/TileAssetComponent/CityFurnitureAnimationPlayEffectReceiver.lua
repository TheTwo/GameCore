local Utils = require("Utils")

local LuaBehaviourAnimationEventReceiver = require("LuaBehaviourAnimationEventReceiver")

---@class CityFurnitureAnimationPlayEffectReceiver:LuaBehaviourAnimationEventReceiver
---@field new fun():CityFurnitureAnimationPlayEffectReceiver
---@field super LuaBehaviourAnimationEventReceiver
local CityFurnitureAnimationPlayEffectReceiver = class('CityFurnitureAnimationPlayEffectReceiver', LuaBehaviourAnimationEventReceiver)

function CityFurnitureAnimationPlayEffectReceiver:Awake()
    ---@type CS.UnityEngine.Transform
    self._targetTransform = nil
    ---@type CS.DragonReborn.VisualEffect.VisualEffectHandle
    self._effect = nil
end

---@param transform CS.UnityEngine.Transform
function CityFurnitureAnimationPlayEffectReceiver:SetEffectRoot(transform)
    self._targetTransform = transform
end

---@param parameter string @play_effect:assetName|stop_effect
function CityFurnitureAnimationPlayEffectReceiver:OnAnimationEvent(parameter)
    g_Logger.Log("CityFurnitureAnimationPlayEffectReceiver:OnAnimationEvent(%s)", parameter)
    if parameter == "stop_effect" then
        self:ClearLastEffect()
    elseif string.StartWith(parameter, "play_effect:") then
        local assetName = string.sub(parameter, 13)
        if not string.IsNullOrEmpty(assetName) then
            self:CreateEffect(assetName)
        end
    end
end

function CityFurnitureAnimationPlayEffectReceiver:CreateEffect(assetName)
    self:ClearLastEffect()
    if Utils.IsNull(self._targetTransform) then
        return
    end
    self._effect = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    local parentLayer = self._targetTransform.gameObject.layer
    self._effect:Create(assetName, "CityFurnitureAnimationPlayEffect", self._targetTransform, function(success, obj, handle)
        if success then
            ---@type CS.UnityEngine.Transform
            local trans = handle.Effect.transform
            trans.localScale = CS.UnityEngine.Vector3.one
            trans.localPosition = CS.UnityEngine.Vector3.zero
            trans.localEulerAngles = CS.UnityEngine.Vector3.zero
            trans.gameObject:SetLayerRecursive(parentLayer)
        end
    end)
end

function CityFurnitureAnimationPlayEffectReceiver:ClearLastEffect()
    if self._effect then
        self._effect:Delete()
        self._effect = nil
    end
end

function CityFurnitureAnimationPlayEffectReceiver:OnDisable()
    self:ClearLastEffect()
end

return CityFurnitureAnimationPlayEffectReceiver