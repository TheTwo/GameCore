--- Created by wupei. DateTime: 2021/7/1

---@class SkillClientTarget
local SkillClientTarget = class("SkillClientTarget")
local SkillClientEnum = require("SkillClientEnum")
local Vector3 = CS.UnityEngine.Vector3

---@param self SkillClientTarget
---@param skillParam SkillClientParam
---@return void
function SkillClientTarget:ctor(skillParam)
    ---@type SkillClientParam
    self._skillParam = skillParam
    self._type = -1
	---@type SEActor
    self._ctrl = nil
    self._pos = nil
    self._damageKey = 0
end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:GetID()
    local ctrl = self:GetCtrl()
    if ctrl then
        return ctrl:GetID()
    end
    return 0
end

---@param self SkillClientTarget
---@return SkillClientParam
function SkillClientTarget:GetSkillParam()
    return self._skillParam
end

---@param self SkillClientTarget
---@param type any
---@param ctrlOrNil any
---@param posOrNil any
---@return void
function SkillClientTarget:SetInfo(type, ctrlOrNil, posOrNil)
    self._type = type
    self._ctrl = ctrlOrNil
    self._pos = posOrNil
end

---@param self SkillClientTarget
---@return any
function SkillClientTarget:GetCtrl()
    return self._ctrl
end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:IsCtrlValid()
    return self._ctrl ~= nil and self._ctrl:IsValid()
end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:HasCtrlAndDead()
    if self._ctrl and self._ctrl:IsValid() and self._ctrl:IsDead() and self._ctrl.CastSkillWhenDead and not self._ctrl:CastSkillWhenDead() then
        return true
    end
    return false
end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:HasCtrl()
    if self._ctrl and self._ctrl:IsValid() then
        return true
    end
    return false
end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:GetType()
    return self._type
end

---@param self SkillClientTarget
---@param damageKey any
---@return void
function SkillClientTarget:SetDamageKey(damageKey)
    self._damageKey = damageKey
end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:GetDamageKey()
    return self._damageKey
end

---@param self SkillClientTarget
---@return CS.UnityEngine.Transform
function SkillClientTarget:GetTransform()
    if not self._ctrl or not self._ctrl:IsValid() then
        return nil
    end
    return self._ctrl:GetTransform()
end

---@param self SkillClientTarget
---@param offsetOrNil any
---@param offsetRotOrNil any
---@return CS.UnityEngine.Vector3
function SkillClientTarget:GetPosition(offsetOrNil, offsetRotOrNil)
    if self._ctrl then
        local pos = self._ctrl:GetPosition()
        if (not pos) then
            g_Logger.Trace("self._ctrl:GetPosition() = %s", pos)
            return nil
        end
        if offsetOrNil and self._ctrl:IsValid() then
            if offsetRotOrNil then
                pos = pos + offsetRotOrNil * Vector3(offsetOrNil.x, offsetOrNil.y, offsetOrNil.z)
            else
                pos = pos + self._ctrl:GetTransform().rotation * Vector3(offsetOrNil.x, offsetOrNil.y, offsetOrNil.z)
            end
        end
        return pos
    elseif self._pos then
        if offsetOrNil then
            return Vector3(self._pos.x + offsetOrNil.x, self._pos.y + offsetOrNil.y, self._pos.z + offsetOrNil.z)
        else
            return self._pos
        end
    end
    g_Logger.Warn("SkillData:GetSrcPosition() no data")
    return nil
end


---@param self SkillClientTarget
---@param offsetOrNil any
---@return CS.UnityEngine.Vector3
function SkillClientTarget:GetPositionPriorityPos(offsetOrNil)
    if self._pos then
        return self._pos
    elseif self._ctrl then
        local pos = self._ctrl:GetPosition()
        if (not pos) then
            g_Logger.Error("self._ctrl:GetPosition() = %s", pos)
        end
        if offsetOrNil and self._ctrl:IsValid() then
            local offset = self._ctrl:GetTransform().rotation * Vector3(offsetOrNil.x, offsetOrNil.y, offsetOrNil.z)
            pos = Vector3(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z)
        end
        return pos
    end
    g_Logger.Error("SkillData:GetSrcPosition() no data")
    return nil
end

---@param self SkillClientTarget
---@param attachNodeNameOrNil any
---@param offsetOrNil any
---@return void
function SkillClientTarget:GetAttachNodePosition(attachNodeNameOrNil, offsetOrNil)
    if self._ctrl then
        local pos = self._ctrl:GetPosition()
        if (not pos) then
            g_Logger.Error("self._ctrl:GetPosition() = %s", pos)
        end
        if string.isNotEmpty(attachNodeNameOrNil) then
            local trans = self._ctrl:GetTransform():FirstOrDefaultByName(attachNodeNameOrNil)
            if trans then
                pos = trans.position
            else
                g_Logger.Error("attachNodeName not found. name: %s, root: %s", attachNodeNameOrNil, self._ctrl:GetTransform().name)
            end
        end
        if offsetOrNil and self._ctrl:IsValid() then
            local offset = self._ctrl:GetTransform().rotation * Vector3(offsetOrNil.x, offsetOrNil.y, offsetOrNil.z)
            pos = Vector3(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z)
        end
        return pos
    elseif self._pos then
        return self._pos
    end
    g_Logger.Error("SkillData:GetSrcPosition() no data")
    return nil
