local SdkCrashlytics = require("SdkCrashlytics")
local BaseManager = require("BaseManager")
local EventConst = require("EventConst")

---@class EventManager
---@field new fun():EventManager
local EventManager = class('EventManager', BaseManager);

function EventManager:ctor()
    self.allEventListeners = {};
    self.frontCache = {};
    self.backCache = {};
    self.processing = false;
    self.postAddList = {}
    self.postDeleteList = {}
end

local function LogExceptionOrError(result)
    if not SdkCrashlytics.LogCSException(result) then
        SdkCrashlytics.LogLuaErrorAsException(result)
    end
end

function EventManager:ListenerCount(evtName)
    return self.allEventListeners[evtName] and #self.allEventListeners[evtName] or 0
end

---@return boolean, number @boolean:是否被立刻执行了;number:当前监听者数量
function EventManager:TriggerEvent(evt, ...)
    table.insert(not self.processing and self.frontCache or self.backCache , {evt, ...});
    if self.processing then return false, self:ListenerCount(evt) end

    self.processing = true;
    while #self.frontCache > 0 do
        local toList = self.frontCache;
        for _, v in ipairs(toList) do
            self:DispatchEventMsg(v)
            self:PostAddListener()
            self:PostRemoveListener()
        end
        self.frontCache, self.backCache = self.backCache, self.frontCache;
        table.clear(self.backCache);
    end

    self.processing = false;
    return true, self:ListenerCount(evt)
end

function EventManager:DispatchEventMsg(pack)
    local name = pack[1]
    local listeners = self.allEventListeners[name]
    if listeners then
        for _, v in pairs(listeners) do
            if not self:IsWaitingRemoving(name, v) then
                try_catch_traceback_with_vararg(v, nil, table.unpack(pack, 2))
            end
        end
    end
end

function EventManager:AddListener(name, listener)
    local listeners = self.allEventListeners[name]
    if (listeners == nil) then
        listeners = {}
        self.allEventListeners[name] = listeners
    end
    if self.processing then
        if self:PostDeleteMerge(name, listener) then
            return
        end
        if table.indexof(listeners, listener) < 0 then
            table.insert(self.postAddList, {name, listener})
        end
        return
    end
    self:AddListenerImp(name, listener)
end

---@private
function EventManager:AddListenerImp(name, listener)
    local listeners = self.allEventListeners[name]
    if table.indexof(listeners, listener) < 0 then
        table.insert(listeners, listener)
    end
end

function EventManager:RemoveListener(name, listener)
    local listeners = self.allEventListeners[name];
    if (listeners ~= nil) then
        if self.processing then
            if self:PostAddMerge(name, listener) then
                return
            end
            if table.indexof(listeners, listener) > 0 then
                table.insert(self.postDeleteList, {name, listener})
            end
            return
        end
        self:RemoveListenerImp(name, listener)
    end
end

---@private
function EventManager:RemoveListenerImp(name, listener)
    local listeners = self.allEventListeners[name];
    table.removebyvalue(listeners, listener, true);
end

function EventManager:IsWaitingRemoving(name, listener)
    if not self.postDeleteList then return false end

    for _, v in ipairs(self.postDeleteList) do
        if v[1] == name and v[2] == listener then
            return true
        end
    end
    return false
end

---@private
function EventManager:PostDeleteMerge(name, listener)
    for i, v in ipairs(self.postDeleteList) do
        if v[1] == name and v[2] == listener then
            table.remove(self.postDeleteList, i)
            return true
        end
    end
    return false
end

---@private
function EventManager:PostAddMerge(name, listener)
    for i, v in ipairs(self.postAddList) do
        if v[1] == name and v[2] == listener then
            table.remove(self.postAddList, i)
            return true
        end
    end
    return false
end

---@private
function EventManager:PostAddListener()
    while #self.postAddList > 0 do
        local v = table.remove(self.postAddList, 1)
        self:AddListenerImp(v[1], v[2])
    end
end

---@private
function EventManager:PostRemoveListener()
    while #self.postDeleteList > 0 do
        local v = table.remove(self.postDeleteList, 1)
        self:RemoveListenerImp(v[1], v[2])
    end
end

function EventManager:Release()
    self.allEventListeners = {};
    self.frontCache = {};
    self.backCache = {};
    self.processing = false;
end

function EventManager:Reset()
    self:Release()
end

function EventManager:OnLowMemory()
    self:TriggerEvent(EventConst.ON_LOW_MEMORY)
end

return EventManager

