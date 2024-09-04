--- Created by wupei. DateTime: 2021/7/1

local Behavior = require("Behavior")

---@class CameraShake:Behavior
---@field super Behavior
local CameraShake = class("CameraShake", Behavior)

---@type skillclient.data.CameraShake
CameraShake._dataShake = nil

---@param self CameraShake
---@param ... any
---@return void
function CameraShake:ctor(...)
    CameraShake.super.ctor(self, ...)

    ---@type skillclient.data.CameraShake
    self._dataShake = self._data
end

---@param self CameraShake
---@return void
function CameraShake:OnStart()
    self._manager.native:CameraShake(self._dataShake)
end

return CameraShake
