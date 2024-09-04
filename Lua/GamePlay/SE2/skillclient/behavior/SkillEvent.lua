---
--- Created by wupei. DateTime: 2021/9/18
---

local Behavior = require("Behavior")

---@class SkillEvent:Behavior
---@field super Behavior
local SkillEvent = class("SkillEvent", Behavior)

---@param self SkillEvent
---@param ... any
---@return void
function SkillEvent:ctor(...)
    SkillEvent.super.ctor(self, ...)

    ---@type skillclient.data.SkillEvent
    self._skillEvent = self._data
end

---@param self SkillEvent
---@return void
function SkillEvent:OnStart()
    self._skillTarget:OnEventStart(self._skillEvent)
end

---@param self SkillEvent
---@return void
function SkillEvent:OnEnd()
    self._skillTarget:OnEventEnd(self._skillEvent)
end

return SkillEvent
