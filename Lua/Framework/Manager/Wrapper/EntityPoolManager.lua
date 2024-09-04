local Delegate = require('Delegate')
---@type DeviceUtil
local DeviceUtil = require('DeviceUtil')

---@class EntityPoolManager
---@field new fun():EntityPoolManager
local EntityPoolManager = class("EntityPoolManager", require("BaseManager"))

function EntityPoolManager:ctor()
    self.manager = CS.DragonReborn.AssetTool.ECS.EntityPoolManager.Instance;
    self.manager:OnGameInitialize(nil)
    g_Game:AddSystemTicker(Delegate.GetOrCreate(self,self.Tick))
	
	if DeviceUtil.IsLowMemoryDevice() then
		self.manager.UnusedCacheLimit = 200
		self.manager.CachedEntityLimit = 5
        self.manager.DefaultPoolCacheSize = 10
	else
		self.manager.UnusedCacheLimit = 200
		self.manager.CachedEntityLimit = 20
        self.manager.DefaultPoolCacheSize = 50
	end
end

function EntityPoolManager:Tick(delta)
    self.manager:Tick(delta)
end

function EntityPoolManager:Reset()
    try_catch_traceback_with_vararg(self.manager.Reset, nil, self.manager)
    g_Game:RemoveSystemTicker(Delegate.GetOrCreate(self,self.Tick))
end

function EntityPoolManager:OnLowMemory()
    try_catch_traceback_with_vararg(self.manager.OnLowMemory, nil, self.manager)
end

function EntityPoolManager:Clear(name)
    self.manager:Clear(name)
end

return EntityPoolManager
