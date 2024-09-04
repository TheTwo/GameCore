local AttrProviderBase = require("AttrProviderBase")
local ModuleRefer = require("ModuleRefer")
---@class AttrProvider_Cfg:AttrProviderBase
---@field new fun():AttrProvider_Cfg
local AttrProvider_Cfg = class("AttrProvider_Cfg", AttrProviderBase)

---@param attrGroupCfg AttrGroupConfigCell
function AttrProvider_Cfg:ctor(attrGroupCfg)
    self.attrGroupCfg = attrGroupCfg
end

function AttrProvider_Cfg:Calculate(baseCfgMap, multiCfgMap, pointCfgMap, logAttrType)
    local baseValue = self:CalculateBase(baseCfgMap, logAttrType)
    local multiValue = self:CalculateMulti(multiCfgMap, logAttrType)
    local pointValue = self:CalculatePoint(pointCfgMap, logAttrType)

    return baseValue, multiValue, pointValue
end

function AttrProvider_Cfg:CalculateBase(baseCfgMap, logAttrType)
    return self:CalculateImp(baseCfgMap, self.attrGroupCfg, "Base", logAttrType)
end

function AttrProvider_Cfg:CalculateMulti(multiCfgMap, logAttrType)
    return self:CalculateImp(multiCfgMap, self.attrGroupCfg, "Multi", logAttrType)
end

function AttrProvider_Cfg:CalculatePoint(pointCfgMap, logAttrType)
    return self:CalculateImp(pointCfgMap, self.attrGroupCfg, "Point", logAttrType)
end

---@param cfgMap table<number, AttrElementConfigCell>
---@param attrGroupCfg AttrGroupConfigCell
function AttrProvider_Cfg:CalculateImp(cfgMap, attrGroupCfg, logTag, logAttrType)
    if cfgMap == nil then return 0 end

    local ret = 0
    for i = 1, attrGroupCfg:AttrListLength() do
        local listInst = attrGroupCfg:AttrList(i)
        local id = listInst:TypeId()
        if cfgMap[id] then
            local cfg = cfgMap[id]
            local value = listInst:Value()
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
    return ret
end

return AttrProvider_Cfg