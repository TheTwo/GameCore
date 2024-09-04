---@class Blackboard
---@field new fun():Blackboard
local Blackboard = sealedClass("Blackboard")

function Blackboard:ctor()
    self.pair = {}
end

function Blackboard:Write(key, value, force)
    if key == nil then
        g_Logger.Error("key cant be nil");
        return false
    end

    if self.pair[key] ~= nil and not force then
        g_Logger.Error(string.format("the key %s is duplicated in blackboard", tostring(key)));
        return false
    end

    self.pair[key] = value
    return true
end

function Blackboard:Read(key, clear)
    if key == nil then
        g_Logger.Error("key cant be nil");
        return;
    end

    local ret = self.pair[key];
    if ret ~= nil and clear then
        self.pair[key] = nil;
    end
    return ret;
end

function Blackboard:Clear()
    self.pair = {}
end

return Blackboard