local EntityEventRegister = require('DBEntityEventRegister')
local Delegate = require('Delegate')
local NetEntityName = require('DBEntityName')
local NetEntityNameToType = require('DBEntityNameToType')
local NetEntityTypeToName = require('DBEntityTypeToName')
local DBEntityViewTypeToEntityType = require("DBEntityViewTypeToEntityType")
local DBEntityViewTypeToName = require("DBEntityViewTypeToName")
local DBEntityPath = require("DBEntityPath")
local SdkCrashlytics = require("SdkCrashlytics")
local EventConst = require("EventConst")

-- 初始化监听全部Entity类型的OnNewEntity和OnDestroyEntity
-- OnNewEntity的回调中注册针对该类型Entity的OnChange，并在OnDestroyEntity中取消注册
---@class DatabaseManager
---@field new fun():DatabaseManager
---@field newViewCallbackByType table<number, table<number, fun()>>
local DatabaseManager = class('DatabaseManager', require("BaseManager"))

function DatabaseManager:ctor()
end

function DatabaseManager:Initialize()
    self.enableLog = self:LogSwitch()
    self.newCallbackByType = {}
    self.newCallback = {}
    self.destroyCallbackByType = {}
    self.destroyCallback = {}

    self.newViewCallback = {}
    self.newViewCallbackByType = {}
    self.destroyViewCallback = {}
    self.destroyViewCallbackByType = {}
    self.newViewFuncCache = {} -- 内部缓存
    self.destroyViewFuncCache = {} -- 内部缓存

    self.entityChangeCbMap = {} -- 保存业务测注册的回调函数
    self.entityChangeFuncCache = {} -- 内部使用，按类型保存entity的change回调，缓存用
    
    self.entityEventRegister = EntityEventRegister.new()
    local onNew = Delegate.GetOrCreate(self, self.OnNewEntity)
    local onDestroy = Delegate.GetOrCreate(self, self.OnDestroyEntity)
    self.entityEventRegister:RegisterNewDestroyCallback(onNew, onDestroy)
    self.inited = true
    g_Logger.Log("Init DatabaseManager.")

    g_Game.EventManager:AddListener(EventConst.WATCHER_CONNECTION_DESTRUCTED, Delegate.GetOrCreate(self, self.OnWatcherConnectionDestructed))
end

function DatabaseManager:Release()
    g_Game.EventManager:RemoveListener(EventConst.WATCHER_CONNECTION_DESTRUCTED, Delegate.GetOrCreate(self, self.OnWatcherConnectionDestructed))
    g_Logger.Log("Release DatabaseManager.")
    
    self.entityMgr = nil
    if self.entityEventRegister then
        self.entityEventRegister:RegisterNewDestroyCallback(nil, nil)
        self.entityEventRegister = nil
    end
    self.entityChangeFuncCache = nil
    self.entityChangeCbMap = nil
    self.destroyCallback = nil
    self.destroyCallbackByType = nil
    self.newCallback = nil
    self.newCallbackByType = nil

    self.newViewCallback = nil
    self.newViewCallbackByType = nil
    self.destroyViewCallback = nil
    self.destroyViewCallbackByType = nil
    self.newViewFuncCache = nil
    self.destroyViewFuncCache = nil
    self.inited = false
end

function DatabaseManager:Reset()
    self:ClearEntities()
    self:Release()
end

function DatabaseManager:SetEntityMgr(entityMgr)
    self.entityMgr = entityMgr
end

function DatabaseManager:OnWatcherConnectionDestructed()
    self:SetEntityMgr(nil)
end

function DatabaseManager:LogSwitch()
    if UNITY_EDITOR then
        return CS.UnityEditor.EditorPrefs.GetInt("GMPanelEnableDatabaseManagerLog") == 1
    else
        return false
    end
end

