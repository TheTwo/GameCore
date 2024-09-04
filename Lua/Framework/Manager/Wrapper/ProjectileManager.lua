local Delegate = require('Delegate')
local BaseManager = require('BaseManager')

---@class ProjectileManager : BaseManager
---@field new fun():ProjectileManager
local ProjectileManager = class('ProjectileManager', BaseManager)

function ProjectileManager:ctor()
    self.manager = CS.DragonReborn.Projectile.ProjectileManager.Instance
    self.manager:OnGameInitialize(nil)
    g_Game:AddSystemTicker(Delegate.GetOrCreate(self, self.Tick))
end

function ProjectileManager:Tick(delta)
    self.manager:Tick(delta)
end

function ProjectileManager:Reset()
    try_catch_traceback_with_vararg(self.manager.Reset, nil, self.manager)
    g_Game:RemoveSystemTicker(Delegate.GetOrCreate(self, self.Tick))
end

function ProjectileManager:OnLowMemory()
    try_catch_traceback_with_vararg(self.manager.OnLowMemory, nil, self.manager)
end

function ProjectileManager:CreateProjectile(config, source, target, hitAction, userData, debugName)
    self.manager:CreateProjectile(config, source, target, hitAction, userData, debugName)
end

return ProjectileManager