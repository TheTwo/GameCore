--- Created by hao.wu.ss. DateTime: 2023/3/31

local Behavior = require("Behavior")

---@class EnergyRestoreEffect:Behavior
---@field super Behavior
local EnergyRestoreEffect = class("EnergyRestoreEffect", Behavior)

---@param self EnergyRestoreEffect
---@param ... any
---@return void
function EnergyRestoreEffect:ctor(...)
    EnergyRestoreEffect.super.ctor(self, ...)
end

---@param self EnergyRestoreEffect
---@return void
function EnergyRestoreEffect:OnStart()
end

return EnergyRestoreEffect