--region 增
---@private
---@param typeName string NetEntityName的成员
---@param entityType number DBEntityType的成员
---@param entity table entity table
function DatabaseManager:OnNewEntity(typeName, entityType, entity)
    if self.enableLog then
        g_Logger.LogChannel("DB", "[wds.new.%s] detail: \n%s", typeName, FormatTable(entity))    
    end
    -- 向entity注册OnChanged回调
    local onChangeFunc = self:CreateOnChangedFunc(entityType)
    entity:OnChanged(onChangeFunc)
    local onNewViewFunc = self:CreateOnNewViewFunc(entityType)
    entity:OnNewView(onNewViewFunc)
    local onDestroyViewFunc = self:CreateOnDestroyViewFunc(entityType)
    entity:OnDestroyView(onDestroyViewFunc)
    
    local map = self.newCallbackByType[entityType]
    if map then
        for _, v in pairs(map) do
            local state, result = xpcall(v, debug.traceback, entityType, entity)
            if not state then
                g_Logger.Error(result)
            end
        end
    end

    for _, v in ipairs(self.newCallback) do
        local state, result = xpcall(v, debug.traceback, entityType, entity)
        if not state then
            g_Logger.Error(result)
        end
    end
end

---@private
---@param entityType number DBEntityType的成员
function DatabaseManager:CreateOnNewViewFunc(entityType)
    if self.newViewFuncCache[entityType] then
        return self.newViewFuncCache[entityType]
    end

    local function callback(entity, viewTypeHash, refCount)
        if not self.inited then
            g_Logger.ErrorChannel("DB", "OnNewView callback occurs after DatabaseManager Release")
            return
        end

        if self.enableLog then
            g_Logger.LogChannel("DB", ("%s Entity : %d Add New View %s"):format(NetEntityTypeToName[entity.TypeHash], entity.ID, DBEntityViewTypeToName[viewTypeHash]))
        end

        if self.newViewCallback[entityType] then
            for _, v in pairs(self.newViewCallback[entityType]) do
                local state, result = xpcall(v, debug.traceback, entity, viewTypeHash, refCount)
                if not state then
                    g_Logger.Error(result)
                end
            end
        end

        local entityMap = self.newViewCallbackByType[entityType]
        if entityMap then
            local map = entityMap[viewTypeHash]
            if not map then return end

            for _, v in pairs(map) do
                local state, result = xpcall(v, debug.traceback, entity, viewTypeHash, refCount)
                if not state then
                    g_Logger.Error(result)
                end
            end
        end
    end
    self.newViewFuncCache[entityType] = callback
    return callback
end

---@private
---@param entityType number DBEntityType的成员
function DatabaseManager:CreateOnDestroyViewFunc(entityType)
    if self.destroyViewFuncCache[entityType] then
        return self.destroyViewFuncCache[entityType]
    end

    local function callback(entity, viewTypeHash, refCount)
        if not self.inited then
            g_Logger.ErrorChannel("DB", "OnDestoryView callback occurs after DatabaseManager Release")
            return
        end

        if self.enableLog then
            g_Logger.LogChannel("DB", ("%s Entity : %d Delete New View %s"):format(NetEntityTypeToName[entity.TypeHash], entity.ID, DBEntityViewTypeToName[viewTypeHash]))
        end

        if self.destroyViewCallback[entityType] then
            for _, v in pairs(self.destroyViewCallback[entityType]) do
                local state, result = xpcall(v, debug.traceback, entity, viewTypeHash, refCount)
                if not state then
                    g_Logger.Error(result)
                end
            end
        end

        local entityMap = self.destroyViewCallbackByType[entityType]
        if entityMap then
            local map = entityMap[viewTypeHash]
            if not map then return end

            for _, v in pairs(map) do
                local state, result = xpcall(v, debug.traceback, entity, viewTypeHash, refCount)
                if not state then
                    g_Logger.Error(result)
                end
            end
        end
    end
    self.destroyViewFuncCache[entityType] = callback
    return callback
end

--endregion 增

--region 删
---@private
---@param typeName string NetEntityName的成员
---@param entityType number DBEntityType的成员
---@param entity table entity table
function DatabaseManager:OnDestroyEntity(typeName, entityType, entity)
    if self.enableLog then
        g_Logger.LogChannel("DB", "[wds.destroy.%s] detail: \n%s", typeName, FormatTable(entity))
    end
    -- 向entity取消注册OnChanged回调
    --entity:OnChanged(nil)
    
    local map = self.destroyCallbackByType[entityType]
    if map then
        for _, v in pairs(map) do
            local state, result = xpcall(v, debug.traceback, entityType, entity)
            if not state then
                g_Logger.Error(result)
            end
        end
    end

    for _, v in ipairs(self.destroyCallback) do
        local state, result = xpcall(v, debug.traceback, entityType, entity)
        if not state then
            g_Logger.Error("entityType:%s, entityId:%s, typeName:%s error:%s",entityType, entity.ID, entity.TypeName ,result)
        end
    end
