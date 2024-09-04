local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local CityInteractionPointType = require("CityInteractionPointType")
local CityGridLayerMask = require("CityGridLayerMask")
local CityWorkTargetType = require("CityWorkTargetType")

local CityManagerBase = require("CityManagerBase")

---@class CityInteractPoint_Impl
---@field index number
---@field mask number
---@field pointType number @CityInteractionPointType
---@private
---@field worldPos CS.UnityEngine.Vector3
---@field worldRotation CS.UnityEngine.Vector3
---@field gridX number
---@field gridY number
---@field gridKey number
---@field ownerInfo CityCitizenTargetInfo
---@field gridPosX number
---@field gridPosY number
---@field parentY number
---@field GetWorldPos fun(self:CityInteractPoint_Impl):CS.UnityEngine.Vector3

---@class CityInteractPointManager:CityManagerBase
---@field new fun():CityInteractPointManager
---@field super CityManagerBase
local CityInteractPointManager = class('CityInteractPointManager', CityManagerBase)

function CityInteractPointManager:ctor(city, ...)
    CityInteractPointManager.super.ctor(self, city, ...) 
    self._index = 1
    self._freePointCount = 0
    ---@type table<number, CityInteractPoint_Impl>
    self._index2Point = {}
    ---@type table<number, table<number, CityInteractPoint_Impl[]>>
    self._freePoints = {}
    ---@type table<CityInteractPoint_Impl, CityInteractPoint_Impl>
    self._inUsingPoint = {}
    ---@type table<number, {x:number,y:number,points:CityInteractPoint_Impl[]}>
    self._mapPoint = {}
    ---@type table<number, table<CityInteractPoint_Impl, CityInteractPoint_Impl>>
    self._currentMapPoint = {}
    ---@type table<number, CS.UnityEngine.GameObject>
    self._debugGo = {}
    self._debugPoint = false
    if UNITY_EDITOR then
        self._debugPoint = (g_Game.PlayerPrefsEx:GetInt("CityInteractPointManager_DEBUG", 0) > 0)
    end
    ---@type table<number, boolean>
    self._noInteractPointElementId = {}
end

function CityInteractPointManager:NeedLoadData()
    return true
end

function CityInteractPointManager:DoDataLoad()
    local city = self.city
    local gridConfig = city.gridConfig
    local maxX = gridConfig.cellsX
    local cityInteractionPoint = ConfigRefer.CityInteractionPoint
    for _, v in ConfigRefer.CityMapInteractionPoint:pairs() do
        local pos = v:Pos()
        local posX = pos:X()
        local posY = pos:Y()
        for i = 1, v:RefInteractPosLength() do
            local relPos = v:RefInteractPos(i)
            local pointConfig = cityInteractionPoint:Find(relPos)
            local point = CityInteractPointManager.MakePoint(city, pointConfig, maxX, posX, posY, 0)
            local key = point.gridKey
            ---@type {x:number,y:number,points:CityInteractPoint_Impl[]}
            local t = self._mapPoint[key]
            if not t then
                t = {}
                t.x = point.gridX
                t.y = point.gridY
                t.points = {}
                self._mapPoint[key] = t
            end
            table.insert(t.points, point)
        end
    end
    for i, v in pairs(self._mapPoint) do
        if city.gridLayer:IsEmpty(v.x, v.y) then
            for _, point in ipairs(v.points) do
                self:DoAddInteractPoint(point)
                local l = table.getOrCreate(self._currentMapPoint, point.gridKey)
                l[point] = point
            end
        end
    end
    
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_LAYER_UPDATE, Delegate.GetOrCreate(self, self.OnGridLayerUpdate))
    
    return self:DataLoadFinish()
end

function CityInteractPointManager:DoDataUnload()
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_LAYER_UPDATE, Delegate.GetOrCreate(self, self.OnGridLayerUpdate))
    for _, v in pairs(self._currentMapPoint) do
        for _, point in pairs(v) do
            self:RemoveInteractPoint(point.index)
        end
    end
    table.clear(self._currentMapPoint)
    table.clear(self._mapPoint)
    for _, value in pairs(self._debugGo) do
        CS.UnityEngine.Object.Destroy(value)
    end
    table.clear(self._debugGo)
    table.clear(self._noInteractPointElementId)
end

