--- Created by wupei. DateTime: 2021/6/30

local Behavior = require("Behavior")

---@class DamageText:Behavior
---@field super Behavior
local DamageText = class("DamageText", Behavior)

---@param self DamageText
---@param ... any
---@return void
function DamageText:ctor(...)
    DamageText.super.ctor(self, ...)

    ---@type skillclient.data.DamageText
    self._damageData = self._data
end

---@param self DamageText
---@return void
function DamageText:OnStart()
    self._manager.native:SpawnDamageNum(self._damageData, self._skillTarget, self._skillParam:GetServerData())
end

---@param self DamageText
---@return void
function DamageText:OnUpdate()

end

---@param self DamageText
---@return void
function DamageText:OnEnd()

end

return DamageText
