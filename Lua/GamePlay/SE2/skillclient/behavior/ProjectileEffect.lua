---
--- Created by wupei. DateTime: 2021/9/14
---

local Behavior = require("Behavior")

---@class ProjectileEffect:Behavior
---@field super Behavior
local ProjectileEffect = class("ProjectileEffect", Behavior)
local Vector3 = CS.UnityEngine.Vector3

---@param self ProjectileEffect
---@param ... any
---@return void
function ProjectileEffect:ctor(...)
    ProjectileEffect.super.ctor(self, ...)

    ---@type skillclient.data.ProjectileEffect
    self._projectileEffect = self._data
end

---@param self ProjectileEffect
---@return void
function ProjectileEffect:OnStart()
    local data = self._projectileEffect
    local conf = CS.HeightFixedParabolaConfig()
    conf.Height = data.Height
    conf.Gravity = data.Gravity
    conf.Prefab = data.EffectPath
    conf.Pool = "SeVfx"
    local source = CS.GenericTransform()
    if string.IsNullOrEmpty(data.AttachNodeName) then
        source.Position = self._skillTarget:GetPosition(data.Offset)
    else
        source.Position = self._skillTarget:GetAttachNodePosition(data.AttachNodeName, data.Offset)
    end
    source.Scale = Vector3(data.Scale.x, data.Scale.y, data.Scale.z)
    local dest = CS.GenericTransform()
    local dstScale = Vector3(data.Scale.x, data.Scale.y, data.Scale.z)
    dest.Position = self._skillTarget:GetOtherPosition()
    dest.Scale = dstScale
    g_Game.ProjectileManager:CreateProjectile(conf, source, dest, nil)
end
