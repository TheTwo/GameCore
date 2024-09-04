---
--- Created by wupei. DateTime: 2022/1/21
---

local Behavior = require("Behavior")
local SkillClientGen = require("SkillClientGen")

---@class AnimatorParameters:Behavior
---@field super Behavior
local AnimatorParameters = class("AnimatorParameters", Behavior)
local Utils = require("Utils")

---@param self AnimatorParameters
---@param ... any
---@return void
function AnimatorParameters:ctor(...)
    AnimatorParameters.super.ctor(self, ...)

    ---@type skillclient.data.AnimatorParameters
    self._paramData = self._data
    self._tweener = nil
end

---@param self AnimatorParameters
---@return void
function AnimatorParameters:OnStart()
    if not self._paramData.AutoAimTarget then
        self:UpdateAnimatorParam(self._paramData.Tweening)
    end
end

---@param self AnimatorParameters
---@return void
function AnimatorParameters:OnUpdate()
    if self._paramData.AutoAimTarget then
        self:UpdateAnimatorParam(false)
    end
end

---@param self AnimatorParameters
---@return void
function AnimatorParameters:OnEnd()
    if self:IsCancel() and self._tweener then
        if self._tweener:IsPlaying() then
            self._tweener:Complete()
        end
        self._tweener = nil
    end
end

---@param self AnimatorParameters
---@param tweening any
---@return void
function AnimatorParameters:UpdateAnimatorParam(tweening)
    if self._skillTarget:IsCtrlValid() then
        ---@type CS.UnityEngine.Animator
        local animator = self._skillTarget:GetAnimator()
        if Utils.IsNotNull(animator) then
            if self._paramData.ParamType == SkillClientGen.EParamType.UseFloat then
                if self:HasParamKey(animator, self._paramData.ParamKey) then
                    if tweening then
                        self._tweener = animator:DOSetFloat(self._paramData.ParamKey, self._paramData.ParamValue, self._paramData.Time)
                    else
                        animator:SetFloat(self._paramData.ParamKey, self._paramData.ParamValue)
                    end
                end
            elseif self._paramData.ParamType == SkillClientGen.EParamType.AttackAngle then
                local forward = self._skillTarget:GetForwardToEnemy()
                local forward2 = self._skillTarget:GetForward()
                local angle = CS.UnityEngine.Quaternion.FromToRotation(forward2, forward).eulerAngles.y
                while angle > 180 do
                    angle = angle - 360
                end
                while angle < -180 do
                    angle = angle + 360
                end
                if self:HasParamKey(animator, self._paramData.ParamKey) then
                    if tweening then
                        self._tweener = animator:DOSetFloat(self._paramData.ParamKey, angle, self._paramData.Time)
                    else
                        animator:SetFloat(self._paramData.ParamKey, angle)
                    end
                end
            end
        end
    end
end

---@param self AnimatorParameters
---@param animator any
---@param key any
---@return void
function AnimatorParameters:HasParamKey(animator, key)
    if CS.UnityEngine.Application.isEditor then
        if animator:HasParameter(key) then
            return true
        end
        return false
    end
    return true
end

return AnimatorParameters