---@param city City
---@param pointConfig CityInteractionPointConfigCell
---@param maxX number
---@param posX number
---@param posY number
---@param rotation number @0,90.180,270
---@param worldPos CS.UnityEngine.Vector3
---@param ownerInfo CityCitizenTargetInfo
---@return CityInteractPoint_Impl
function CityInteractPointManager.MakePoint(city, pointConfig, maxX, posX, posY, rotation, worldPos, ownerInfo ,sx, sy)
    local relPosX = pointConfig:RelativePosX()
    local relPosY = pointConfig:RelativePosY()
    sx = sx or 1
    sy = sy or 1
    local gridPosX
    local gridPosY
    local dirX,dirY,dirZ = pointConfig:DirX(),pointConfig:DirY(),pointConfig:DirZ()
    local worldRotation = CS.UnityEngine.Vector3(dirX, dirY, dirZ).normalized
    local quaternion
    if rotation == 90 then
        gridPosX = posX + relPosY
        gridPosY = posY + sy - relPosX
        quaternion = CS.UnityEngine.Quaternion.Euler(0,90,0)
    elseif rotation == 180 then
        gridPosX = posX + sx - relPosX
        gridPosY = posY + sy - relPosY
        quaternion = CS.UnityEngine.Quaternion.Euler(0,180,0)
    elseif rotation == 270 then
        gridPosX = posX + sx - relPosY
        gridPosY = posY + relPosX
        quaternion = CS.UnityEngine.Quaternion.Euler(0,270,0)
    else
        gridPosX = posX + relPosX
        gridPosY = posY + relPosY
        quaternion = CS.UnityEngine.Quaternion.identity
    end
    worldRotation = quaternion * worldRotation
    ---@type CityInteractPoint_Impl
    local point = {}
    point.gridX = math.floor(gridPosX)
    point.gridY = math.floor(gridPosY)
    point.gridKey = maxX * point.gridY + point.gridX + 1
    point.mask = 1 << 0
    point.ownerInfo = ownerInfo
    for i = 1, pointConfig:TagsLength() do
        local tag = pointConfig:Tags(i)
        point.mask = point.mask | (1 << tag)
    end
    point.pointType = pointConfig:Type()
    point.gridPosX = gridPosX
    point.gridPosY = gridPosY
    point.GetWorldPos = Delegate.GetOrCreate(city, city.CityInteractPointGetPos)
    point.parentY = worldPos and worldPos.y
    point.worldRotation = worldRotation
    point.cfgId = pointConfig:Id()
    return point
end

---@param pointConfig CityInteractionPointConfigCell
---@param posX number
---@param posY number
---@param worldRotation number
---@param worldPos CS.UnityEngine.Vector3
---@param ownerInfo CityCitizenTargetInfo
---@return number @index
function CityInteractPointManager:AddInteractPoint(pointConfig, posX, posY, worldRotation, worldPos, ownerInfo, sx, sy)
    ---@type CityInteractPoint_Impl
    local point = CityInteractPointManager.MakePoint(self.city, pointConfig, self.city.gridConfig.cellsX, posX, posY, worldRotation, worldPos, ownerInfo, sx, sy)
    return self:DoAddInteractPoint(point)
end

---@param point CityInteractPoint_Impl
---@return number @index
function CityInteractPointManager:DoAddInteractPoint(point)
    point.index = self._index
    self._index2Point[point.index] = point
    self._index = self._index + 1
    local mask2List = table.getOrCreate(self._freePoints, point.pointType)
    if not mask2List then
        mask2List = {}
        self._freePoints[point.pointType] = mask2List
    end
    local list = table.getOrCreate(mask2List, point.mask)
    table.insert(list, point)
    self._freePointCount = self._freePointCount + 1
    self:DoDebugGo(true, point)
    return point.index
end

function CityInteractPointManager:RemoveInteractPoint(index)
    local point = self._index2Point[index]
    if not point then
        return
    end
    self._index2Point[index] = nil
    local points = self._freePoints[point.pointType][point.mask]
    if points then
        table.removebyvalue(points, point)
    end
    if self._inUsingPoint[point] then
        self._inUsingPoint[point] = nil
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_IN_USING_POINT_REMOVED, point)
    end
    self:DoDebugGo(false, point)
end

