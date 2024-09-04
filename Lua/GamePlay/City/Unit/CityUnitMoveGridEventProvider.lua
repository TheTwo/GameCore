
---@class CityUnitMoveGridEventProvider.UnitHandle
---@field refreshPos fun(self:CityUnitMoveGridEventProvider.UnitHandle,x:number, y:number, force:boolean)
---@field dispose fun(self:CityUnitMoveGridEventProvider.UnitHandle)
---@field unitType CityUnitMoveGridEventProvider.UnitType

---@class CityUnitMoveGridEventProvider.Listener
---@field xMin number
---@field yMin number
---@field xMax number
---@field yMax number
---@field count number
---@field unitTypeMask CityUnitMoveGridEventProvider.UnitTypeMask
---@field onEnter fun(x:number,y:number,listener:CityUnitMoveGridEventProvider.Listener)
---@field onExit fun(x:number,y:number,listener:CityUnitMoveGridEventProvider.Listener)

---@class CityUnitMoveGridEventProvider
---@field new fun():CityUnitMoveGridEventProvider
local CityUnitMoveGridEventProvider = class('CityUnitMoveGridEventProvider')

---@class CityUnitMoveGridEventProvider.UnitType
CityUnitMoveGridEventProvider.UnitType = {
    Citizen = 1,
    Explorer = 2,
    MyTroop = 3,
    TimelineSelfUnit = 4,
    EnemyTroop = 10, 
}

---@class CityUnitMoveGridEventProvider.UnitTypeMask
CityUnitMoveGridEventProvider.UnitTypeMask = {
    MyCityUnit = (1 << CityUnitMoveGridEventProvider.UnitType.Citizen) 
            | (1 << CityUnitMoveGridEventProvider.UnitType.Explorer) 
            | (1 << CityUnitMoveGridEventProvider.UnitType.MyTroop)
            | (1 << CityUnitMoveGridEventProvider.UnitType.TimelineSelfUnit)
}

function CityUnitMoveGridEventProvider:ctor()
    ---@type table<CityUnitMoveGridEventProvider.UnitHandle, table>
    self._trackingUnit = {}
    ---@type table<CityUnitMoveGridEventProvider.Listener, CityUnitMoveGridEventProvider.Listener>
    self._zoneListener = {}
end

function CityUnitMoveGridEventProvider:Init(width, height)
    self._width = width
    self._height = height
end

function CityUnitMoveGridEventProvider:Clear()
    table.clear(self._trackingUnit)
    table.clear(self._zoneListener)
end

---@param unitTypeMask CityUnitMoveGridEventProvider.UnitTypeMask
---@return CityUnitMoveGridEventProvider.Listener
function CityUnitMoveGridEventProvider:AddListener(x,y,sizeX,sizeY, onEnter, onExit, unitTypeMask)
    ---@type CityUnitMoveGridEventProvider.Listener
    local ret = {}
    ret.xMin = x
    ret.yMin = y
    ret.xMax = x + sizeX
    ret.yMax = y + sizeY
    ret.count = 0
    ret.onEnter = onEnter
    ret.onExit = onExit
    ret.unitTypeMask = unitTypeMask or (~0)
    self._zoneListener[ret] = ret
    return ret
end

---@param listener CityUnitMoveGridEventProvider.Listener
function CityUnitMoveGridEventProvider:RemoveListener(listener)
    self._zoneListener[listener] = nil
end

---@param x number
---@param y number
---@param unitType CityUnitMoveGridEventProvider.UnitType
---@param noEnterCheck boolean
---@return CityUnitMoveGridEventProvider.UnitHandle
function CityUnitMoveGridEventProvider:AddUnit(x, y, unitType, noEnterCheck)
    ---@type CityUnitMoveGridEventProvider.UnitHandle
    local ret = {}
    ret.unitType = unitType
    self._trackingUnit[ret] = {x, y}
    local provider = self
    ret.refreshPos = function(handle, posX, posY, force)
        provider:NotifyCheckUnit(handle, posX, posY, force)
    end
    ret.dispose = function(handle)
        provider:RemoveUnit(handle)
    end
    if not noEnterCheck then
        self:CheckEnterTrigger(x, y, unitType)
    end
    return ret
end

---@param handle CityUnitMoveGridEventProvider.UnitHandle
function CityUnitMoveGridEventProvider:RemoveUnit(handle)
    local pos = self._trackingUnit[handle]
    if not pos then
        return
    end
    self._trackingUnit[handle] = nil
    self:CheckExitTrigger(pos[1], pos[2], handle.unitType)
end

---@param handle CityUnitMoveGridEventProvider.UnitHandle
---@param x number
---@param y number
---@param force boolean|nil
function CityUnitMoveGridEventProvider:NotifyCheckUnit(handle, x, y, force)
    local pos = self._trackingUnit[handle]
    if not pos then
        return
    end
    x = math.floor(x)
    y = math.floor(y)
    if pos[1] == x and pos[2] == y and not force then
        return
    end
    self:CheckExitTrigger(pos[1], pos[2], handle.unitType)
    pos[1] = x
    pos[2] = y
    self:CheckEnterTrigger(pos[1], pos[2], handle.unitType)
end

function CityUnitMoveGridEventProvider:CheckExitTrigger(x, y, unitType)
    local unitTypeFlag = 1 << unitType
    for _, listener in pairs(self._zoneListener) do
        if (listener.unitTypeMask & unitTypeFlag) ~= 0 then
            if listener.xMin <= x and listener.yMin <= y and listener.xMax > x and listener.yMax > y then
                listener.count = listener.count - 1
                listener.onExit(x, y, listener)
            end
        end
    end
end

function CityUnitMoveGridEventProvider:CheckEnterTrigger(x, y, unitType)
    local unitTypeFlag = 1 << unitType
    for _, listener in pairs(self._zoneListener) do
        if (listener.unitTypeMask & unitTypeFlag) ~= 0 then
            if listener.xMin <= x and listener.yMin <= y and listener.xMax > x and listener.yMax > y then
                listener.count = listener.count + 1
                listener.onEnter(x, y, listener)
            end
        end
    end
end

---@param city City
function CityUnitMoveGridEventProvider:DebugDrawGrid(city)
    local color = CS.UnityEngine.Color.red
    for _, listener in pairs(self._zoneListener) do
        for x = listener.xMin, listener.xMax - 1 do
            for y = listener.yMin, listener.yMax - 1 do
                city:DebugDrawGrid(x, y, color)
            end
        end
    end
    color = CS.UnityEngine.Color.yellow
    for _, pos in pairs(self._trackingUnit) do
        city:DebugDrawGrid(pos[1], pos[2], color)
    end
end

return CityUnitMoveGridEventProvider