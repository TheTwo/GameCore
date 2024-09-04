---@class ModuleRefer
local ModuleRefer = {};

local ModuleReferMeta = {
    __index = function(t, name)
        return g_Game.ModuleManager:RetrieveModule(name);
    end,
    __newindex = function(t, key, value)
        g_Logger.Error("ModuleRefer is forbidden to assign value manually, key is %s", tostring(key));
    end
};

setmetatable(ModuleRefer, ModuleReferMeta);

return ModuleRefer