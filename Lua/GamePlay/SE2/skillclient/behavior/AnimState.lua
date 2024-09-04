---
--- Created by wupei. DateTime: 2022/2/17
---

local Behavior = require("Behavior")
local AnimStateType = require("SEAnimStateType")

---@class AnimState:Behavior
---@field super Behavior
local AnimState = class("AnimState", Behavior)

---@param self AnimState
---@param ... any
---@return void
function AnimState:ctor(...)
    AnimState.super.ctor(self, ...)

    ---@type skillclient.data.AnimState
    self._stateData = self._data
end

---@param self AnimState
---@return void
function AnimState:OnStart()
    local ctrl = self._skillTarget:GetCtrl()
    if ctrl then
        if self._stateData.IgnoreRunRotation then
            ctrl:AddAnimStateCount(AnimStateType.IgnoreRunRotation)
        end
        if self._stateData.PlayAttackMove then
            ctrl:AddAnimStateCount(AnimStateType.PlayAttackMove)
        end
        if self._stateData.IgnoreKeepDirection then
            ctrl:AddAnimStateCount(AnimStateType.IgnoreKeepDirection)
        end
    end
end

---@param self AnimState
---@return void
function AnimState:OnUpdate()
    if self._stateData.KeepDirection then
        local ctrl = self._skillTarget:GetCtrl()
        if ctrl and ctrl:IsValid() and not ctrl:IsIgnoreKeepDirection() then
            local forward = self._skillTarget:GetForwardToEnemy()
            ctrl:SetForward(forward)
        end
    end
end

---@param self AnimState
---@return void
function AnimState:OnEnd()
    local ctrl = self._skillTarget:GetCtrl()
    if ctrl then
        if self._stateData.IgnoreRunRotation then
            ctrl:SubAnimStateCount(AnimStateType.IgnoreRunRotation)
        end
        if self._stateData.PlayAttackMove then
            ctrl:SubAnimStateCount(AnimStateType.PlayAttackMove)
        end
        if self._stateData.IgnoreKeepDirection then
            ctrl:SubAnimStateCount(AnimStateType.IgnoreKeepDirection)
        end
    end
end

return AnimState
