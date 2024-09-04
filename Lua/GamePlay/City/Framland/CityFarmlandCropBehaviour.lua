local ArtResourceUtils = require("ArtResourceUtils")
local Delegate = require("Delegate")

---@class CityFarmlandCropBehaviour
---@field new fun():CityFarmlandCropBehaviour
---@field go CS.UnityEngine.GameObject
---@field growPhaseAnim CS.UnityEngine.Animation
---@field phase_1_root CS.UnityEngine.Transform
---@field phase_2_root CS.UnityEngine.Transform
---@field phase_3_root CS.UnityEngine.Transform
local CityFarmlandCropBehaviour = sealedClass('CityFarmlandCropBehaviour')

function CityFarmlandCropBehaviour:ctor()
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._handle1 = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._handle2 = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._handle3 = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self._goCreator = nil
    ---@type number
    self._cropId = nil
end

---@param goCreator CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
function CityFarmlandCropBehaviour:Init(goCreator)
    self._goCreator = goCreator
end

function CityFarmlandCropBehaviour:ReleaseCrop()
    self._cropId = nil
    if self._handle1 then
        self._handle1:Delete()
    end
    if self._handle2 then
        self._handle2:Delete()
    end
    if self._handle3 then
        self._handle3:Delete()
    end
    self._handle1 = nil
    self._handle2 = nil
    self._handle3 = nil
end

---@param value number @[0.0~1.0]
function CityFarmlandCropBehaviour:SetCropGrowingProcess(value)
    self._value = value
    self.growPhaseAnim:SetCurrentAnimationNormalizedTime(value)
    self.growPhaseAnim:Sample()
end

---@param cropConfig CropConfigCell
function CityFarmlandCropBehaviour:SetCropTid(cropId, cropConfig)
    if self._cropId and self._cropId == cropId then
        return
    end
    if not self._cropId or self._cropId ~= cropId then
        self:ReleaseCrop()
    end
    self._cropId = cropId
    if not cropConfig then
        return
    end
    local callBack = Delegate.GetOrCreate(self, self.OnCropAssetLoaded)
    self._handle1 = self._goCreator:Create(ArtResourceUtils.GetItem(cropConfig:CropModel1()), self.phase_1_root, callBack)
    self._handle2 = self._goCreator:Create(ArtResourceUtils.GetItem(cropConfig:CropModel2()), self.phase_2_root, callBack)
    self._handle3 = self._goCreator:Create(ArtResourceUtils.GetItem(cropConfig:CropModel3()), self.phase_3_root, callBack)
end

function CityFarmlandCropBehaviour:SetActive(active)
    self.go:SetVisible(active)
end

function CityFarmlandCropBehaviour:OnEnable()
    if self._value then
        self.growPhaseAnim:PlayAnimationClipEx(self.growPhaseAnim.clip.name, 0, self._value)
        self.growPhaseAnim:Sample()
    else
        self.growPhaseAnim:PlayAnimationClipEx(self.growPhaseAnim.clip.name, 0, 0)
        self.growPhaseAnim:Sample()
    end
end

function CityFarmlandCropBehaviour:OnCropAssetLoaded(go, userData)
    
end

return CityFarmlandCropBehaviour