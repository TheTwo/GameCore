---
--- Created by wupei. DateTime: 2022/3/1
---

---@class BuffBehavior
local BuffBehavior = class("BuffBehavior");

---@param self BuffBehavior
---@param data any
---@param target BuffClientTarget
---@return void
function BuffBehavior:ctor(data, target)
    self._param = nil
    self._data = data
    ---@type BuffClientTarget
    self._target = target
    self._isCtrlValid = false
end

--local gen = require("BuffClientGen")

---@param self BuffBehavior
---@return void
function BuffBehavior:DoOnStart()
    self._isCtrlValid = false
    if not self._isCtrlValid then
        if self._target and self._target:IsCtrlFbxValid() then
            self._isCtrlValid = true
        end
    end
    self:OnStart()
end

function BuffBehavior:DoOnCtrlValid()
    self:OnCtrlValid()
end


---@param self BuffBehavior
---@return void
function BuffBehavior:DoOnUpdate()
    if not self._isCtrlValid then
        if self._target and self._target:IsCtrlFbxValid() then
            self._isCtrlValid = true
            self:DoOnCtrlValid()
        end
    end
    self:OnUpdate()
end

---@param self BuffBehavior
---@return void
function BuffBehavior:DoOnEnd()
    self:OnEnd()
end

---@param self BuffBehavior
---@return void
function BuffBehavior:OnStart()

end

---@param self BuffBehavior
---@return void
function BuffBehavior:OnCtrlValid()
end

---@param self BuffBehavior
---@return void
function BuffBehavior:OnUpdate()

end

---@param self BuffBehavior
---@return void
function BuffBehavior:OnEnd()

end

return BuffBehavior
