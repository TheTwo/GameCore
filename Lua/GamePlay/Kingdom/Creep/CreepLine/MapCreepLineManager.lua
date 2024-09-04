local Delegate = require("Delegate")
local DBEntityType = require("DBEntityType")
local DBEntityViewType = require("DBEntityViewType")
local DBEntityPath = require("DBEntityPath")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local MapCreepLineLinkInfo = require("MapCreepLineLinkInfo")
local ManualResourceConst = require("ManualResourceConst")

local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper

---@class MapCreepLineManager
---@field new fun():MapCreepLineManager
local MapCreepLineManager = class('MapCreepLineManager')

---@alias InQueueInfo {from:number,to:number,path:CS.UnityEngine.Vector3[],refCount:number}

function MapCreepLineManager:ctor()
    self.creator = PooledGameObjectCreateHelper.Create("MapCreepLine")
    self.eventsSetup = false
    self.inUsingLine = MapCreepLineLinkInfo.new()
    ---@type InQueueInfo[]
    self.inQueueWaitShow = {}
    self.frameAddLimit = 3
    self.tickDirty = false
    self.linePrefabName = ManualResourceConst.fx_map_creep_line
    self.init = false
end

function MapCreepLineManager:Init()
    self.init = true
end

function MapCreepLineManager:Release()
    self.init = false
    self.tickDirty = false
    table.clear(self.inQueueWaitShow)
    self.inUsingLine:CleanUp()
end

function MapCreepLineManager:SetupEvents(add)
    if add and not self.eventsSetup then
        self.eventsSetup = true
        g_Game.DatabaseManager:AddViewNewByType(DBEntityViewType.ViewSlgCreepTumorForMap, Delegate.GetOrCreate(self, self.OnSlgCreepCenterAdd))
        g_Game.DatabaseManager:AddViewDestroyByType(DBEntityViewType.ViewSlgCreepTumorForMap, Delegate.GetOrCreate(self, self.OnSlgCreepCenterRemove))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.SlgCreepTumor.CreepSpread.Parent.MsgPath, Delegate.GetOrCreate(self, self.OnSlgCreepCenterParentLinkUpdate))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.SlgCreepTumor.CreepSpread.Childs.MsgPath, Delegate.GetOrCreate(self, self.OnSlgCreepCenterChildLinkUpdate))
        g_Game.DatabaseManager:AddViewNewByType(DBEntityViewType.ViewVillageForMap, Delegate.GetOrCreate(self, self.OnVillageAdd))
        g_Game.DatabaseManager:AddViewDestroyByType(DBEntityViewType.ViewVillageForMap, Delegate.GetOrCreate(self, self.OnVillageRemove))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.CreepSpread.Parent.MsgPath,  Delegate.GetOrCreate(self, self.OnVillageParentLinkUpdate))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.CreepSpread.Childs.MsgPath,  Delegate.GetOrCreate(self, self.OnVillageChildLinkUpdate))
    elseif not add and self.eventsSetup then
        self.eventsSetup = false
        g_Game.DatabaseManager:RemoveViewNewByType(DBEntityViewType.ViewSlgCreepTumorForMap, Delegate.GetOrCreate(self, self.OnSlgCreepCenterAdd))
        g_Game.DatabaseManager:RemoveViewDestroyByType(DBEntityViewType.ViewSlgCreepTumorForMap, Delegate.GetOrCreate(self, self.OnSlgCreepCenterRemove))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.SlgCreepTumor.CreepSpread.Parent.MsgPath, Delegate.GetOrCreate(self, self.OnSlgCreepCenterParentLinkUpdate))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.SlgCreepTumor.CreepSpread.Childs.MsgPath, Delegate.GetOrCreate(self, self.OnSlgCreepCenterChildLinkUpdate))
        g_Game.DatabaseManager:RemoveViewNewByType(DBEntityViewType.ViewVillageForMap, Delegate.GetOrCreate(self, self.OnVillageAdd))
        g_Game.DatabaseManager:RemoveViewDestroyByType(DBEntityViewType.ViewVillageForMap, Delegate.GetOrCreate(self, self.OnVillageRemove))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.CreepSpread.Parent.MsgPath,  Delegate.GetOrCreate(self, self.OnVillageParentLinkUpdate))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.CreepSpread.Childs.MsgPath,  Delegate.GetOrCreate(self, self.OnVillageChildLinkUpdate))
    end
