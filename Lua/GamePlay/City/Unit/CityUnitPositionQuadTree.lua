local QuadTreeNode = require("QuadTreeNode")
local QuadTreeLeaf = require("QuadTreeLeaf")
local Rect = require("Rect")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local SlgUtils = require("SlgUtils")
local DBEntityPath = require('DBEntityPath')
local ModuleRefer = require('ModuleRefer')
---@class CityUnitPositionQuadTree
---@field new fun():CityUnitPositionQuadTree
local CityUnitPositionQuadTree = sealedClass('CityUnitPositionQuadTree')

function CityUnitPositionQuadTree:ctor()
    ---@type table<QuadTreeLeaf, QuadTreeLeaf>
    self._trackedLeaf = {}
    self._tmpRect = Rect.new(0, 0, 0, 0)
    self._eventsAdd = false
    self._slgEnemyTroops = {}
    self._slgTroopRadius = 0.1
end

function CityUnitPositionQuadTree:Init(x, y, sizeX, sizeY)
    self._quadTree = QuadTreeNode.new(Rect.new(x, y, sizeX, sizeY))
end

function CityUnitPositionQuadTree:AddEvents()
   self:SetupEvents(true) 
end

function CityUnitPositionQuadTree:RemoveEvents()
    self:SetupEvents(false)
end

function CityUnitPositionQuadTree:SetupEvents(add)
    if not self._eventsAdd and add then
        g_Game.EventManager:AddListener(EventConst.ON_TROOP_CREATED, Delegate.GetOrCreate(self, self.OnAddTroop))
        -- g_Game.EventManager:AddListener(EventConst.ON_TROOP_MOVED, Delegate.GetOrCreate(self, self.OnTroopMoved))
        -- g_Game.EventManager:AddListener(EventConst.ON_CITY_MONSTER_TROOP_MOVED, Delegate.GetOrCreate(self, self.OnTroopMoved))
        g_Game.EventManager:AddListener(EventConst.ON_TROOP_DESTROYED, Delegate.GetOrCreate(self, self.OnTroopRemoved))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Troop.MapBasics.Position.MsgPath,Delegate.GetOrCreate(self, self.OnTroopMoved))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.MapMob.MapBasics.Position.MsgPath,Delegate.GetOrCreate(self, self.OnMonsterTroopMoved))
    elseif self._eventsAdd and not add then
        g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_CREATED, Delegate.GetOrCreate(self, self.OnAddTroop))
        -- g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_MOVED, Delegate.GetOrCreate(self, self.OnTroopMoved))
        -- g_Game.EventManager:RemoveListener(EventConst.ON_CITY_MONSTER_TROOP_MOVED, Delegate.GetOrCreate(self, self.OnTroopMoved))
        g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_DESTROYED, Delegate.GetOrCreate(self, self.OnTroopRemoved))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Troop.MapBasics.Position.MsgPath,Delegate.GetOrCreate(self, self.OnTroopMoved))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapMob.MapBasics.Position.MsgPath,Delegate.GetOrCreate(self, self.OnMonsterTroopMoved))
    end
    self._eventsAdd = add
end

---@return QuadTreeLeaf
function CityUnitPositionQuadTree:AddLeaf(x, y, w, h, type)
    local leaf = QuadTreeLeaf.new(Rect.new(x, y, w, h), type)
    self._quadTree:Insert(leaf)
    self._trackedLeaf[leaf] = leaf
    return leaf
end

---@param leaf QuadTreeLeaf
function CityUnitPositionQuadTree:UpdateLeaf(leaf, x, y, w, h, t)
    if not self._trackedLeaf[leaf] then
        return false
    end
    self._quadTree:Remove(leaf)
    leaf.rect.x = x or leaf.rect.x
    leaf.rect.y = y or leaf.rect.y
    leaf.rect.sizeX = w or leaf.rect.sizeX
    leaf.rect.sizeY = h or leaf.rect.sizeY
    leaf.value = t or leaf.value
    self._quadTree:Insert(leaf)
    return true
end

---@param leaf QuadTreeLeaf
function CityUnitPositionQuadTree:RemoveLeaf(leaf)
    if not self._trackedLeaf[leaf] then
        return false
    end
    self._quadTree:Remove(leaf)
    self._trackedLeaf[leaf] = nil
    return true
end

---@return QuadTreeLeaf[]
function CityUnitPositionQuadTree:SearchAny(x, y, w, h)
    if not self._queryResult then
        self._queryResult = {}
    end
    self._tmpRect.x = x
    self._tmpRect.y = y
    self._tmpRect.sizeX = w
    self._tmpRect.sizeY = h
    return self._quadTree:SearchByRect(self._tmpRect, false, self._queryResult)
end

---@param troopId number
---@param troopType SlgUtils.TroopType
---@param position CS.UnityEngine.Vector3
function CityUnitPositionQuadTree:OnAddTroop(troopId, troopType, position)
    if troopType < SlgUtils.TroopType.Monster then
        return
    end
    local typeMap = self._slgEnemyTroops[troopType]
    if not typeMap then
        typeMap = {}
        self._slgEnemyTroops[troopType] = typeMap
     end
    local leaf = typeMap[troopId]
    if leaf then
        return
    end
    leaf = self:AddLeaf(position.x, position.z, self._slgTroopRadius, self._slgTroopRadius, troopType)
    typeMap[troopId] = leaf
end

---@param data wds.Troop
---@param changed wds.Vector3F
function CityUnitPositionQuadTree:OnTroopMoved(data,changed)      
    local troopId = data.ID
    local position = ModuleRefer.SlgModule:ServerCoordinate2Vector3(changed)
    local typeMap = self._slgEnemyTroops[SlgUtils.TroopType.MySelf]
    if not typeMap then
        return
    end
    local leaf = typeMap[troopId]
    if not leaf then
        return
    end
    self:UpdateLeaf(leaf, position.x, position.z)
end

function CityUnitPositionQuadTree:OnMonsterTroopMoved(data,changed)    
    local troopId = data.ID
    local position = ModuleRefer.SlgModule:ServerCoordinate2Vector3(changed)
    local typeMap = self._slgEnemyTroops[SlgUtils.TroopType.Monster]
    if not typeMap then
        return
    end
    local leaf = typeMap[troopId]
    if not leaf then
        return
    end
    self:UpdateLeaf(leaf, position.x, position.z)
end 

-- function CityUnitPositionQuadTree:OnTroopMoved(troopId, troopType, position)
--     if troopType < SlgUtils.TroopType.Monster then
--         return
--     end
--     local typeMap = self._slgEnemyTroops[troopType]
--     if not typeMap then
--         return
--     end
--     local leaf = typeMap[troopId]
--     if not leaf then
--         return
--     end
--     self:UpdateLeaf(leaf, position.x, position.z)
-- end

function CityUnitPositionQuadTree:OnTroopRemoved(troopId, troopType)
    if troopType < SlgUtils.TroopType.Monster then
        return
    end
    local typeMap = self._slgEnemyTroops[troopType]
    if not typeMap then
        return
    end
    local leaf = typeMap[troopId]
    if not leaf then
        return
    end
    typeMap[troopId] = nil
    self:RemoveLeaf(leaf)
end

---@param city City
function CityUnitPositionQuadTree:DebugDrawGrid(city)
    local color = CS.UnityEngine.Color.white
    for i, v in pairs(self._trackedLeaf) do
        local rect = v.rect
        local gridX,gridY = city:GetCoordFromPosition(CS.UnityEngine.Vector3(rect.x, 0, rect.y))
        city:DebugDrawGrid(gridX, gridY, color)
    end
end

return CityUnitPositionQuadTree