end

---销毁指定类型的所有entity
---@param entityType number 实体类型，DBEntityType的成员
function DatabaseManager:DestroyEntitiesByType(entityType)
    if self.entityMgr then
        self.entityMgr:DestroyEntitiesByTypeHash(entityType)
    end
end

---销毁指定entity
---@param id number entity id
---@param type number 实体类型，DBEntityType的成员
function DatabaseManager:DestroyEntity(id, type)
    if self.entityMgr then
        return self.entityMgr:DestroyEntity(id, type)
    end
end

---清空所有entity
function DatabaseManager:ClearEntities()
    if self.entityMgr then
        if g_Game.ServiceManager:IsConnectionValid() then
            self.entityMgr:DestroyEntitiesAndRaiseEvent()
            SdkCrashlytics.RecordCrashlyticsLog("DatabaseManager.entityMgr:DestroyEntitiesAndRaiseEvent")
        else
            self.entityMgr:ClearEntities()
            SdkCrashlytics.RecordCrashlyticsLog("DatabaseManager.entityMgr:ClearEntities")
        end
    end
end
--endregion 删

--region 改
---@private
function DatabaseManager.GetOnChangedRelativePath(entity, changedTable)
    if entity == nil or entity.TypeHash == nil then return end
    if changedTable == nil then return end

    local rootName = NetEntityTypeToName[entity.TypeHash]
    local ret = {}
    local pathTable = DBEntityPath[rootName]
    return DatabaseManager.GetChangeTablePath(pathTable, ret, changedTable)
end

---@private
function DatabaseManager.GetChangeTablePath(pathTable, ret, changedTable)
    if pathTable == nil then return ret end
    table.insert(ret, {path = pathTable.MsgPath, changedTable = changedTable})
    if type(changedTable) ~= "table" then return ret end

    for k, v in pairs(changedTable) do
        DatabaseManager.GetChangeTablePath(pathTable[k], ret, v)
    end
    return ret
end

---@private
---@param entityType number 使用DBEntityType的成员
function DatabaseManager:CreateOnChangedFunc(entityType)
    -- 查缓存
    if self.entityChangeFuncCache[entityType] then
        return self.entityChangeFuncCache[entityType]
    end
    
    -- 缓存无则创建
    local cbMap = self.entityChangeCbMap[entityType]
    if not cbMap then
        cbMap = {}
        self.entityChangeCbMap[entityType] = cbMap
    end
    local onChangeFunc = function(entity, changedTable)
        if not self.inited then
            g_Logger.ErrorChannel("DB", "OnChange callback occurs after DatabaseManager Release")
            return
        end

        if self.enableLog then
            g_Logger.LogChannel("DB", "[wds.change.%s] entity: %s, changed table: %s", NetEntityTypeToName[entityType], entity.ID, FormatTable(changedTable))
        end

        local ret = DatabaseManager.GetOnChangedRelativePath(entity, changedTable)
        for i, wrap in ipairs(ret) do
            local array = cbMap[wrap.path]
            if array == nil then goto continue end
            for _, v in ipairs(array) do
                local state, result = xpcall(v, debug.traceback, entity, wrap.changedTable)
                if not state then
                    g_Logger.ErrorChannel("DB", "OnChange Path:%s, error msg:%s", wrap.path, result)
                end
            end
            ::continue::
        end
    end
    self.entityChangeFuncCache[entityType] = onChangeFunc
    return onChangeFunc
end
--endregion 改

--region 查
---获取所有实体列表
---@return table 返回所有实体
function DatabaseManager:GetAllEntities()
    if self.entityMgr then
        return self.entityMgr:GetAllEntities()
    end
    return nil
end

---获取指定ID的实体
---@param id number entity id
---@param type number 实体类型，DBEntityType的成员
---@return table 返回指定id的实体
function DatabaseManager:GetEntity(id, type)
    if self.entityMgr then
        return self.entityMgr:GetEntity(id, type)
    end
    return nil
