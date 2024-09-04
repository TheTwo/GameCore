---@class AttrProviderBase
---@field new fun():AttrProviderBase
local AttrProviderBase = class("AttrProviderBase")
AttrProviderBase.EnableLog = false

---@param baseCfgMap table<number, AttrElementConfigCell>
---@param multiCfgMap table<number, AttrElementConfigCell>
---@param pointCfgMap table<number, AttrElementConfigCell>
function AttrProviderBase:Calculate(baseCfgMap, multiCfgMap, pointCfgMap, logAttrType)
    ---override this
    return 0, 0, 0
end

return AttrProviderBase