---@param pointType number @CityInteractionPointType
---@param tagMask number
---@param pos CS.UnityEngine.Vector3
---@return CityInteractPoint_Impl|nil
function CityInteractPointManager:AcquireInteractNearestPoint(pointType, tagMask, pos)
    if self._freePointCount <= 0 then
        return nil
    end
    local mask2List = self._freePoints[pointType]
    if not mask2List then
        return nil
    end
    local zoneMgr = self.city.zoneManager
    ---@type CityInteractPoint_Impl[]
    local tmpList = {}
    for listTag, list in pairs(mask2List) do
        if (listTag & tagMask) ~= 0 then
            for _, value in ipairs(list) do
                if pointType == CityInteractionPointType.Generic then
                    local zone = zoneMgr:GetZone(value.gridX, value.gridY)
                    if zone and zone:IsHideFog() then
                        tmpList[#tmpList] = value
                    end
                else -- 工作类型的交互目标都是服务器给定的 不需要检查是不是在迷雾里了
                    tmpList[#tmpList] = value
                end
            end
        end
    end
    if #tmpList > 0 then
        local choosePoint = tmpList[1]
        local dis = (pos - choosePoint:GetWorldPos()).sqrMagnitude
        for i = 2, #tmpList do
            local compare = tmpList[i]
            local compareDis = (pos - compare:GetWorldPos()).sqrMagnitude
            if compareDis <= dis then
                choosePoint = compare
                dis = compareDis
            end
        end
        table.removebyvalue(mask2List[choosePoint.mask], choosePoint)
        self._freePointCount = self._freePointCount - 1
        self._inUsingPoint[choosePoint] = choosePoint
        self:DoDebugGoUse(true, choosePoint)
        return choosePoint
    end
    return nil
end

---@param requireOwnerInfo CityCitizenTargetInfo|nil
---@param point CityInteractPoint_Impl
---@return boolean
function CityInteractPointManager.MatchOwnerInfo(requireOwnerInfo, point)
    if not requireOwnerInfo then return true end
    if not point.ownerInfo then return false end
    return requireOwnerInfo.id == point.ownerInfo.id and requireOwnerInfo.type == point.ownerInfo.type
end

---@param pointType number @CityInteractionPointType
---@param tagMask number
---@param ownerInfo CityCitizenTargetInfo
---@return CityInteractPoint_Impl|nil
function CityInteractPointManager:AcquireInteractPoint(pointType, tagMask, ownerInfo)
    if self._freePointCount <= 0 then
        return nil
    end
    local mask2List = self._freePoints[pointType]
    if not mask2List then
        return nil
    end
    local tmpList = {}
    local zoneMgr = self.city.zoneManager
    for listTag, list in pairs(mask2List) do
        if (listTag & tagMask) ~= 0  and #list > 0 then
            for _, value in ipairs(list) do
                if pointType == CityInteractionPointType.Generic then
                    local zone = zoneMgr:GetZone(value.gridX, value.gridY)
                    if zone and zone:IsHideFog() then
                        if CityInteractPointManager.MatchOwnerInfo(ownerInfo, value) then
                            tmpList[#tmpList + 1] = value
                        end
                    end
                else -- 工作类型的交互目标都是服务器给定的 不需要检查是不是在迷雾里了
                    if CityInteractPointManager.MatchOwnerInfo(ownerInfo, value) then
                        tmpList[#tmpList + 1] = value
                    end
                end
            end
            if #tmpList > 0 then
                local index = math.random(1, #tmpList)
                local point = table.remove(tmpList, index)
                table.removebyvalue(list, point)
                self._freePointCount = self._freePointCount - 1
                self._inUsingPoint[point] = point
                self:DoDebugGoUse(true, point)
                return point
            end
        end
    end
    return nil
end

---@param point CityInteractPoint_Impl
function CityInteractPointManager:DismissInteractPoint(point)
    if not self._inUsingPoint[point] then
        return
    end
    local list = self._freePoints[point.pointType][point.mask]
    table.insert(list, point)
    self._freePointCount = self._freePointCount + 1
    self._inUsingPoint[point] = nil
    self:DoDebugGoUse(false, point)
end

function CityInteractPointManager:ProcessMapPointCover(maxX, x, y)
    local key = maxX * x + y + 1
    local l = self._currentMapPoint[key]
    if l then
        for _, point in pairs(l) do
            self:RemoveInteractPoint(point.index)
        end
        self._currentMapPoint[key] = nil
    end
end

function CityInteractPointManager:ProcessMapPointCoverCheckFurniture(maxX, x, y, furnitureId)
    local key = maxX * x + y + 1
    local l = self._currentMapPoint[key]
    if l then
        local count = 0
        local removeCount = 0
        for _, point in pairs(l) do
            count = count + 1
            if not point.ownerInfo or point.ownerInfo.id ~= furnitureId or point.ownerInfo.type ~= CityWorkTargetType.Furniture then
                removeCount = removeCount + 1
                self:RemoveInteractPoint(point.index)
            end
        end
        if count == removeCount then
            self._currentMapPoint[key] = nil
        end
    end
end

function CityInteractPointManager:ProcessMapPointUnCover(maxX, x, y)
    local key = maxX * x + y + 1
    local mapPoint = self._mapPoint[key]
    if mapPoint then
        local l = table.getOrCreate(self._currentMapPoint, key)
        for _, point in pairs(mapPoint.points) do
            if not l[point] then
                self:DoAddInteractPoint(point)
                l[point] = point
            end
        end
    end
end

function CityInteractPointManager:OnGridLayerUpdate(city, x, y, sizeX, sizeY)
    if city ~= self.city then
        return
    end
    local maxX = self.city.gridConfig.cellsX
    for i = x, x + sizeX - 1 do
        for j = y, y + sizeY - 1 do
            local mask = self.city.gridLayer:Get(i, j)
            if mask and CityGridLayerMask.IsPlaced(mask) then
                if CityGridLayerMask.HasFurniture(mask) then
                    local furniture = self.city.furnitureManager:GetPlaced(i, j)
                    if furniture then
                        self:ProcessMapPointCoverCheckFurniture(maxX, i, j, furniture:UniqueId())
                        goto continue
                    end
                end
                self:ProcessMapPointCover(maxX, i, j)
            else
                self:ProcessMapPointUnCover(maxX, i, j)
            end
            ::continue::
        end
    end
end

---@param point CityInteractPoint_Impl
function CityInteractPointManager:DoDebugGo(add, point)
    if not UNITY_EDITOR then return end
    if not self._debugPoint then return end
    if add then
        local go = CS.UnityEngine.GameObject.CreatePrimitive(CS.UnityEngine.PrimitiveType.Sphere)
        local to = CS.UnityEngine.GameObject.CreatePrimitive(CS.UnityEngine.PrimitiveType.Cube)
        to.transform.parent = go.transform
        to.transform.localScale = CS.UnityEngine.Vector3(0.2, 0.2, 1)
        to.transform.localPosition = CS.UnityEngine.Vector3(0,0, 0.5)
        self._debugGo[point.index] = go
        go.transform.localScale = CS.UnityEngine.Vector3.one * self.city.scale * 0.5
        go.transform:SetPositionAndRotation(point:GetWorldPos(), CS.UnityEngine.Quaternion.LookRotation(point.worldRotation))
        go.name = ("交互点:%s type:%s, mask:%s, 属于：%s t:%s"):format(point.index, point.pointType, point.mask, point.ownerInfo and point.ownerInfo.id, point.ownerInfo and point.ownerInfo.type)
    else
        local go = self._debugGo[point.index]
        self._debugGo[point.index] = nil
        if require("Utils").IsNotNull(go) then
            CS.UnityEngine.Object.Destroy(go)
        end
    end
end

---@param point CityInteractPoint_Impl
function CityInteractPointManager:DoDebugGoUse(take, point)
    if not UNITY_EDITOR then return end
    if not self._debugPoint then return end
    local go = self._debugGo[point.index]
    if require("Utils").IsNotNull(go) then
        ---@type CS.UnityEngine.MeshRenderer
        local render = go:GetComponent(typeof(CS.UnityEngine.MeshRenderer))
        if take then
            render.material.color = CS.UnityEngine.Color.red
        else
            render.material.color = CS.UnityEngine.Color.green
        end
    end
end

function CityInteractPointManager:MarkElementNoInteractPoint(elementId)
    self._noInteractPointElementId[elementId] = true
end

function CityInteractPointManager:UnMarkElementNoInteractPoint(elementId)
    self._noInteractPointElementId[elementId] = nil
end

function CityInteractPointManager:FastCheckElementHasNoneInteractPoint(elementId)
    return self._noInteractPointElementId[elementId]
end

return CityInteractPointManager