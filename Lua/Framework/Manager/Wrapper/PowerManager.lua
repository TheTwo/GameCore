local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseManager = require("BaseManager")

---@class PowerManager:BaseManager
---@field new fun():PowerManager
---@field super BaseManager
local PowerManager = class('PowerManager', BaseManager)

function PowerManager:ctor()
    ---@type CS.DragonReborn.Utilities.PowerManager
    self.csManager = CS.DragonReborn.Utilities.PowerManager.Instance
    self.csManager:OnGameInitialize()
end

function PowerManager:GetCurrentThermalStatus()
    return self.csManager:GetCurrentThermalStatus()
end

function PowerManager:IsPowerSaveMode()
    return self.csManager:IsPowerSaveMode()
end

function PowerManager:KeepScreenOn()
    self.csManager:KeepScreenOn()
end

function PowerManager:NoKeepScreenOn()
    self.csManager:NoKeepScreenOn()
end

function PowerManager:BackupAndroidWindowFlags()
    self.csManager:BackupAndroidWindowFlags()
end

function PowerManager:RestoreAndroidWindowFlags()
    self.csManager:RestoreAndroidWindowFlags()
end

function PowerManager:Reset()
    self.csManager:Reset()
end

function PowerManager:OnLowMemory()
    try_catch_traceback_with_vararg(self.csManager.OnLowMemory, nil, self.csManager)
end

return PowerManager