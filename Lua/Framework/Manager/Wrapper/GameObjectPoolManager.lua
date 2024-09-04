local Delegate = require('Delegate')
---@type DeviceUtil
local DeviceUtil = require('DeviceUtil')

---@class GameObjectPoolManager
---@field new fun():GameObjectPoolManager
local GameObjectPoolManager = class("GameObjectPoolManager", require("BaseManager"))

function GameObjectPoolManager:ctor()
    ---@type CS.DragonReborn.AssetTool.GameObjectPoolManager
    self.manager = CS.DragonReborn.AssetTool.GameObjectPoolManager.Instance;
    self.manager:OnGameInitialize(nil)
    g_Game:AddSystemTicker(Delegate.GetOrCreate(self,self.Tick))

	if DeviceUtil.IsLowMemoryDevice() then
		self.manager.UnusedCacheLimit = 200
		self.manager.CachedGameObjectLimit = 5
        self.manager.DefaultPoolCacheSize = 10
	else
		self.manager.UnusedCacheLimit = 200
		self.manager.CachedGameObjectLimit = 20
        self.manager.DefaultPoolCacheSize = 50
	end
end

function GameObjectPoolManager:Tick(delta)
    self.manager:Tick(delta)
end

function GameObjectPoolManager:Reset()
    try_catch_traceback_with_vararg(self.manager.Reset, nil, self.manager)
    g_Game:RemoveSystemTicker(Delegate.GetOrCreate(self,self.Tick))
end

function GameObjectPoolManager:OnLowMemory()
    try_catch_traceback_with_vararg(self.manager.OnLowMemory, nil, self.manager)
end

function GameObjectPoolManager:Clear(name)
	self.manager:Clear(name)
end

return GameObjectPoolManager
