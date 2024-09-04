---
--- Created by wupei. DateTime: 2022/4/26
---

local BuffClientTarget = require("BuffClientTarget")

---@class SEBuffClientTarget:BuffClientTarget
local SEBuffClientTarget = class("SEBuffClientTarget", BuffClientTarget)

---@param self SEBuffClientTarget
---@param ... any
---@return void
function SEBuffClientTarget:ctor(...)
    SEBuffClientTarget.super.ctor(self, ...)
end

---@param self SEBuffClientTarget
---@return SEActor
function SEBuffClientTarget:GetActor()
    return self._ctrl
end

---@param self SEBuffClientTarget
---@param speed any
---@return void
function SEBuffClientTarget:MultiplyAnimatorSpeed(speed)
    if not self:IsCtrlFbxValid() then
        return
    end
    self:GetActor():GetUnit():GetStateMachine():MultiplyAnimatorSpeed(speed)
end

---@param self SEBuffClientTarget
---@param state any
---@param speed any
---@return void
function SEBuffClientTarget:MultiplyAnimatorStateSpeed(state, speed)
    if not self:IsCtrlFbxValid() then
        return
    end
    return self:GetActor():GetUnit():GetStateMachine():MultiplyAnimatorStateSpeed(state, speed)
end

---@param self SEBuffClientTarget
---@return void
function SEBuffClientTarget:GetAnimator()
    if not self:IsCtrlFbxValid() then
        return
    end
    return self:GetActor():GetAnimator()
end

---@param self SEBuffClientTarget
---@param damageTextData any
---@return void
function SEBuffClientTarget:SpawnDamageNum(damageTextData)
end

---@param self SEBuffClientTarget
---@return void
function SEBuffClientTarget:SyncHpClientFromKeyEvent()
    if not self:IsCtrlFbxValid() then
        return
    end

    return self:GetActor():SyncHpClientFromKeyEvent()
end

return SEBuffClientTarget
