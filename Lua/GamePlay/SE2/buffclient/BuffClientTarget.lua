---
--- Created by wupei. DateTime: 2022/3/1
---

---@class BuffClientTarget
local BuffClientTarget = class("BuffClientTarget")

---@param self BuffClientTarget
---@param buffParam any
---@return void
function BuffClientTarget:ctor(buffParam)
    ---@type SEActor
    self._ctrl = nil
    ---@type BuffClientParam
    self._buffParam = buffParam
end

---@param self BuffClientTarget
---@return void
function BuffClientTarget:GetID()
    local ctrl = self:GetCtrl()
    if ctrl then
        return ctrl:GetID()
    end
    return 0
end

---@param self BuffClientTarget
---@return BuffClientParam
function BuffClientTarget:GetBuffParam()
    return self._buffParam
end

---@param self BuffClientTarget
---@param ctrl SEActor
---@return void
function BuffClientTarget:SetCtrl(ctrl)
    self._ctrl = ctrl
end

---@param self BuffClientTarget
---@return SEActor
function BuffClientTarget:GetCtrl()
    return self._ctrl
end

---@param self BuffClientTarget
---@return void
function BuffClientTarget:IsCtrlValid()
    return self._ctrl ~= nil and self._ctrl:IsValid()
end

function BuffClientTarget:IsCtrlFbxValid()
    return self._ctrl ~= nil and self._ctrl:IsValid() and self._ctrl:IsFbxObjectValid()
end

---@param self BuffClientTarget
---@param target any
---@return void
function BuffClientTarget:Equal(target)
    return target ~= nil and self._ctrl == target._ctrl
end

---@param self BuffClientTarget
---@param iconPath string
---@return void
function BuffClientTarget:AddBuffIcon(iconPath)
    if self._ctrl and self._ctrl:IsValid() then
        self._ctrl:AddBuffIcon(iconPath)
    end
end

---@param self BuffClientTarget
---@param text any
---@return void
function BuffClientTarget:AddBuffText(text)
    if self._ctrl and self._ctrl:IsValid() then
        self._ctrl:AddBuffText(text)
    end
end

local Vector3 = CS.UnityEngine.Vector3

local MulV3 = function(v1, v2)
    return Vector3(v1.x*v2.x, v1.y*v2.y, v1.z*v2.z)
end

local DivV3 = function(v1, v2)
    return Vector3(v1.x/v2.x, v1.y/v2.y, v1.z/v2.z)
end


---@param self BuffClientTarget
---@param scale Vector3
---@return void
function BuffClientTarget:MulScale(scale)
    if self._ctrl and self._ctrl:IsValid() then
        local transform = self:GetFbxTransform()
        local targetScale = MulV3(transform.localScale, scale)
        transform.localScale = targetScale
    end
end

---@param self BuffClientTarget
---@param scale any
---@return void
function BuffClientTarget:DivScale(scale)
    if self._ctrl and self._ctrl:IsValid() then
        local transform = self:GetFbxTransform()
        local targetScale = DivV3(transform.localScale, scale)
        transform.localScale = targetScale
    end
end

---@param self BuffClientTarget
---@return void
function BuffClientTarget:GetTransform()
    return self._ctrl:GetTransform()
end

function BuffClientTarget:GetFbxTransform()
    return self._ctrl:GetFbxTransform()
end

---@param self BuffClientTarget
---@param offsetOrNil any
---@return UnityEngine.Vector3
function BuffClientTarget:GetPosition(offsetOrNil)
    if self._ctrl then
        local pos = self._ctrl:GetPosition()
        if (not pos) then
            g_Logger.Error("self._ctrl:GetPosition() = %s", pos)
        end
        if offsetOrNil and self._ctrl:IsValid() then
            pos = pos + self._ctrl:GetTransform().rotation * Vector3(offsetOrNil.x, offsetOrNil.y, offsetOrNil.z)
        end
        return pos
    end
    g_Logger.Error("BuffClientTarget:GetPosition() no data")
    return nil
end

---@param self BuffClientTarget
---@param speed any
---@return void
function BuffClientTarget:MultiplyAnimatorSpeed(speed)

end

---@param self BuffClientTarget
---@param state any
---@param speed any
---@return void
function BuffClientTarget:MultiplyAnimatorStateSpeed(state, speed)

end

---@param self BuffClientTarget
---@return void
function BuffClientTarget:GetAnimator()
    
end

---@param self BuffClientTarget
---@param damageTextData any
---@return void
function BuffClientTarget:SpawnDamageNum(damageTextData)

end

---@param self BuffClientTarget
---@return void
function BuffClientTarget:SyncHpClientFromKeyEvent()

end

return BuffClientTarget
