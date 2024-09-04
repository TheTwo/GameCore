---
--- Created by wupei. DateTime: 2022/3/23
---

local SkillClientTarget = require("SkillClientTarget")

---@class SESkillClientTarget:SkillClientTarget
local SESkillClientTarget = class("SESkillClientTarget", SkillClientTarget)

---@param self SESkillClientTarget
---@param ... any
---@return void
function SESkillClientTarget:ctor(...)
    SESkillClientTarget.super.ctor(self, ...)
end

---@param self SESkillClientTarget
---@return SEActor
function SESkillClientTarget:GetCtrl()
    return self._ctrl
end

---@param self SESkillClientTarget
---@param animationBehavior Animation
---@return void
function SESkillClientTarget:OnAnimationStart(animationBehavior)
    local dataAnim = animationBehavior:GetDataAnim()
    local seqId = animationBehavior:GetSeqId()
    ---@type SEActor
    local ctrl = self:GetCtrl()
    if ctrl and ctrl:IsValid() then
        if ctrl:GetUnit():GetStateMachine():OnPerform(dataAnim, seqId) then
            return true
        end
    end
    return false
end

---@param self SESkillClientTarget
---@param animationBehavior Animation
---@param isCancel boolean
---@return void
function SESkillClientTarget:OnAnimationEnd(animationBehavior, isCancel)
    local dataAnim = animationBehavior:GetDataAnim()
    local seqId = animationBehavior:GetSeqId()
    ---@type SEActor
    local ctrl = self:GetCtrl()
    if ctrl and ctrl:IsValid() then
        ctrl:GetUnit():GetStateMachine():OnPerformEnd(dataAnim, seqId, isCancel)
    end
end

---@param self SESkillClientTarget
---@param speed SkillClientTarget
---@param any number
---@return void
function SESkillClientTarget:MultiplyAnimatorSpeed(speed)
    local ctrl = self:GetCtrl()
    if (ctrl and ctrl:IsValid()) then
        ctrl:GetUnit():GetStateMachine():MultiplyAnimatorSpeed(speed)
    end
end

---@param self SESkillClientTarget
---@param skillEvent skillclient.data.SkillEvent
---@param any SkillClientTarget
---@return void
function SESkillClientTarget:OnEventStart(skillEvent)
    local SkillEventType = require("SkillClientGen").SkillEventType
    if (skillEvent) then
        if (skillEvent.SkillEventType == SkillEventType.LockSelf) then
            --g_Logger.Log("SetClientDominated: true")
            local ctrl = self:GetCtrl()
            if (ctrl and ctrl:IsValid()) then
                ctrl:GetUnit():SetClientDominated(true)
            end
            --self.Environment:GetPlayer():SetClientDominated(true)
        end
    end
end

---@param self SESkillClientTarget
---@param skillEvent skillclient.data.SkillEvent
---@param any SkillClientTarget
---@return void
function SESkillClientTarget:OnEventEnd(skillEvent)
    local SkillEventType = require("SkillClientGen").SkillEventType
    if (skillEvent) then
        if (skillEvent.SkillEventType == SkillEventType.LockSelf) then
            --g_Logger.Log("SetClientDominated: false")
            local ctrl = self:GetCtrl()
            if (ctrl and ctrl:IsValid()) then
                ctrl:GetUnit():SetClientDominated(false)
            end
            --self.Environment:GetPlayer():SetClientDominated(false)
        end
    end
end

---@param self SESkillClientTarget
---@return void
function SESkillClientTarget:GetCtrlEffectTag()
    if self:IsCtrlValid() then
        return self:GetCtrl():GetUnit():GetData():GetConfig():HiteffectTag()
    end
    return 0
end

---@param self SESkillClientTarget
---@param value any
---@return void
function SESkillClientTarget:SetPlayingSkill(value)
    if self:IsCtrlValid() then
        self:GetCtrl():GetUnit():SetPlayingSkill(value)
    end
end

---@param self SESkillClientTarget
---@return void
function SESkillClientTarget:IsPlayer()
    -- if self:IsCtrlValid() then
    --     return self:GetCtrl():GetUnit():IsPlayer()
    -- end
    return false
end

---@param self SESkillClientTarget
---@param forward any
---@param time any
---@param useRotAnim any
---@return void
function SESkillClientTarget:SetForward(forward, time, useRotAnim)
    if self:IsCtrlValid() then
        return self:GetCtrl():SetForward(forward, time, useRotAnim)
    end
    return nil
end

---@param self SESkillClientTarget
---@return CS.UnityEngine.Transform
function SESkillClientTarget:GetFbxTransform()
    if self:IsCtrlValid() then
        return self:GetCtrl():GetFbxTransform()
    end
    return nil
end

---@param self SESkillClientTarget
---@return CS.UnityEngine.Animator|nil
function SESkillClientTarget:GetAnimator()
    if self:IsCtrlValid() then
        return self:GetCtrl():GetAnimator()
    end
    return nil
end

---@param self SESkillClientTarget
---@param count any
---@return void
function SESkillClientTarget:AddRendererInvisibleCount(count)
    if self:IsCtrlValid() then
        self:GetCtrl():AddRendererInvisibleCount(count)
    end
end

return SESkillClientTarget
