local CfgConst = require("CfgConst") 
local ConfigWrapFactory = {}
local this = ConfigWrapFactory;

function ConfigWrapFactory.CreateWrap(name)
    if not this.inited then
        this.InitConstMap();
        this.inited = true;
    end

    if this.IsConstCfg(name) then
        return require("ConstConfigWrap").new(name);
    end

    return require("ConfigWrap").new(name);
end

function ConfigWrapFactory.InitConstMap()
    this.constMap = {}
    if CfgConst then
        for _, v in ipairs(CfgConst) do
            this.constMap[v] = true;
        end
    end
end

function ConfigWrapFactory.IsConstCfg(name)
    return this.constMap[name];
end

return ConfigWrapFactory;