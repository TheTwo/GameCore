---
--- Created by wupei. DateTime: 2022/1/18
---

local Behavior = require("Behavior")
local SkillClientEnum = require("SkillClientEnum")

---@class AdjustPos:Behavior
---@field super Behavior
local AdjustPos = class("AdjustPos", Behavior)

---@param self AdjustPos
---@param ... any
---@return void
function AdjustPos:ctor(...)
    AdjustPos.super.ctor(self, ...)

    ---@type skillclient.data.AdjustPos
    self._adjustPosData = self._data
end

---@param self AdjustPos
---@return void
function AdjustPos:OnStart()
    local ctrl = self._skillTarget:GetCtrl()
    if ctrl and ctrl:IsValid() then
        local type = self._skillTarget:GetType()
        if type == SkillClientEnum.SkillTargetType.Attacker then
            local pos = self._manager.native:ConvertServerPos(self._skillParam:GetServerData().Pos)
            ctrl:TeleportTo(pos)
        else
            g_Logger.Error("AdjustPos not support this type: %s", type)
        end
    end
end

return AdjustPos
