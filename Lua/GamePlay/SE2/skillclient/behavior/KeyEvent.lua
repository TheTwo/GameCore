---
--- Created by wupei. DateTime: 2022/1/21
---

local Behavior = require("Behavior")

---@class KeyEvent:Behavior
---@field super Behavior
local KeyEvent = class("KeyEvent", Behavior)

---@param self KeyEvent
---@param ... any
---@return void
function KeyEvent:ctor(...)
    KeyEvent.super.ctor(self, ...)
end

---@param self KeyEvent
---@return void
function KeyEvent:OnStart()
    if self._skillTarget:IsCtrlValid() then
        local ctrl = self._skillTarget:GetCtrl()
        ctrl:SyncHpClientFromKeyEvent()
    end
end

return KeyEvent
