local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetLegoUnit:CityTileAsset
---@field new fun():CityTileAssetLegoUnit
local CityTileAssetLegoUnit = class("CityTileAssetLegoUnit", CityTileAsset)
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Delegate = require("Delegate")
local Vector3 = CS.UnityEngine.Vector3
local Quaternion = CS.UnityEngine.Quaternion

---@param legoBuilding CityLegoBuilding
---@param blockCfgId number @LegoBlockConfigCell.Id
---@param style number @描述风格块的样式，ref LegoBlockArtMap
---@param indoor boolean @是否室内资源(室内材质会受到特殊参数影响)
function CityTileAssetLegoUnit:ctor(legoBuilding, blockCfgId, style, indoor)
    CityTileAsset.ctor(self)
    self.syncLoaded = true
    self.legoBuilding = legoBuilding
    self.blockCfg = ConfigRefer.LegoBlock:Find(blockCfgId)
    self.style = style
    self.indoor = indoor
    local modelCfgId = 0
    local blockArtMapCfg = ConfigRefer.LegoBlockArtMap:Find(self.style)
    if blockArtMapCfg then
        if indoor then
            modelCfgId = blockArtMapCfg:ModelIndoorPart()
        else
            modelCfgId = blockArtMapCfg:ModelOutsidePart()
        end
    end
    self.modelPath, self.scale = ArtResourceUtils.GetItemAndScale(modelCfgId)
    if self.scale == 0 then
        self.scale = 1
    end
end

function CityTileAssetLegoUnit:GetPrefabName()
    return self.modelPath or string.Empty
end

function CityTileAssetLegoUnit:GetScale()
    return self.scale or 1
end

---@param go CS.UnityEngine.GameObject
---@param userdata any
---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function CityTileAssetLegoUnit:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end
    self.go = go
    self.go.transform:SetPositionAndRotation(self:GetWorldPosition(), self:GetWorldRotation())

    self:CreateAttachedDecorationsAsset()
    self.originName = self.go.name
    self.go.name = ("%s:%d"):format(self:GetType(), self:GetInstanceId())
    if self.indoor then
        self:IndoorMaterial()
    end
end

function CityTileAssetLegoUnit:OnAssetUnload(go, fadeOut)
    if self.indoor then
        self:ClearIndoorMaterial()
    end

    self:DestroyAttachedDecorationsAsset()
    if Utils.IsNotNull(self.go) then
        self.go.name = self.originName
    end
    self.go = nil
end

function CityTileAssetLegoUnit:CreateAttachedDecorationsAsset()
    self.docorationHandles = {}
    local createHelper = self:GetCreateHelper()
    for _, v in pairs(self:GetDecorations(self.indoor)) do
        local handle = createHelper:Create(v.decorationPrefabName, self:GetDecorationAttachTrans(self.go.transform, v.pointName), Delegate.GetOrCreate(self, self.OnDecorationLoaded), v, 0, true, true)
        self.docorationHandles[v] = handle
    end
end

function CityTileAssetLegoUnit:DestroyAttachedDecorationsAsset()
    local createHelper = self:GetCreateHelper()
    for _, v in pairs(self.docorationHandles) do
        if Utils.IsNotNull(v.Asset) then
            local holder = v.Asset:GetComponent(typeof(CS.PrefabCustomInfoHolder))
            if Utils.IsNotNull(holder) then
                holder:ExitRoomMode()
            end
        end
        createHelper:Delete(v)
    end
    self.docorationHandles = nil
end

---@param go CS.UnityEngine.GameObject
---@param userdata any
---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function CityTileAssetLegoUnit:OnDecorationLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    if Utils.IsNull(self.go) then
        self:GetCreateHelper():Delete(handle)
        return
    end
    go.transform.localPosition = CS.UnityEngine.Vector3.zero
    local holder = go:GetComponent(typeof(CS.PrefabCustomInfoHolder))
    if Utils.IsNotNull(holder) then
        local roomLightColor = self.legoBuilding:GetRoomLightColor()
        local roomLightDir = self.legoBuilding:GetRoomLightDir()
        local roomGi = self.legoBuilding:GetRoomGi()
        holder:EnterRoomMode(roomLightColor, roomLightDir, roomGi)
    end
end

function CityTileAssetLegoUnit:GetDecorationAttachTrans(rootTrans, pointName)
    if string.IsNullOrEmpty(pointName) then
        return rootTrans
    end

    local script = rootTrans.gameObject:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNull(script) then
        return rootTrans
    end

    local point = script:GetAttachPoint(pointName)
    if Utils.IsNull(point) then
        return rootTrans
    end

    return point
end

function CityTileAssetLegoUnit:IndoorMaterial()
    local holder = self.go:GetComponent(typeof(CS.PrefabCustomInfoHolder))
    if Utils.IsNull(holder) then return end

    self.customInfoHolder = holder
    local roomLightColor = self.legoBuilding:GetRoomLightColor()
    local roomLightDir = self.legoBuilding:GetRoomLightDir()
    local roomGi = self.legoBuilding:GetRoomGi()
    self.customInfoHolder:EnterRoomMode(roomLightColor, roomLightDir, roomGi)
end

function CityTileAssetLegoUnit:ClearIndoorMaterial()
    if Utils.IsNull(self.customInfoHolder) then return end

    self.customInfoHolder:ExitRoomMode()
    self.customInfoHolder = nil
end

function CityTileAssetLegoUnit:GetWorldPosition()
    return Vector3.zero
end

function CityTileAssetLegoUnit:GetWorldRotation()
    return Quaternion.identity
end

---@return CityLegoAttachedDecoration[]
function CityTileAssetLegoUnit:GetDecorations(indoor)
    return {}
end

function CityTileAssetLegoUnit:Refresh()
    if Utils.IsNull(self.go) then return end

    self.go.transform:SetPositionAndRotation(self:GetWorldPosition(), self:GetWorldRotation())
end

function CityTileAssetLegoUnit:GetInstanceId()
    return self.blockCfg:Id()
end

function CityTileAssetLegoUnit:GetType()
    return "积木"
end

return CityTileAssetLegoUnit