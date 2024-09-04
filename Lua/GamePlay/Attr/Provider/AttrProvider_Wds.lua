local AttrProviderBase = require("AttrProviderBase")
local ModuleRefer = require("ModuleRefer")
---@class AttrProvider_Wds:AttrProviderBase
---@field new fun():AttrProvider_Wds
---@field map table<number, number>
local AttrProvider_Wds = class("AttrProvider_Wds", AttrProviderBase)
local SkipCache = false

function AttrProvider_Wds:ctor(map)
    self:UpdateWds(map)
end

---@param map table<number, number>
function AttrProvider_Wds:UpdateWds(map)
    self.map = map
    self.baseValues = {}
    self.multiValues = {}
    self.pointValues = {}
    return self
end

---@param baseCfgMap table<number, AttrElementConfigCell>
---@param multiCfgMap table<number, AttrElementConfigCell>
---@param pointCfgMap table<number, AttrElementConfigCell>
function AttrProvider_Wds:Calculate(baseCfgMap, multiCfgMap, pointCfgMap, logAttrType)
    local baseValue = self:CalculateBase(baseCfgMap, logAttrType)
    local multiValue = self:CalculateMulti(multiCfgMap, logAttrType)
    local pointValue = self:CalculatePoint(pointCfgMap, logAttrType)

    return baseValue, multiValue, pointValue
end

function AttrProvider_Wds:CalculateBase(baseCfgMap, logAttrType)
    return self:CalculateImp(baseCfgMap, self.baseValues, "Base", logAttrType)
end

function AttrProvider_Wds:CalculateMulti(multiCfgMap, logAttrType)
    return self:CalculateImp(multiCfgMap, self.multiValues, "Multi", logAttrType)
end

function AttrProvider_Wds:CalculatePoint(pointCfgMap, logAttrType)
    return self:CalculateImp(pointCfgMap, self.pointValues, "Point", logAttrType)
end

---@param cfgMap table<number, AttrElementConfigCell>
function AttrProvider_Wds:CalculateImp(cfgMap, valuesCache, logTag, logAttrType)
    if cfgMap == nil then return 0 end

    if not SkipCache and valuesCache[cfgMap] then
        return valuesCache[cfgMap]
    end

    local ret = 0
    for id, value in pairs(self.map) do
        if cfgMap[id] then
            local cfg = cfgMap[id]
            local plusValue = ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
            ret = ret + plusValue
            if self.EnableLog then
                g_Logger.TraceChannel("属性计算器", "[计算%s][%s]读取到值[%.2f]", logAttrType, logTag, plusValue)
            end
        end
    end

    if self.EnableLog then
        g_Logger.TraceChannel("属性计算器", "[计算%s][%s]最终值[%.2f]", logAttrType, logTag, ret)
    end

    valuesCache[cfgMap] = ret
    return ret
end

return AttrProvider_Wds