---@class RectDyadicMap
---@field new fun(maxX:number, maxY:number, metatable:table):RectDyadicMap
local RectDyadicMap = sealedClass("RectDyadicMap")
local assert = assert
local math = math
local next = next

function RectDyadicMap:ctor(maxX, maxY, metatable)
    self.map = setmetatable({}, metatable)
    self.metatable = metatable
    -- assert(maxX > 0, "rect sizeX cannot equal-less than 0")
    -- assert(maxY > 0, "rect sizeX cannot equal-less than 0")
    self.maxX = maxX -- float to integer
    self.maxY = maxY -- float to integer
    self.count = 0
end

function RectDyadicMap:Key(x, y)
    -- assert(x < self.maxX)
    -- assert(y < self.maxY)

    return self.maxX * y + x + 1
end

function RectDyadicMap:Clear()
    table.clear(self.map)
    self.count = 0
end

function RectDyadicMap:Get(x, y)
    return self.map[self.maxX * y + x + 1]
end

function RectDyadicMap:Contains(x, y)
    return self.map[self.maxX * y + x + 1] ~= nil
end

function RectDyadicMap:Update(x, y, value)
    local key = self.maxX * y + x + 1
    if not self.metatable and not rawget(self.map, key) then
        g_Logger.Error(("index of x:%d, y:%d doesn't exist"):format(x, y))
        return
    end
    self.map[key] = value
end

---@return boolean
function RectDyadicMap:TryAdd(x, y, value)
    local key = self.maxX * y + x + 1
    if not self.metatable and rawget(self.map, key) then
        return false
    end
    self.map[key] = value
    self.count = self.count + 1
    return true
end

---@generic T
---@param value T
---@return T
function RectDyadicMap:Add(x, y, value)
    local key = self.maxX * y + x + 1
    if not self.metatable and rawget(self.map, key) then
        g_Logger.Error(("index of x:%d, y:%d has existed, value is %s"):format(x, y, tostring(rawget(self.map, key))))
        return nil
    end
    self.map[key] = value
    self.count = self.count + 1
    return value
end

function RectDyadicMap:Delete(x, y)
    local key = self.maxX * y + x + 1
    if not rawget(self.map, key) then
        g_Logger.Error(("index of x:%d, y:%d doesn't exist"):format(x, y))
        return nil
    end
    local ret = self.map[key]
    self.map[key] = nil
    self.count = self.count - 1
    return ret
end

function RectDyadicMap:pairs()
    local key, value = nil, nil
    return function()
        key, value = next(self.map, key)
        if key or value then
            local realKey = key - 1
            local x, y = realKey % self.maxX, realKey // self.maxX
            return x, y, value
        end
    end
end

---@return number|nil, number|nil, any
function RectDyadicMap:First()
    local key, value = next(self.map, nil)
    if key or value then
        local realKey = key - 1
        local x, y = realKey % self.maxX, realKey // self.maxX
        return x, y, value
    end
    return nil
end

return RectDyadicMap