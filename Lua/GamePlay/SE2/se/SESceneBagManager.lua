local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local Delegate = require("Delegate")

---@class SESceneBagManager
---@field new fun(env:SEEnvironment)
local SESceneBagManager = class("SESceneBagManager")

function SESceneBagManager:ctor(env)
    self._env = env
    self._sceneId = nil
    ---@type table<number, {permanent:number, temporary:number}>
    self.itemCountCache = {}
    self.countChangeListener = {}
end

function SESceneBagManager:InitWithSceneId(sceneId)
    self._sceneId = sceneId
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Scene.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnSceneBagItemChanged))
    self:ReCreateCache()
end

function SESceneBagManager:Dispose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Scene.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnSceneBagItemChanged))
    self._env = nil
    self._sceneId = nil
    table.clear(self.itemCountCache)
end

---@param entity wds.Scene
---@param changeTable {Add:table<number, wds.Item>|nil, Remove:table<number, wds.Item>|nil}
function SESceneBagManager:OnSceneBagItemChanged(entity, changeTable)
    if not self._sceneId or self._sceneId ~= entity.ID then return end
    local notRealAdd = {}
    local countChangeMap = {}
    local dataError = false
    if changeTable.Add then
        for uid, item in pairs(changeTable.Add) do
            if entity.Bag.KItems[uid] == nil then
                notRealAdd[uid] = true
                goto continue
            end

            local cache = self.itemCountCache[item.ConfigId]
            if not cache then
                cache = {permanent = 0, temporary = 0}
                self.itemCountCache[item.ConfigId] = cache
            end
            cache.permanent = cache.permanent + (item.ExpireTime == 0 and item.Count or 0)
            cache.temporary = cache.temporary + (item.ExpireTime ~= 0 and item.Count or 0)
            countChangeMap[item.ConfigId] = true
            ::continue::
        end
    end

    if changeTable.Remove then
        for uid, item in pairs(changeTable.Remove) do
            if notRealAdd[uid] then
                if entity.Bag.KItems[uid] == nil then
                    goto continue
                end
            end

            local cache = self.itemCountCache[item.ConfigId]
            if not cache then
                dataError = true
                break
            end
            cache.permanent = cache.permanent - (item.ExpireTime == 0 and item.Count or 0)
            cache.temporary = cache.temporary - (item.ExpireTime ~= 0 and item.Count or 0)

            if cache.permanent < 0 or cache.temporary < 0 then
                dataError = true
                break
            end
            countChangeMap[item.ConfigId] = true
            ::continue::
        end
    end
    if dataError then
        self:ReCreateCache()
    end
    for id, _ in pairs(countChangeMap) do
        self:DispatchCountChangeEvent(id)
    end
end

function SESceneBagManager:ReCreateCache()
    table.clear(self.itemCountCache)
    if not self._sceneId then return end
    ---@type wds.Scene
    local scene = g_Game.DatabaseManager:GetEntity(self._sceneId, DBEntityType.Scene)
    if not scene or not scene.Bag or not scene.Bag.KItems then return end
    for _, item in pairs(scene.Bag.KItems) do
        local cache = self.itemCountCache[item.ConfigId]
        if not cache then
            cache = {permanent = 0, temporary = 0}
            self.itemCountCache[item.ConfigId] = cache
        end
        cache.permanent = cache.permanent +( (item.ExpireTime == 0) and item.Count or 0 )
        cache.temporary = cache.temporary +( (item.ExpireTime ~= 0) and item.Count or 0 )
    end
end

---@param configId number
---@return number
function SESceneBagManager:GetAmountByConfigId(configId)
    local cache = self.itemCountCache[configId]
    return cache == nil and 0 or cache.permanent + cache.temporary
end

function SESceneBagManager:AddCountChangeListener(id, delegate)
    if not self.countChangeListener then return end
    if not self.countChangeListener[id] then
        self.countChangeListener[id] = {}
    end
    self.countChangeListener[id][delegate] = true
    return function()
        self:RemoveCountChangeListener(id, delegate)
    end
end

function SESceneBagManager:RemoveCountChangeListener(id, delegate)
    if not self.countChangeListener then return end
    if not self.countChangeListener[id] then return end
    self.countChangeListener[id][delegate] = nil
end

function SESceneBagManager:DispatchCountChangeEvent(id)
    if not self.countChangeListener then return end
    local listeners = self.countChangeListener[id]
    if not listeners then return end
    for delegate, _ in pairs(listeners) do
        try_catch_traceback(delegate)
    end
end

function SESceneBagManager:PairsOfCachedItems()
    local itemId, cache = nil, nil
    return function()
        itemId, cache = next(self.itemCountCache, itemId)
        if itemId then
            return itemId, cache and (cache.permanent + cache.temporary) or 0
        end
    end
end

return SESceneBagManager