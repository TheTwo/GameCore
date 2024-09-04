---
--- Created by wupei. DateTime: 2022/3/1
---

local BuffBehavior = require("BuffBehavior")
local SkillClientUtils = require("SkillClientUtils")

---@class BuffModelModify:BuffBehavior
local BuffModelModify = class("BuffModelModify", BuffBehavior)

---@param self BuffModelModify
---@param ... any
---@return void
function BuffModelModify:ctor(...)
    BuffModelModify.super.ctor(self, ...)

    ---@type buffclient.data.ModelModify
    self._buffModel = self._data
end

function BuffModelModify:IsScaleValid(scale)
    if scale then
        if scale.x > 0 and scale.y > 0 and scale.z > 0 then
            return true
        else
            g_Logger.Error('scale not valid: %s %s %s', scale.x, scale.y, scale.z)
            return false
        end
    else
        g_Logger.Error('scale not valid: nil value')
        return false
    end
end

---@param self BuffModelModify
---@return void
function BuffModelModify:OnStart()
    local scale = self._buffModel.Scale
    if self:IsScaleValid(scale) then
        self._target:MulScale(scale)
    end

    if (self._buffModel.ReplaceModel) then
        self._target:GetCtrl():TransmorphTo(self._buffModel.NewModelPath)
    end

    if self._buffModel.Tweening then
        self._timeBegin = CS.UnityEngine.Time.time
        if self._target and self._target:IsCtrlFbxValid() then
            self._beginScale = self._target:GetFbxTransform().localScale
        end
    end
end

function BuffModelModify:OnCtrlValid()
    if self._beginScale then return end
    self._beginScale = self._target:GetFbxTransform().localScale
end

---@param self BuffModelModify
---@return void
function BuffModelModify:OnUpdate()
    if self._buffModel.Tweening and self._beginScale then
        local curveX = SkillClientUtils.GetCurve(self._buffModel.CurveX)
        local curveY = SkillClientUtils.GetCurve(self._buffModel.CurveY)
        local curveZ = SkillClientUtils.GetCurve(self._buffModel.CurveZ)

        local duration = self._buffModel.Time
        local time = CS.UnityEngine.Time.time - self._timeBegin
        local scaleX = curveX:Evaluate(time / duration)
        local scaleY = curveY:Evaluate(time / duration)
        local scaleZ = curveZ:Evaluate(time / duration)
        local scale = CS.UnityEngine.Vector3(scaleX, scaleY, scaleZ)
        self._target:GetFbxTransform().localScale = scale
        -- g_Logger.Error('BuffModelModify:OnUpdate set scale %s %s %s, time %s, duration %s', scaleX, scaleY, scaleZ, time, duration)
    end
end

---@param self BuffModelModify
---@return void
function BuffModelModify:OnEnd()
    -- Tweening效果复位
    if self._buffModel.Tweening then
        if self._target:IsCtrlFbxValid() and self._beginScale then
            self._target:GetFbxTransform().localScale = self._beginScale
        end
    end

    local scale = self._buffModel.Scale
    if self:IsScaleValid(scale) then
        self._target:DivScale(scale)
    end

    if (self._buffModel.ReplaceModel) then
        self._target:GetCtrl():CancelTransmorph()
    end
end

return BuffModelModify
