---
--- Created by wupei. DateTime: 2021/12/22
---

---@class MultiKeyMap
local MultiKeyMap = class("MultiKeyMap", nil, true)

---@protected
function MultiKeyMap:ctor(...)
    self._map = {}
end

function MultiKeyMap:GetSRC()
    return self._map
end

function MultiKeyMap:Set(key1, key2, value)
    if key1 == nil or key2 == nil then
        LogError("key1 == nil or key2 == nil. key1: %s, key2: %s", tostring(key1), tostring(key2))
        return
    end
    local subMap = self._map[key1]
    if subMap == nil then
        subMap = {}
        self._map[key1] = subMap
    end
    subMap[key2] = value
end

function MultiKeyMap:TrySet(key1, key2, value)
    if key1 == nil or key2 == nil then
        LogError("key1 == nil or key2 == nil. key1: %s, key2: %s", tostring(key1), tostring(key2))
        return
    end
    local subMap = self._map[key1]
    if subMap == nil then
        subMap = {}
        self._map[key1] = subMap
    end
    if subMap[key2] == nil then
        subMap[key2] = value
        return true
    end
    return false
end

function MultiKeyMap:Get(key1, key2)
    if key1 == nil or key2 == nil then
        return nil
    end
    local subMap = self._map[key1]
    if subMap == nil then
        return nil
    end
    return subMap[key2]
end

return MultiKeyMap
