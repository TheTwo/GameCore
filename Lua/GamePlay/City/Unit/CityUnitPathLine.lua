---@type CS.UnityEngine.Quaternion
local Quaternion = CS.UnityEngine.Quaternion
---@type CS.UnityEngine.Vector3
local Vector3 = CS.UnityEngine.Vector3
---@type CS.UnityEngine.MaterialPropertyBlock
local MaterialPropertyBlock = CS.UnityEngine.MaterialPropertyBlock
---@type CS.UnityEngine.Shader
local Shader = CS.UnityEngine.Shader

local Delegate = require("Delegate")
local Utils = require("Utils")
local NativeArrayVector3 = CS.Unity.Collections.NativeArray(CS.UnityEngine.Vector3)
local ColorPropertyIndex = Shader.PropertyToID("_BaseColor")

---@class CityUnitPathLine
---@field new fun(trans:CS.UnityEngine.Transform):CityUnitPathLine
local CityUnitPathLine = class('CityUnitPathLine')
---@type CityUnitPathLine[]
CityUnitPathLine._pool = {}
---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
CityUnitPathLine._goCreator = nil

function CityUnitPathLine.InitPoolRootOnce()
    if Utils.IsNotNull(CityUnitPathLine._goCreator) then
        return
    end
    CityUnitPathLine._goCreator = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create("CityUnitPathLinePool")
end

---@param trans CS.UnityEngine.Transform
---@return CityUnitPathLine
function CityUnitPathLine.GetOrCreate(trans, prefab)
    return CityUnitPathLine.new(trans, prefab)
end

---@param line CityUnitPathLine
function CityUnitPathLine.Delete(line)
    if Utils.IsNotNull(line._resHandle) then
        line._resHandle:Delete()
        return
    end
    line:Clear()
end

function CityUnitPathLine:ctor(trans, prefab)
    self._assetReady = false
    self._go = nil
    ---@type CS.UnityEngine.LineRenderer
    self._lineRenderer = nil
    self._wayPoints = nil
    CityUnitPathLine.InitPoolRootOnce()
    self._resHandle = CityUnitPathLine._goCreator:Create(prefab, trans, Delegate.GetOrCreate(self, self.OnAssetReady))
    ---@type CS.UnityEngine.MaterialPropertyBlock
    self._propertyBlock = MaterialPropertyBlock()
    ---@type CS.UnityEngine.Color
    self._color = nil
end

function CityUnitPathLine:Clear()
    self._assetReady = false
    self._go = nil
    self._lineRenderer = nil
    self._wayPoints = nil
    self._resHandle = nil
    self._color = nil
end

---@param go CS.UnityEngine.GameObject
---@param _ any
function CityUnitPathLine:OnAssetReady(go, _)
    if Utils.IsNull(go) then
        return
    end
    self._go = go
    self._go.transform:SetPositionAndRotation(Vector3.zero, Quaternion.Euler(90, 0, 0))
    self._lineRenderer = go:GetComponent(typeof(CS.UnityEngine.LineRenderer))
    if self._wayPoints then
        self:SetLineRendererData(self._wayPoints)
        self._wayPoints = nil
    end
    self:DoSetLineColor()
    self._assetReady = true
end

---@param wayPoints CS.UnityEngine.Vector3[]
---@param currentPoint CS.UnityEngine.Vector3
function CityUnitPathLine:InitWayPoints(wayPoints, currentPoint)
    local c = #wayPoints
    local rTable = {}
    for index = c, 1, -1 do
        local v = wayPoints[index]
        table.insert(rTable, Vector3(v.x, v.y, v.z))
    end
    if not currentPoint then
        currentPoint = rTable[#rTable]
    end
    table.insert(rTable, currentPoint)
    if not self._assetReady then
        self._wayPoints = rTable
        return
    end
    self:SetLineRendererData(rTable)
end

function CityUnitPathLine:SetLineRendererData(t)
    local c = #t
    local array = NativeArrayVector3(c, CS.Unity.Collections.Allocator.Temp)
    for i, v in ipairs(t) do
        array[i - 1] = v
    end
    self._lineRenderer.positionCount = c
    self._lineRenderer:SetPositions(array)
    array:Dispose()
end

---@param point CS.UnityEngine.Vector3
function CityUnitPathLine:UpdateCurrentPoint(point)
    if not self._assetReady then
        if #self._wayPoints <= 0 then
            return
        end
        self._wayPoints[#self._wayPoints] = point
        return
    end
    if self._lineRenderer.positionCount <= 0 then
        return
    end
    self._lineRenderer:SetPosition(self._lineRenderer.positionCount - 1, point)
end

function CityUnitPathLine:SetWayPointsLength(length)
    if length < 0 then
        length = 0
    end
    if not self._assetReady then
        local c = #self._wayPoints
        while length < c do
            table.remove(self._wayPoints)
            c = c - 1
        end
        return
    end
    if length >= self._lineRenderer.positionCount then
        return
    end
    self._lineRenderer.positionCount = length
end

function CityUnitPathLine:WayPointsCount()
    if not self._assetReady then
        return #self._wayPoints
    end
    return self._lineRenderer.positionCount
end

---@param color CS.UnityEngine.Color
function CityUnitPathLine:SetLineColor(color)
    self._color = color
    self:DoSetLineColor()
end

function CityUnitPathLine:DoSetLineColor()
    if Utils.IsNull(self._lineRenderer) or not self._color then return end
    self._propertyBlock:Clear()
    self._lineRenderer:GetPropertyBlock(self._propertyBlock)
    self._propertyBlock:SetColor(ColorPropertyIndex, self._color)
    self._lineRenderer:SetPropertyBlock(self._propertyBlock)
end

function CityUnitPathLine:UpdatePoints(p0, p1)
    if self._wayPoints then
        table.clear(self._wayPoints)
    else
        self._wayPoints = {}
    end
    self._wayPoints[1] = p1
    self._wayPoints[2] = p0
    if self._assetReady then
        self:SetLineRendererData(self._wayPoints)
    end
end

---@param moveAgent UnitMoveAgent
function CityUnitPathLine:UpdateByMoveAgent(moveAgent)
    if not moveAgent.Dirty then return end

    local linePoints = self:WayPointsCount() - 1
    local wayPointsCount = #moveAgent._waypoints
    if linePoints > 0 and wayPointsCount > 0 then
        local runningIndex = wayPointsCount - moveAgent._currentWayPoint + 1
        if runningIndex == linePoints then
            self:UpdateCurrentPoint(moveAgent._currentPosition)
        elseif runningIndex < linePoints then
            self:SetWayPointsLength(runningIndex + 1)
        end
    end
end

return CityUnitPathLine