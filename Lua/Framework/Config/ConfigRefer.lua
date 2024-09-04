---@type ConfigRefer
local ConfigRefer = {}
local ConfigReferMt = {}

function ConfigReferMt.__index(t, k)
    return g_Game.ConfigManager:RetrieveConfig(k);
end

function ConfigReferMt.__newindex(t, k, v)
    g_Logger.Error("ConfigRefer is forbidden to assign value manually");
end

---@type ConfigRefer
local ret = setmetatable(ConfigRefer, ConfigReferMt)
return ret;