end

---@param entity wds.SlgCreepTumor
function MapCreepLineManager:OnSlgCreepCenterAdd(entity, viewType, refCount)
    if refCount > 1 then return end
    self:DoAddById(entity.ID, entity.CreepSpread)
end

---@param entity wds.SlgCreepTumor
function MapCreepLineManager:OnSlgCreepCenterRemove(entity, viewType, refCount)
    if refCount > 1 then return end
    self:DoRemoveById(entity.ID)
end

---@param entity wds.SlgCreepTumor  
function MapCreepLineManager:OnSlgCreepCenterParentLinkUpdate(entity)
    self:DoRemoveByTo(entity.ID)
    local inQueueCount = #self.inQueueWaitShow
    self:DoAddAsTo(entity.ID, entity.CreepSpread)
    if #self.inQueueWaitShow ~= inQueueCount then
        self.tickDirty = true
    end
end

---@param entity wds.SlgCreepTumor  
function MapCreepLineManager:OnSlgCreepCenterChildLinkUpdate(entity)
    self:DoRemoveByFrom(entity.ID)
    local inQueueCount = #self.inQueueWaitShow
    self:DoAddAsFrom(entity.ID, entity.CreepSpread)
    if #self.inQueueWaitShow ~= inQueueCount then
        self.tickDirty = true
    end
end

---@param entity wds.Village
function MapCreepLineManager:OnVillageAdd(entity, viewType, refCount)
    if refCount > 1 then return end
    self:DoAddById(entity.ID, entity.CreepSpread)
end

---@param entity wds.Village
function MapCreepLineManager:OnVillageRemove(entity, viewType, refCount)
    if refCount > 1 then return end
    self:DoRemoveById(entity.ID)
end

---@param entity wds.Village
function MapCreepLineManager:OnVillageParentLinkUpdate(entity)
    self:DoRemoveByTo(entity.ID)
    local inQueueCount = #self.inQueueWaitShow
    self:DoAddAsTo(entity.ID, entity.CreepSpread)
    if #self.inQueueWaitShow ~= inQueueCount then
        self.tickDirty = true
    end
end

---@param entity wds.Village
function MapCreepLineManager:OnVillageChildLinkUpdate(entity)
    self:DoRemoveByFrom(entity.ID)
    local inQueueCount = #self.inQueueWaitShow
    self:DoAddAsFrom(entity.ID, entity.CreepSpread)
    if #self.inQueueWaitShow ~= inQueueCount then
        self.tickDirty = true
    end
end

---@param creepSpread wds.CreepSpread
function MapCreepLineManager:DoAddById(entityId, creepSpread)
    local inQueueCount = #self.inQueueWaitShow
    self:DoAddAsTo(entityId, creepSpread)
    self:DoAddAsFrom(entityId, creepSpread)
    if #self.inQueueWaitShow ~= inQueueCount then
        self.tickDirty = true
    end
end

---@param creepSpread wds.CreepSpread
function MapCreepLineManager:DoAddAsFrom(entityId, creepSpread)
    if creepSpread.Childs then
        for _, value in ipairs(creepSpread.Childs) do
            if value.State == wds.CreepTumorNodeStatus.CreepTumorNodeStatusNormal and not value.NotWorking and #value.Path > 1 then
                self:DoAddFromToSpread(entityId, value.EntityId, value.Path)
            end
        end
    end
end

---@param creepSpread wds.CreepSpread
function MapCreepLineManager:DoAddAsTo(entityId, creepSpread)
    if creepSpread.Parent and creepSpread.Parent.State == wds.CreepTumorNodeStatus.CreepTumorNodeStatusNormal and #creepSpread.Parent.Path > 1 then
        self:DoAddFromToSpread(creepSpread.Parent.Id, entityId, creepSpread.Parent.Path)
    end
end

