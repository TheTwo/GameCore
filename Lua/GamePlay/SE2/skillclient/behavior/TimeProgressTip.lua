---
--- Created by wupei. DateTime: 2021/10/26
---

local Behavior = require("Behavior")

---@class TimeProgressTip:Behavior
---@field super Behavior
local TimeProgressTip = class("TimeProgressTip", Behavior)

---@param self TimeProgressTip
---@param ... any
---@return void
function TimeProgressTip:ctor(...)
    TimeProgressTip.super.ctor(self, ...)

    ---@type skillclient.data.TimeProgressTip
    self._tipData = self._data
end

---@param self TimeProgressTip
---@return void
function TimeProgressTip:OnStart()
    local ctrl = self._skillTarget:GetCtrl()
    if ctrl and ctrl:IsValid() then
        if ctrl.StartTimeProgressTip then
            ctrl:StartTimeProgressTip(self._tipData)
        else
            g_Logger.Error("ctrl no implement StartTimeProgressTip()")
        end
    end
end

---@param self TimeProgressTip
---@return void
function TimeProgressTip:OnEnd()
    local ctrl = self._skillTarget:GetCtrl()
    if ctrl and ctrl:IsValid() then
        if ctrl.EndTimeProgressTip then
            ctrl:EndTimeProgressTip(self._tipData)
        else
            g_Logger.Error("ctrl no implement StartTimeProgressTip()")
        end
    end
end

return TimeProgressTip