end

---获取指定类型的实体列表
---@param entityType number 使用DBEntityType的成员
---@return table 返回所有指定类型的实体
function DatabaseManager:GetEntitiesByType(entityType)
    if self.entityMgr then
        return self.entityMgr:GetEntitiesByTypeHash(entityType)
    end
    return nil
end

function DatabaseManager:GetEntitiesById(id)
    if self.entityMgr then
        return self.entityMgr:GetEntitiesById(id)
    end
    return nil
end

function DatabaseManager.DumpEntity(idOrEntity)
    if type(idOrEntity) == "number" then
        local entitys = g_Game.DatabaseManager.entityMgr:GetEntitiesById(idOrEntity)
        if #entitys > 0 then
            return tostring(FormatTable(entitys[1]))
        else
            return string.format("entity not found. id: %s", idOrEntity)
        end
    else
        return tostring(idOrEntity)
    end
end

function DatabaseManager.DumpEntityTypes()
    return require("DBEntityType")
end

local function TableIsArray(targetTable)
    local arrayCount = table.ipairsNums(targetTable)
    local rawCount = table.nums(targetTable)
    if arrayCount == rawCount and targetTable[1] then
        return true
    end
    return false
end

---@param entity any
---@return table
local function FilterEntity(entity, showHideEntityComponent)
    if type(entity) ~= 'table' then
        return entity
    end
    local ret = {}
    if TableIsArray(entity) then
        for key, v in ipairs(entity) do
            ret[key] = FilterEntity(v, showHideEntityComponent)
        end
    else
        for key, v in pairs(entity) do
            if showHideEntityComponent then
                ret[tostring(key)] = FilterEntity(v, showHideEntityComponent)
            elseif (type(key) ~= 'string' or (key ~= "__components" and key ~= "__views")) then
                ret[tostring(key)] = FilterEntity(v, showHideEntityComponent)
            end
        end
    end
    return ret
end

function DatabaseManager.DumpEntityToJson(idOrEntity, showHideEntityComponent)
    local jsonUtility = require("rapidjson")
    if type(idOrEntity) == "number" then
        local entitys = g_Game.DatabaseManager.entityMgr:GetEntitiesById(idOrEntity)
        if #entitys > 0 then
            local t = {}
            for _, v in ipairs(entitys) do
                table.insert(t, FilterEntity(v, showHideEntityComponent))
            end
            return jsonUtility.encode(t)
        else
            return nil
        end
    else
        return jsonUtility.encode(FilterEntity(idOrEntity, showHideEntityComponent))
    end
end

function DatabaseManager.DumpEntityByTypeAndIdToJson(id, typeHash, showHideEntityComponent)
    local jsonUtility = require("rapidjson")
    local entity = g_Game.DatabaseManager.entityMgr:GetEntity(id, typeHash)
    if entity then
        return jsonUtility.encode(FilterEntity(entity, showHideEntityComponent))
    else
        return nil
    end
end

function DatabaseManager.DumpEntityIdsByTypeToJson(typeHash)
    local jsonUtility = require("rapidjson")
    local entities = g_Game.DatabaseManager.entityMgr:GetEntitiesByTypeHash(typeHash)
    if entities then
        local t = {}
        for _, v in pairs(entities) do
            local id = v.ID
            if id then
                table.insert(t, id)
            end
        end
        return jsonUtility.encode(t)
    else
        return nil
    end
end

function DatabaseManager.SetPlayerIdForDebug(playerId)
    DatabaseManager.___playerId = playerId
end

function DatabaseManager.SetAllianceIdForDebug(allianceId)
    DatabaseManager.___allianceId = allianceId
end

function DatabaseManager.SetCastleBriefId(castleBriefId)
    DatabaseManager.___castleBriefId = castleBriefId
end

function DatabaseManager.DumpShotCutIds()
    if not DatabaseManager.___playerId then
        return nil
    end
    if not DatabaseManager.___debugRet then
        DatabaseManager.___debugRet = {}
    end
    DatabaseManager.___debugRet.PlayerId = DatabaseManager.___playerId
    DatabaseManager.___debugRet.AllianceId = DatabaseManager.___allianceId
    DatabaseManager.___debugRet.CastleBrief = DatabaseManager.___castleBriefId
    return DatabaseManager.___debugRet
