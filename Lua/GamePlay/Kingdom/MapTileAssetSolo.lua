--警告：不要随意修改这个基类，否则可能导致严重的性能问题！
--asset和view都会缓存。请在回收前清空状态

local LodConst = require("LodConst")
local PoolUsage = require("PoolUsage")
local MapTileAsset = require("MapTileAsset")
local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle
local Zero = CS.UnityEngine.Vector3.zero
local One = CS.UnityEngine.Vector3.one
local Identity = CS.UnityEngine.Quaternion.identity

---@class MapTileAssetSolo : MapTileAsset
local MapTileAssetSolo = class("MapTileAssetSolo", MapTileAsset)

---@param go CS.UnityEngine.GameObject
---@param data MapTileAssetSolo
local function LoadCallback(go, data)
    if data ~= nil then
        data:PostLoaded()
        if data.fade then
            data:FadeIn(data:GetFadeInDuration())
        else
            data:FadeIn(0)
        end
    end
    
end

function MapTileAssetSolo:ctor()
    self.handle = PooledGameObjectHandle(PoolUsage.Map)
    self.lastPrefabName = string.Empty
    self.fade = false
end

function MapTileAssetSolo:GetEnableFadeOut()
    return true
end

function MapTileAssetSolo:GetEnableFadeIn()
    return true
end

---@return CS.UnityEngine.GameObject
function MapTileAssetSolo:GetAsset()
    return self.handle.Asset
end

function MapTileAssetSolo:GetPriority()
    return 0
end

function MapTileAssetSolo:GetSyncCreate()
    return false
end

function MapTileAssetSolo:GetSyncLoad()
    return false
end

---@return CS.UnityEngine.Vector3
function MapTileAssetSolo:GetPosition()
    -- 重载此函数
    return Zero
end

---@return CS.UnityEngine.Quaternion
function MapTileAssetSolo:GetRotation()
    -- 重载此函数
    return Identity
end

---@return CS.UnityEngine.Vector3
function MapTileAssetSolo:GetScale()
    -- 重载此函数
    return One
end

function MapTileAssetSolo:GetFadeOutDuration()
    return 0.2
end

function MapTileAssetSolo:GetFadeInDuration()
    return 0.2
end

function MapTileAssetSolo:Show()
    self:OnShow()
    self:ShowInternal(self:GetEnableFadeIn())
end

function MapTileAssetSolo:Hide()
    self:HideInternal(self:GetEnableFadeOut())
    self:OnHide()
end

function MapTileAssetSolo:Release()
    if self.handle then
        self.handle:Delete()
    end
    self.handle = nil
end

function MapTileAssetSolo:OnLodChanged(oldLod, newLod)
    local prefabName = self:GetPrefabName()
    if string.IsNullOrEmpty(self.lastPrefabName) then
        if not string.IsNullOrEmpty(prefabName) then
            self:ShowInternal(self:GetEnableFadeIn())
        end
    else
        if string.IsNullOrEmpty(prefabName) then
            self:HideInternal(self:GetEnableFadeOut())
        else
            if self.lastPrefabName ~= prefabName then
                self:HideInternal(self:GetEnableFadeOut())
                self:ShowInternal(self:GetEnableFadeIn())
            else
                self:OnConstructionUpdate()
            end
        end
    end
end

function MapTileAssetSolo:OnTerrainLoaded()
    if self.handle and self.handle.Loaded then
        local asset = self:GetAsset()
        local position = self:GetPosition()
        if position then
            asset.transform.position = position 
        end
    end
end

function MapTileAssetSolo:GetSortingOrder()
    return 0
end

function MapTileAssetSolo:Refresh()
    local prefabName = self:GetPrefabName()
    if string.IsNullOrEmpty(self.lastPrefabName) then
        if not string.IsNullOrEmpty(prefabName) then
            self:ShowInternal(self:GetEnableFadeIn())
        end
    else
        if string.IsNullOrEmpty(prefabName) then
            self:HideInternal(self:GetEnableFadeOut())
        else
            if self.lastPrefabName ~= prefabName then
                self:HideInternal(false)
                self:ShowInternal(self:GetEnableFadeIn())
            else
                self:OnConstructionUpdate()
            end
        end
    end
end

function MapTileAssetSolo:CanShow()
    return true
end

if UNITY_DEBUG then
MapTileAssetSolo.CSTypeCache = nil
MapTileAssetSolo.CheckParamResult = nil

local CheckTypeIs = function(target, luaType, csType)
    if nil == target then return 1 end
    if type(target) ~= luaType then return 2 end
    if not csType then return end
    if not target.GetType then return 3 end
    local targetType = target:GetType()
    if targetType ~= csType then return 4,targetType end
end

local printCheckTypeError = function(ownerType, paramName, checkCode, targetCSType, CheckParamResult)
    g_Logger.Error("%s param:%s check failed:%s, csType:%s",ownerType, paramName, CheckParamResult[checkCode], targetCSType)
end

