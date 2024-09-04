local require = require
local setmetatable = setmetatable
local assert = assert
local rawset = rawset
local rawget = rawget
local pairs = pairs
local type = type
classCache = setmetatable({}, {__mode = "kv"})

local function is(t, cls)
    local tCls = GetClassOf(t)
    repeat
        if tCls == cls then
            return true
        end
        tCls = tCls.super
    until tCls == nil
    return false
end

function sealedClass(classname)
    local cls = {__cname = classname, __isClass = true, __isLightClass = true, __isSealed = true}
    cls.__index = cls
    cls.__class = cls
    cls.new = function(...)
        local inst = setmetatable({}, {__index = cls, __tostring = cls.ToString})
        inst.__isInstance = true --for lua memory profiler
        if inst.ctor then
            inst:ctor(...)
        end
        return inst
    end
    cls.is = is
    classCache[cls] = classname
    return cls
end

function class(className, superCls)
    if superCls then
        assert(superCls.__isLightClass, "lightClass只能继承自lightClass")
        assert(not superCls.__isSealed, "sealedClass无法继承")
    end

    local cls = {__cname = className, __isClass = true, __isLightClass = true}
    cls.__index = cls
    cls.__class = cls
    cls.super = superCls
    if superCls then
        setmetatable(cls, {__index = superCls})
    end

    cls.new = function(...)
        local inst = setmetatable({}, {__index = cls, __tostring = cls.ToString})
        inst.__isInstance = true --for lua memory profiler
        if inst.ctor then
            inst:ctor(...)
        end
        return inst
    end
    cls.is = is
    classCache[cls] = className
    return cls
end

local function replace_register(srcFuncs, reloadFuncs)
    local registry = debug.getregistry()
    local changeList = {};
    for name, value in pairs(srcFuncs) do
        for k, v in pairs(registry) do
            if v == value then
                if reloadFuncs[name] == nil then
                    error("Reload class failed ")
                end
                changeList[k] = reloadFuncs[name];
                break;
            end
        end
    end

    for k, v in pairs(changeList) do
        registry[k] = v;
    end
end

local function ReloadClassImp(source, reload)
    rawset(source, "super", rawget(reload, "super"))
    local sourceFunc, reloadFunc = {}, {}
    for k, v in pairs(source) do
        if type(v) == "function" then
            sourceFunc[k] = v
        end
    end

    for k, v in pairs(reload) do
        if type(v) == "function" then
            reloadFunc[k] = v
        end
    end

    replace_register(sourceFunc, reloadFunc)
    for k, v in pairs(sourceFunc) do
        if not reloadFunc[k] then
            rawset(source, k, nil)
        end
    end

    for k, v in pairs(reloadFunc) do
        rawset(source, k, v)
    end
end

function ReloadLightClass(name)
    local oldCls = package.loaded[name]
    if oldCls == nil then return end

    package.loaded[name] = nil
    local newCls = require(name)
    ReloadClassImp(oldCls, newCls)
    package.loaded[name] = oldCls
end

function GetClassOf(instance)
    return instance.__class;
end

function GetClassName(instance)
    return GetClassOf(instance).__cname;
end

function IsDerivedFrom(cls, superCls)
    if cls == nil or cls.super == nil then
        return false;
    end

    if superCls == nil then
        return false;
    end

    if cls.super == superCls then
        return true;
    end

    return IsDerivedFrom(cls.super, superCls);
end