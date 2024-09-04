--- Created by wupei. DateTime: 2021/7/2
local Utils = require("Utils")

local Behavior = require("Behavior")

---@class ModelShake:Behavior
---@field super Behavior
local ModelShake = class("ModelShake", Behavior)

---@param self ModelShake
---@param ... any
---@return void
function ModelShake:ctor(...)
    ModelShake.super.ctor(self, ...)

    ---@type skillclient.data.ModelShake
    self._shakeData = self._data
    ---@type CS.DragonReborn.SEModelShake
    self._seModelShake = nil
end

---@param self ModelShake
---@return void
function ModelShake:OnStart()
    self._seModelShake = nil
    local range = self._shakeData.Range
    local angularFrequency = self._shakeData.AngularFrequency
    local damping = self._shakeData.Damping
    local time = self._shakeData.Time
    local bodyTrans = self._skillTarget:GetFbxTransform()
    if bodyTrans then
        self._seModelShake = CS.DragonReborn.SEModelShake.Get(bodyTrans.gameObject)
        self._seModelShake:StopShake()
        bodyTrans.localPosition = CS.UnityEngine.Vector3.zero
        self._seModelShake:StartShake(range, angularFrequency, damping, time)
    end
end

function ModelShake:OnEnd()
    if Utils.IsNotNull(self._seModelShake) then
        self._seModelShake:StopShake()
    end
    self._seModelShake = nil
end

return ModelShake
