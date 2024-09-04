local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local Utils = require("Utils")
local ArtResourceUtils = require("ArtResourceUtils")
local CityCitizenDefine = require("CityCitizenDefine")

---@class CityAssetCitizenSpawnPlace
---@field new fun():CityAssetCitizenSpawnPlace
---@field spawnRoot CS.UnityEngine.Transform
local CityAssetCitizenSpawnPlace = class('CityAssetCitizenSpawnPlace')

function CityAssetCitizenSpawnPlace:ctor()
    ---@type number
    self._citizenConfigId = nil
    self._citizenModel = nil
    self._modelAsset = nil
    self._modelScale = nil
    self._goCreator = GameObjectCreateHelper.Create()
    ---@type CityTrigger
    self._clickTriggerLua = nil
end

function CityAssetCitizenSpawnPlace:Init()

end

function CityAssetCitizenSpawnPlace:Release()
    self._goCreator:CancelAllCreate()
    if Utils.IsNotNull(self._citizenModel) then
        GameObjectCreateHelper.DestroyGameObject(self._citizenModel)
    end
    self._citizenConfigId = nil
    self._citizenModel = nil
    self._modelScale = nil
    self._modelAsset = nil
end

function CityAssetCitizenSpawnPlace:SpawnCitizen(citizenConfigId)
    if self._citizenConfigId == citizenConfigId then
        return
    end
    self._citizenConfigId = citizenConfigId
    self._goCreator:CancelAllCreate()
    if Utils.IsNotNull(self._citizenModel) then
        GameObjectCreateHelper.DestroyGameObject(self._citizenModel)
    end
    self._citizenModel = nil
    if not self._citizenConfigId then
        return
    end
    local cfg = ConfigRefer.Citizen:Find(self._citizenConfigId)
    if not cfg then
        return
    end
    self._modelAsset,self._modelScale = CityCitizenDefine.GetCitizenModelAndScaleByDeviceLv(cfg)
    if string.IsNullOrEmpty(self._modelAsset) then
        return
    end
    self._goCreator:Create(self._modelAsset, self.spawnRoot, Delegate.GetOrCreate(self, self.OnCitizenModelLoaded))
end

---@param go CS.UnityEngine.GameObject
function CityAssetCitizenSpawnPlace:OnCitizenModelLoaded(go)
    self._citizenModel = go
    if Utils.IsNull(go) then
        return
    end
    go:SetLayerRecursively("City")
    self._citizenModel.transform.localScale = CS.UnityEngine.Vector3.one * self._modelScale
end

return CityAssetCitizenSpawnPlace