---@param path wds.Vector3F[]
function MapCreepLineManager:DoAddFromToSpread(from, to, path)
    if self.inUsingLine:HasLink(from, to) then
        self.inUsingLine:AddLinkRef(from, to)
        return
    end
    for i = #self.inQueueWaitShow, 1, -1 do
        local queueInfo = self.inQueueWaitShow[i]
        if queueInfo.from == from and queueInfo.to == to then
            queueInfo.refCount = queueInfo.refCount + 1
            return
        end
    end
    ---@type InQueueInfo
    local addToQueue = {}
    addToQueue.from = from
    addToQueue.to = to
    addToQueue.path = {}
    addToQueue.refCount = 1
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    for _, pos in ipairs(path) do
        local x = pos.X * staticMapData.UnitsPerTileX
        local z = pos.Y * staticMapData.UnitsPerTileZ
        local y = KingdomMapUtils.SampleHeight(x, z) + 10
        table.insert(addToQueue.path, CS.UnityEngine.Vector3(x, y, z))
    end
    table.insert(self.inQueueWaitShow, addToQueue)
    return
end

function MapCreepLineManager:DoRemoveFromToLink(from, to)
    for i = #self.inQueueWaitShow, 1, -1 do
        local info = self.inQueueWaitShow[i]
        if info.from == from and info.to == to then
            info.refCount = info.refCount - 1
            if info.refCount <= 0 then
               table.remove(self.inQueueWaitShow, i)
               return
            end
        end
    end
    self.inUsingLine:RemoveLinkRef(from, to)
end

function MapCreepLineManager:DoRemoveById(fromOrTo)
    for i = #self.inQueueWaitShow, 1, -1 do
        local info = self.inQueueWaitShow[i]
        if info.from == fromOrTo or info.to == fromOrTo then
            info.refCount = info.refCount - 1
            if info.refCount <= 0 then
                table.remove(self.inQueueWaitShow, i)
            end
        end
    end
    self.inUsingLine:TryRemove(fromOrTo)
end

function MapCreepLineManager:DoRemoveByFrom(from)
    for i = #self.inQueueWaitShow, 1, -1 do
        local info = self.inQueueWaitShow[i]
        if info.from == from then
            info.refCount = info.refCount - 1
            if info.refCount <= 0 then
               table.remove(self.inQueueWaitShow, i)
            end
        end
    end
    self.inUsingLine:TryRemoveLinkRefByFrom(from)
end

function MapCreepLineManager:DoRemoveByTo(to)
    for i = #self.inQueueWaitShow, 1, -1 do
        local info = self.inQueueWaitShow[i]
        if info.to == to then
            info.refCount = info.refCount - 1
            if info.refCount <= 0 then
               table.remove(self.inQueueWaitShow, i)
            end
        end
    end
    self.inUsingLine:TryRemoveLinkRefByTo(to)
end

function MapCreepLineManager:Tick(dt)
    if not self.tickDirty then return end
    local limit = self.frameAddLimit
    while limit > 0 do
        limit = limit - 1
        local pop = table.remove(self.inQueueWaitShow, 1)
        if not pop then
            self.tickDirty = false
            return
        end
        local handle = self.creator:Create(self.linePrefabName, ModuleRefer.SlgModule.worldHolder, Delegate.GetOrCreate(self, self.OnAssetLoaded), pop)
        self.inUsingLine:CreateLink(pop.from, pop.to, pop.refCount ,handle)
    end
end

---@param go CS.UnityEngine.GameObject
---@param userData InQueueInfo
---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function MapCreepLineManager:OnAssetLoaded(go, userData, handle)
    if not self.init then
        handle:Delete()
        return
    end
    local beheviour = go:GetLuaBehaviour("MapCreepLine")
    if UNITY_EDITOR then
        go.name = ("creep_link_%s->%s refCount:%s"):format(userData.from, userData.to, userData.refCount)
    end
    ---@type MapCreepLine
    local lua = beheviour and beheviour.Instance
    if not lua then
        handle:Delete()
        return
    end
    lua:SetLineArray(userData.path)
end

return MapCreepLineManager