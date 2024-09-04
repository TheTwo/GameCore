local CityConst = require("CityConst")
local Delegate = require("Delegate")
local BasicCamera = require("BasicCamera")

---@class CityAssetCameraZoom
---@field new fun():CityAssetCameraZoom
---@field scaleRoot CS.UnityEngine.Transform
---@field baseScale CS.UnityEngine.Vector3
local CityAssetCameraZoom = class('CityAssetCameraZoom')

function CityAssetCameraZoom:ctor()
    ---@type BasicCamera
    self._camera = nil
    self._manualSetCamera = false
    self._active = false
end

function CityAssetCameraZoom:OnEnable()
    self._active = true
    if self._manualSetCamera then
        return
    end
    self:AutoSetCityCamera()
end

function CityAssetCameraZoom:OnDisable()
    self._active = false
    if self._manualSetCamera then
        return
    end
    self:ClearCamera()
end

---@private
function CityAssetCameraZoom:AutoSetCityCamera()
    if not BasicCamera.CurrentBasicCamera then
        return
    end
    self:SetCamera(BasicCamera.CurrentBasicCamera)
end

---@param basicCamera BasicCamera
function CityAssetCameraZoom:ManualSetCamera(basicCamera)
    self:ClearCamera()
    self._manualSetCamera = true
    self:SetCamera(basicCamera)
end

function CityAssetCameraZoom:ManualClearCamera(restoreAuto)
    if not self._manualSetCamera then
        return
    end
    self:ClearCamera()
    if not restoreAuto then
        return
    end
    self._manualSetCamera = false
    if self._active then
        self:AutoSetCityCamera()
    end
end

---@private
---@param basicCamera BasicCamera
function CityAssetCameraZoom:SetCamera(basicCamera)
    if self._camera == basicCamera then
        return
    end
    local listener = Delegate.GetOrCreate(self, self.DoCameraBaseSizeChanged)
    if self._camera then
        self._camera:RemoveSizeChangeListener(listener)
    end
    self._camera = basicCamera
    local setSize = CityConst.CITY_NEAR_CAMERA_SIZE
    if self._camera then
        self._camera:AddSizeChangeListener(listener)
        setSize = self._camera:GetSize()
    end
    self:DoCameraBaseSizeChanged(nil, setSize)
end

---@private
function CityAssetCameraZoom:ClearCamera()
    if self._camera then
        local listener = Delegate.GetOrCreate(self, self.DoCameraBaseSizeChanged)
        self._camera:RemoveSizeChangeListener(listener)
    end
    self._camera = nil
end

---@param newValue number
function CityAssetCameraZoom:DoCameraBaseSizeChanged(_, newValue)
    local rate = math.max(0, math.min(newValue, CityConst.CITY_ASSET_CAMERA_ZOOM_MAX) / CityConst.CITY_ASSET_CAMERA_ZOOM_MIN)
    self.scaleRoot.localScale = self.baseScale * rate
    if self._camera then
        self.scaleRoot.rotation = self._camera.mainTransform.rotation
    end
end

return CityAssetCameraZoom