end

--endregion 查

--region 事件注册
---监听任意实体创建
---@param callback fun(entityType:number, entity):void
function DatabaseManager:AddEntityNew(callback)
    table.insert(self.newCallback, callback)
end

---取消监听任意实体创建
---@param callback fun(entityType:number, entity):void
function DatabaseManager:RemoveEntityNew(callback)
    table.removebyvalue(self.newCallback, callback, true)
end

---监听任意实体销毁
---@param callback fun(entityType:number, entity):void
function DatabaseManager:AddEntityDestroy(callback)
    table.insert(self.destroyCallback, callback)
end

---取消监听任意实体销毁
---@param callback fun(entityType:number, entity):void
function DatabaseManager:RemoveEntityDestroy(callback)
    table.removebyvalue(self.destroyCallback, callback, true)
end

---监听指定类型实体创建
---@param entityType number 使用DBEntityType的成员
---@param callback fun(entityType:number, entity):void
function DatabaseManager:AddEntityNewByType(entityType, callback)
    local map = self.newCallbackByType[entityType]
    if not map then
        map = {}
        self.newCallbackByType[entityType] = map
    end
    table.insert(map, callback)
end

---取消监听指定类型实体创建
---@param entityType number 使用DBEntityType的成员
---@param callback fun(entityType:number, entity):void
function DatabaseManager:RemoveEntityNewByType(entityType, callback)
    local map = self.newCallbackByType[entityType]
    if map then
        table.removebyvalue(map, callback, true)
    end
end

---监听指定类型实体销毁
---@param entityType number 使用DBEntityType的成员
---@param callback fun(entityType:number, entity):void
function DatabaseManager:AddEntityDestroyByType(entityType, callback)
    local map = self.destroyCallbackByType[entityType]
    if not map then
        map = {}
        self.destroyCallbackByType[entityType] = map
    end
    table.insert(map, callback)
end

---取消监听指定类型实体销毁
---@param entityType number 使用DBEntityType的成员
---@param callback fun(entityType:number, entity):void
function DatabaseManager:RemoveEntityDestroyByType(entityType, callback)
    local map = self.destroyCallbackByType[entityType]
    if map then
        table.removebyvalue(map, callback, true)
    end
end

---监听某一类Entity任意View实例创建
---@param entityType number 使用DBEntityType的成员
---@param callback fun(entity, viewTypeHash:number, refCount:number)
function DatabaseManager:AddViewNew(entityType, callback)
    local map = self.newViewCallback[entityType]
    if not map then
        map = {}
        self.newViewCallback[entityType] = map
    end
    table.insert(map, callback)
end

---取消监听某一类Entity任意View实例创建
---@param entityType number 使用DBEntityType的成员
---@param callback fun(entity, viewTypeHash:number, refCount:number)
function DatabaseManager:RemoveViewNew(entityType, callback)
    local map = self.newViewCallback[entityType]
    if map then
        table.removebyvalue(map, callback, true)
    end
end

---监听某一类Entity任意View实例销毁
---@param entityType number 使用DBEntityType的成员
---@param callback fun(entity, viewTypeHash:number, refCount:number)
function DatabaseManager:AddViewDestroy(entityType, callback)
    local map = self.destroyViewCallback[entityType]
    if not map then
        map = {}
        self.destroyViewCallback[entityType] = map
    end
    table.insert(map, callback)
end

---取消监听某一类Entity任意View实例销毁
---@param entityType number 使用DBEntityType的成员
---@param callback fun(entity, viewTypeHash:number, refCount:number)
function DatabaseManager:RemoveViewDestroy(entityType, callback)
    local map = self.destroyViewCallback[entityType]
    if map then
        table.removebyvalue(map, callback, true)
    end
end

---监听指定类型实体的View切片创建
---@param viewType number 使用DBEntityViewType的成员
---@param callback fun(entity, viewType:number, refCount:number):void
function DatabaseManager:AddViewNewByType(viewType, callback)
    local entityType = DBEntityViewTypeToEntityType[viewType]
    if not entityType then
        g_Logger.Error(("%d 不存在对应的Entity类型"):format(viewType))
        return
    end

    local entityMap = self.newViewCallbackByType[entityType]
    if not entityMap then
        entityMap = {}
        self.newViewCallbackByType[entityType] = entityMap
    end

    local map = entityMap[viewType]
    if not map then
        map = {}
        entityMap[viewType] = map
    end

    table.insert(map, callback)
