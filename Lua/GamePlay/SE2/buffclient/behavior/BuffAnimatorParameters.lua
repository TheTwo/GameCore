---
--- Created by wupei. DateTime: 2022/3/1
---

local BuffBehavior = require("BuffBehavior")
local Utils = require("Utils")

---@class BuffAnimatorParameters:BuffBehavior
local BuffAnimatorParameters = class("BuffAnimatorParameters", BuffBehavior)

---@param self BuffAnimatorParameters
---@param ... any
---@return void
function BuffAnimatorParameters:ctor(...)
    BuffAnimatorParameters.super.ctor(self, ...)

    ---@type buffclient.data.AnimatorParameters
    self._paramData = self._data
    self._tweener = nil
end

---@param self BuffAnimatorParameters
---@return void
function BuffAnimatorParameters:OnStart()
    if not self._paramData.AutoAimTarget then
        self:UpdateAnimatorParam(self._paramData.Tweening)
    end
end

function BuffAnimatorParameters:OnCtrlValid()
    if not self._paramData.AutoAimTarget then
        self:UpdateAnimatorParam(self._paramData.Tweening)
    end
end

---@param self BuffAnimatorParameters
---@return void
function BuffAnimatorParameters:OnUpdate()
    if self._paramData.AutoAimTarget then
        self:UpdateAnimatorParam(false)
    end
end

---@param self BuffAnimatorParameters
---@return void
function BuffAnimatorParameters:OnEnd()
    --if self:IsCancel() and self._tweener then
    --    if self._tweener:IsPlaying() then
    --        self._tweener:Complete()
    --    end
    --    self._tweener = nil
    --end
end

local gen = require("BuffClientGen")

---@param self BuffAnimatorParameters
---@param tweening any
---@return void
function BuffAnimatorParameters:UpdateAnimatorParam(tweening)
    if self._target:IsCtrlFbxValid() then
        ---@type CS.UnityEngine.Animator
        local animator = self._target:GetAnimator()
        if Utils.IsNotNull(animator) then
            if self._paramData.ParamType == gen.EParamType.UseFloat then
                if tweening then
                    self._tweener = animator:DOSetFloat(self._paramData.ParamKey, self._paramData.ParamValue, self._paramData.Time)
                else
                    animator:SetFloat(self._paramData.ParamKey, self._paramData.ParamValue)
                end
            end
        end
    end
end

return BuffAnimatorParameters
