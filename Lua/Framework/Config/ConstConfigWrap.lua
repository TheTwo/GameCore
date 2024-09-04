local flatbuffers = require("flatbuffers")
local ConfigUtils = require("ConfigUtils");
local ConstConfigWrap = {};

function ConstConfigWrap.new(name)
    local ret = {};
    ret.name = name;
    local bytes = ConfigUtils.LoadConfigBinary(name);
    if bytes == nil then return ret end

    local fb = require(name);
    local buf = flatbuffers.binaryArray.New(bytes);
    local fbInstance = fb["GetRootAs"..name](buf, 0);
    setmetatable(ret, {__index = fbInstance, __newindex = function() error("常量表无法被赋值") end});
    return ret;
end
    
return ConstConfigWrap