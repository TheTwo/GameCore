---
--- Created by wupei. DateTime: 2022/2/24
---

local BuffClientEnum = require("BuffClientEnum")

---@class BuffClientParam
local BuffClientParam = class("BuffClientParam")

---@param self BuffClientParam
---@param uniqueId number
---@param buffConfigId number
---@return void
function BuffClientParam:ctor(uniqueId, buffConfigId)
    self._uniqueId = uniqueId
    self._buffConfigId = buffConfigId
    ---@type BuffClientManager
    self._manager = nil
    self._target = nil
    self._targetClass = require("BuffClientTarget")
    self._stage = ""
    self._buffPerformId = 0
end

---@param self BuffClientParam
---@param buffPerformId number
function BuffClientParam:SetPerformId(buffPerformId)
    self._buffPerformId = buffPerformId
end

---@param self BuffClientParam
---@param targetClass any
---@return void
function BuffClientParam:SetTargetClass(targetClass)
    self._targetClass = targetClass
end

---@param self BuffClientParam
---@param buffParam BuffClientParam
---@return void
function BuffClientParam:Equal(buffParam)
    if self._uniqueId == buffParam._uniqueId 
        and self._buffConfigId == buffParam._buffConfigId
        and self._target:Equal(buffParam._target) then
        return true
    end
    return false
end

---@param self BuffClientParam
function BuffClientParam:GetBuffPerformId()
    return self._buffPerformId
end

---@param self BuffClientParam
function BuffClientParam:GetBuffUniqueId()
    return self._uniqueId
end

---@param self BuffClientParam
function BuffClientParam:GetBuffConfigId()
    return self._buffConfigId
end

---@param self BuffClientParam
---@param manager BuffClientManager
---@return void
function BuffClientParam:SetManager(manager)
    self._manager = manager
end

---@param self BuffClientParam
---@param ctrl any
---@return void
function BuffClientParam:SetTarget(ctrl)
    self._target = self._targetClass.new(self)
    self._target:SetCtrl(ctrl)
end

---@param self BuffClientParam
---@return BuffClientTarget
function BuffClientParam:GetTarget()
    return self._target
end

---@param self BuffClientParam
---@return void
function BuffClientParam:SetStageLogic()
    self._stage = BuffClientEnum.Stage.Logic
end

---@param self BuffClientParam
---@return void
function BuffClientParam:GetStage()
    return self._stage
end

return BuffClientParam