end

---取消监听指定类型实体的View切片创建
---@param viewType number 使用DBEntityViewType的成员
---@param callback fun(entity, viewType:number, refCount:number):void
function DatabaseManager:RemoveViewNewByType(viewType, callback)
    local entityType = DBEntityViewTypeToEntityType[viewType]
    if not entityType then
        g_Logger.Error(("%d 不存在对应的Entity类型"):format(viewType))
        return
    end

    local entityMap = self.newViewCallbackByType[entityType]
    if entityMap then
        local map = entityMap[viewType]
        if map then
            table.removebyvalue(map, callback, true)
        end
    end
end


---监听指定类型实体的View切片销毁
---@param viewType number 使用DBEntityViewType的成员
---@param callback fun(entity, viewType:number, refCount:number):void
function DatabaseManager:AddViewDestroyByType(viewType, callback)
    local entityType = DBEntityViewTypeToEntityType[viewType]
    if not entityType then
        g_Logger.Error(("%d 不存在对应的Entity类型"):format(viewType))
        return
    end

    local entityMap = self.destroyViewCallbackByType[entityType]
    if not entityMap then
        entityMap = {}
        self.destroyViewCallbackByType[entityType] = entityMap
    end

    local map = entityMap[viewType]
    if not map then
        map = {}
        entityMap[viewType] = map
    end

    table.insert(map, callback)
end

---取消监听指定类型实体的View切片销毁
---@param viewType number 使用DBEntityViewType的成员
---@param callback fun(entity, viewType:number, refCount:number):void
function DatabaseManager:RemoveViewDestroyByType(viewType, callback)
    local entityType = DBEntityViewTypeToEntityType[viewType]
    if not entityType then
        g_Logger.Error(("%d 不存在对应的Entity类型"):format(viewType))
        return
    end

    local entityMap = self.destroyViewCallbackByType[entityType]
    if entityMap then
        local map = entityMap[viewType]
        if map then
            table.removebyvalue(map, callback, true)
        end
    end
end

---监听实体数据变化
---@param path string 监听的数据在Entity中的层级，例如："Castle"，监听Player中Castle的数据变化
---@param callback fun(entity:table,  changedData:any):void
function DatabaseManager:AddChanged(path, callback, pos)
    local entityType = self:GetEntityTypeByDataPath(path)
    if entityType == 0 or entityType == nil then
        g_Logger.Error("无法从路径中获取有效的Entity类型，path: %s", path)
        return
    end
    
    local map = self.entityChangeCbMap[entityType]
    if not map then
        map = {}
        self.entityChangeCbMap[entityType] = map
    end
    
    local cbs = map[path]
    if not cbs then
        cbs = {}
        map[path] = cbs
    end
    
    if pos then
        table.insert(cbs, pos, callback)
    else
        table.insert(cbs, callback)
    end
end

---取消监听实体数据变化
---@param path string 监听的数据在Entity中的层级，例如："Castle"，监听Player中Castle的数据变化
---@param callback fun(data:table,  changedData:any):void
function DatabaseManager:RemoveChanged(path, callback)
    local entityType = self:GetEntityTypeByDataPath(path)
    if entityType == 0 or entityType == nil then
        g_Logger.Error("无法从路径中获取有效的Entity类型，path: %s", path)
        return
    end
    
    local map = self.entityChangeCbMap[entityType]
    if map then
        local cbs = map[path]
        if cbs then
            table.removebyvalue(cbs, callback, true)
        end
    end
end

---@private
function DatabaseManager:GetEntityTypeByDataPath(path)
    local realIdx, _ = string.find(path, "%.", 1)
    if realIdx == nil then
        realIdx = string.len(path)+1
    end
    
    for _, v in pairs(NetEntityName) do
        local start_i, end_i= string.find(path, v, 1)
        if start_i == 1 and end_i == realIdx-1 then
            return NetEntityNameToType[v] 
        end
    end
    return nil
end
--endregion 事件注册

return DatabaseManager