end

---@param self SkillClientTarget
---@return CS.UnityEngine.Transform
function SkillClientTarget:GetOtherTransform()
    if self._type == SkillClientEnum.SkillTargetType.Attacker then
        return self._skillParam:GetTarget():GetTransform()
    elseif self._type == SkillClientEnum.SkillTargetType.Target then
        return self._skillParam:GetAttacker():GetTransform()
    else
        return self._skillParam:GetAttacker():GetTransform()
    end
end

---@param self SkillClientTarget
---@param offsetOrNil any
---@param offsetRotOrNil any
---@return CS.UnityEngine.Vector3
function SkillClientTarget:GetOtherPosition(offsetOrNil, offsetRotOrNil)
    if self._type == SkillClientEnum.SkillTargetType.Attacker then
        return self._skillParam:GetTarget():GetPosition(offsetOrNil, offsetRotOrNil)
    elseif self._type == SkillClientEnum.SkillTargetType.Target then
        return self._skillParam:GetAttacker():GetPosition(offsetOrNil, offsetRotOrNil)
    else
        return self._skillParam:GetAttacker():GetPosition(offsetOrNil, offsetRotOrNil)
    end
end

---@param self SkillClientTarget
---@return CS.UnityEngine.Vector3
function SkillClientTarget:GetForward()
    if self:IsCtrlValid() then
        local forward = self:GetCtrl():GetForward()
        if forward then
            return Vector3(forward.x, 0, forward.z)
        end
    end
    return Vector3.zero
end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:GetForwardToEnemy()
    local forward
    if self._type == SkillClientEnum.SkillTargetType.Attacker then
        local attackerPos = self:GetPosition()
        local targetPos = self._skillParam:GetTarget():GetPosition()
        forward = targetPos - attackerPos
    elseif self._type == SkillClientEnum.SkillTargetType.Target then
        local attackerPos = self._skillParam:GetAttacker():GetPosition()
        local targetPos = self:GetPosition()
        forward = attackerPos - targetPos
    else
        local attackerPos = self._skillParam:GetAttacker():GetPosition()
        local targetPos = self:GetPosition()
        forward = attackerPos - targetPos
    end
    forward.y = 0
    return forward
end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:GetForwardFromEnemyToAttacker()
    local attackerPos = self._skillParam:GetAttacker():GetPosition()
    local targetPos = self._skillParam:GetTarget():GetPosition()
    local forward = attackerPos - targetPos
    forward.y = 0
    return forward
end

---@param self SkillClientTarget
---@param target SkillClientTarget
---@return void
function SkillClientTarget:EqualCtrl(target)
    local selfCtrl = self:GetCtrl()
    if selfCtrl ~= nil and selfCtrl == target:GetCtrl() then
        return true
    end
    return false
end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:GetCtrlEffectTag()
    return 0
end

---@param self SkillClientTarget
---@param animationBehavior Animation
---@return void
function SkillClientTarget:OnAnimationStart(animationBehavior)
    return false
end

---@param self SkillClientTarget
---@param animationBehavior Animation
---@param isCancel boolean
---@return void
function SkillClientTarget:OnAnimationEnd(animationBehavior, isCancel)

end

---@param self SkillClientTarget
---@param skillTarget SkillClientTarget
---@param speed number
---@return void
function SkillClientTarget:MultiplyAnimatorSpeed(skillTarget, speed)

end

---@param self SkillClientTarget
---@param skillEvent skillclient.data.SkillEvent
---@return void
function SkillClientTarget:OnEventStart(skillEvent)

end

---@param self SkillClientTarget
---@param skillEvent skillclient.data.SkillEvent
---@return void
function SkillClientTarget:OnEventEnd(skillEvent)

end

---@param self SkillClientTarget
---@param value any
---@return void
function SkillClientTarget:SetPlayingSkill(value)

end

---@param self SkillClientTarget
---@return void
function SkillClientTarget:IsPlayer()
    return false
end

---@param self SkillClientTarget
---@param forward any
---@param time any
---@param useRotAnim any
---@return void
function SkillClientTarget:SetForward(forward, time, useRotAnim)

end

---@param self SkillClientTarget
---@return CS.UnityEngine.Transform
function SkillClientTarget:GetFbxTransform()

end

---@param self SkillClientTarget
---@return CS.UnityEngine.Animator
function SkillClientTarget:GetAnimator()

end

---@param self SkillClientTarget
---@param count any
---@return void
function SkillClientTarget:AddRendererInvisibleCount(count)

end

return SkillClientTarget
