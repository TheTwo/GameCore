
---@class MapCreepLineLinkInfoPair
---@field from number
---@field to number
---@field refCount number
---@field handle CS.DragonReborn.AssetTool.PooledGameObjectHandle

---@class MapCreepLineLinkInfo
local MapCreepLineLinkInfo = sealedClass("MapCreepLineLinkInfo")

function MapCreepLineLinkInfo:ctor()
    ---@type table<number, table<number, MapCreepLineLinkInfoPair>>
    self._fromToMap = {}
    ---@type table<number, table<number, MapCreepLineLinkInfoPair>>
    self._toFromMap = {}
end

---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function MapCreepLineLinkInfo:CreateLink(from, to, refCount, handle)
    ---@type MapCreepLineLinkInfoPair
    local info = {}
    info.from = from
    info.to = to
    info.handle = handle
    info.refCount = refCount
    if refCount <= 0 then
        g_Logger.Error("link %s->%s refCount", from, to)
    end
    local set = table.getOrCreate(self._fromToMap, from)
    set[to] = info
    set = table.getOrCreate(self._toFromMap, to)
    set[from] = info
end

function MapCreepLineLinkInfo:AddLinkRef(from, to)
    local set = self._fromToMap[from]
    local info = set[to]
    info.refCount = info.refCount + 1
end

function MapCreepLineLinkInfo:RemoveLinkRef(from, to)
    local set = self._fromToMap[from]
    local info = set[to]
    info.refCount = info.refCount - 1
    if info.refCount <= 0 then
        set[to] = nil
        set = self._toFromMap[to]
        set[from] = nil
        info.handle:Delete()
        return true
    end
    return false
end

function MapCreepLineLinkInfo:TryRemove(fromOrTo)
    self:Remove(fromOrTo, self._fromToMap, self._toFromMap)
    self:Remove(fromOrTo, self._toFromMap, self._fromToMap)
end

function MapCreepLineLinkInfo:TryRemoveLinkRefByFrom(from)
    self:Remove(from, self._fromToMap, self._toFromMap)
end

function MapCreepLineLinkInfo:TryRemoveLinkRefByTo(to)
    self:Remove(to, self._toFromMap, self._fromToMap)
end

---@private
---@param fromToMap table<number, table<number, MapCreepLineLinkInfoPair>>
---@param toFromMap table<number, table<number, MapCreepLineLinkInfoPair>>
function MapCreepLineLinkInfo:Remove(id, fromToMap, toFromMap)
    local fromSet = fromToMap[id]
    if not fromSet then return end
    for to, info in pairs(fromSet) do
        info.refCount = info.refCount - 1
        if info.refCount <= 0 then
            fromSet[to] = nil
            local toSet = toFromMap[to]
            if toSet then
                toSet[id] = nil
            end
            info.handle:Delete()
        end
    end
end

function MapCreepLineLinkInfo:HasLink(from, to)
    local set = self._fromToMap[from]
    if not set then return false end
    return (set[to] ~= nil)
end

function MapCreepLineLinkInfo:CleanUp()
    table.clear(self._toFromMap)
    for _, set in pairs(self._fromToMap) do
        for _, value in pairs(set) do
            value.handle:Delete()
        end
    end
    table.clear(self._fromToMap)
end

return MapCreepLineLinkInfo