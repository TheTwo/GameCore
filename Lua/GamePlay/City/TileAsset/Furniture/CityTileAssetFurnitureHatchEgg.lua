local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetFurnitureHatchEgg:CityTileAsset
---@field new fun():CityTileAssetFurnitureHatchEgg
local CityTileAssetFurnitureHatchEgg = class("CityTileAssetFurnitureHatchEgg", CityTileAsset)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")

function CityTileAssetFurnitureHatchEgg:OnTileViewInit()
    self.furnitureId = self.tileView.tile:GetCell().singleId
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
end

function CityTileAssetFurnitureHatchEgg:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
end

function CityTileAssetFurnitureHatchEgg:GetPrefabName()
    if self:ShouldShow() then
        return self:GetPrefabNameByProcessInfo()
    end
    return string.Empty
end

function CityTileAssetFurnitureHatchEgg:OnFurnitureUpdate(city, batchEvt)
    if city ~= self:GetCity() then return end

    if not batchEvt.Change then return end
    if not batchEvt.Change[self.furnitureId] then return end
    self:ForceRefresh()
end

function CityTileAssetFurnitureHatchEgg:ShouldShow()
    local furnitureTile = self.tileView.tile
    local castleFurniture = furnitureTile:GetCastleFurniture()
    if castleFurniture == nil then return false end
    if castleFurniture.ProcessInfo == nil then return false end
    return castleFurniture.ProcessInfo.ConfigId > 0
end

function CityTileAssetFurnitureHatchEgg:GetPrefabNameByProcessInfo()
    local furnitureTile = self.tileView.tile
    local castleFurniture = furnitureTile:GetCastleFurniture()
    local recipeId = castleFurniture.ProcessInfo.ConfigId
    local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
    if processCfg then
        self.model, self.scale = ArtResourceUtils.GetItemAndScale(processCfg:Model())
        return self.model
    end
    return string.Empty
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetFurnitureHatchEgg:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end
    self.go = go
    local transform = go.transform
    local mainAssets = self.tileView:GetMainAssets()
    self.bindedGo = false
    for asset, _ in pairs(mainAssets) do
        local mainGo = self.tileView.gameObjs[asset]
        if Utils.IsNotNull(mainGo) then
            self:BindModelToMainAsset(mainGo)
            self.bindedGo = true
            break
        end
    end

    if not self.bindedGo then
        transform.localScale = CS.UnityEngine.Vector3.zero
    end
end

function CityTileAssetFurnitureHatchEgg:OnAssetUnload()
    self.go = nil
    self.bindedGo = nil
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetFurnitureHatchEgg:OnMainAssetLoaded(asset, go)
    if Utils.IsNull(self.go) then return end
    if self.bindedGo then return end

    self:BindModelToMainAsset(go)
end

function CityTileAssetFurnitureHatchEgg:GetScale()
    if self.scale == nil or self.scale == 0 then
        return 1
    end
    return self.scale
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetFurnitureHatchEgg:BindModelToMainAsset(go)
    local holder = go:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNull(holder) then return end

    ---@type CS.UnityEngine.Transform
    local anchorTrans = holder:GetAttachPoint('hatch_egg')
    if Utils.IsNull(anchorTrans) then return end

    local transform = self.go.transform
    transform:SetPositionAndRotation(anchorTrans.position, anchorTrans.rotation)
    transform.localScale = CS.UnityEngine.Vector3.one * self:GetScale()
end

return CityTileAssetFurnitureHatchEgg