function MapTileAssetSolo:CheckGenerateObjectParamDebug(prefabName, position, rotation, scale, priority, syncCreate, syncLoad)
    if not MapTileAssetSolo.CSTypeCache then
        MapTileAssetSolo.CSTypeCache = {
            Transform = typeof(CS.UnityEngine.Transform),
            Vector3 = typeof(CS.UnityEngine.Vector3),
            Quaternion = typeof(CS.UnityEngine.Quaternion),
        }
    end
    if not MapTileAssetSolo.CheckParamResult then
        MapTileAssetSolo.CheckParamResult = {
            [1] = "Target is nil",
            [2] = "Target lua type not match",
            [3] = "Target has none GetType function",
            [4] = "Target CS TypeNotMatch"
        }
    end
    local hasError = false
    local ret,csT = CheckTypeIs(position, "userdata", MapTileAssetSolo.CSTypeCache.Vector3)
    if ret then
        hasError = true
        printCheckTypeError(GetClassName(self), "position", ret, csT, MapTileAssetSolo.CheckParamResult)
    end
    ret,csT = CheckTypeIs(rotation, "userdata", MapTileAssetSolo.CSTypeCache.Quaternion)
    if ret then
        hasError = true
        printCheckTypeError(GetClassName(self), "rotation", ret, csT, MapTileAssetSolo.CheckParamResult)
    end
    ret,csT = CheckTypeIs(scale, "userdata", MapTileAssetSolo.CSTypeCache.Vector3)
    if ret then
        hasError = true
        printCheckTypeError(GetClassName(self), "scale", ret, csT, MapTileAssetSolo.CheckParamResult)
    end
    ret,csT = CheckTypeIs(priority, "number")
    if ret then
        hasError = true
        printCheckTypeError(GetClassName(self), "priority", ret, csT, MapTileAssetSolo.CheckParamResult)
    end
    ret,csT = CheckTypeIs(syncCreate, "boolean")
    if ret then
        hasError = true
        printCheckTypeError(GetClassName(self), "syncCreate", ret, csT, MapTileAssetSolo.CheckParamResult)
    end
    ret,csT = CheckTypeIs(syncLoad, "boolean")
    if ret then
        hasError = true
        printCheckTypeError(GetClassName(self), "syncLoad", ret, csT, MapTileAssetSolo.CheckParamResult)
    end
    if hasError then
        g_Logger.Error("GenerateObject param has error, prefabName:%s", prefabName)
    end
end
end

function MapTileAssetSolo:GenerateObject(fade)
    if self.handle.Idle then
        local mapSystem = self:GetMapSystem()
        self.lastPrefabName = self:GetPrefabName()
        local prefabName = self.lastPrefabName
        if not string.IsNullOrEmpty(prefabName) then
            self.fade = fade
            local parentTransform = mapSystem.Parent
            local position = self:GetPosition()
            local rotation = self:GetRotation()
            local scale = self:GetScale()
            local priority = self:GetPriority()
            local syncCreate = self:GetSyncCreate()
            local syncLoad = self:GetSyncLoad()
            if UNITY_DEBUG then
                self:CheckGenerateObjectParamDebug(prefabName, position, rotation, scale, priority, syncCreate, syncLoad)
            end
            position = position or CS.UnityEngine.Vector3.zero
            rotation = rotation or CS.UnityEngine.Quaternion.identity
            scale = scale or CS.UnityEngine.Vector3.one
            priority = priority or 0
            syncCreate = syncCreate or false
            syncLoad = syncLoad or false
            self.handle:Create(prefabName, parentTransform, position, rotation, scale, LoadCallback, self, priority, syncCreate, syncLoad)
        end
    end
end

---@private
function MapTileAssetSolo:GetPrefabName()
    local mapSystem = self:GetMapSystem()
    local lod = mapSystem.Lod
    if lod <= LodConst.Lod0 then
        return self:GetLodPrefab(0)
    end
    if lod <= LodConst.Lod1 then
        return self:GetLodPrefab(1)
    end
    if lod <= LodConst.Lod2 then
        return self:GetLodPrefab(2)
    end
    if lod <= LodConst.Lod3 then
        return self:GetLodPrefab(3)
    end
    if lod <= LodConst.Lod4 then
        return self:GetLodPrefab(4)
    end
    if lod <= LodConst.Lod5 then
        return self:GetLodPrefab(5)
    end
    if lod <= LodConst.Lod6 then
        return self:GetLodPrefab(6)
    end
    return self:GetLodPrefab(7)
end

function MapTileAssetSolo:GetLodPrefab(lod)
    return string.Empty
end

function MapTileAssetSolo:PostLoaded()
    self:OnConstructionSetup()
end

function MapTileAssetSolo:ShowInternal(fade)
    if not self:CanShow() then
        self:HideInternal(false)
    else
        self:GenerateObject(fade)
    end
end

function MapTileAssetSolo:HideInternal(fade)
    self:OnConstructionShutdown()

    if fade then
        self:FadeOut(self:GetFadeOutDuration())
        self.handle:Delete(self:GetFadeOutDuration())
    else
        self.handle:Delete()
    end
    self.lastPrefabName = string.Empty
end

function MapTileAssetSolo:FadeOut(duration)
    -- 重载此函数
end

function MapTileAssetSolo:FadeIn(duration)
    -- 重载此函数
end

function MapTileAssetSolo:OnShow()

end

function MapTileAssetSolo:OnHide()

end

function MapTileAssetSolo:OnConstructionUpdate()
    -- 重载此函数
end

function MapTileAssetSolo:OnConstructionShutdown()
    -- 重载此函数
end

function MapTileAssetSolo:OnConstructionSetup()
    -- 重载此函数
end

return MapTileAssetSolo