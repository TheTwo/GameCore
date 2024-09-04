local BaseModule = require("BaseModule")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local CameraConst = require("CameraConst")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local Utils = require("Utils")
local PoolUsage = require("PoolUsage")
local KingdomConstant = require("KingdomConstant")
local CircleMaskType = require("CircleMaskType")
local LayerMask = require("LayerMask")

local MapUtils = CS.Grid.MapUtils


---@class KingdomTransitionModule : BaseModule
---@field mapSystem CS.Grid.MapSystem
---@field basicCamera BasicCamera
---@field cameraLodData CameraLodData
---@field enableTransition boolean
---@field fullScreen FullScreenController
---@field lastLod number
---@field isCapturing boolean
local KingdomTransitionModule = class("KingdomTransitionModule", BaseModule)

function KingdomTransitionModule:Setup()
    self.enableTransition = true
    self.mapSystem = KingdomMapUtils.GetMapSystem()
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    self.cameraLodData = KingdomMapUtils.GetCameraLodData()
    self.fullScreen = self.basicCamera.fullScreenBehavior.Instance
    self.fullScreen:Initialize()
    
    self.planeDecorationSize = self.cameraLodData.planeDecorationSize
    self.symbolDecorationSize = self.cameraLodData:GetSizeByLod(KingdomMapUtils.GetStaticMapData().SymbolLod - 1)

    g_Game.EventManager:AddListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnCameraLodChanged))
    g_Game.EventManager:AddListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
end

function KingdomTransitionModule:ShutDown()
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnCameraLodChanged))
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))

    if self.fullScreen then
        self.fullScreen:Dispose()
        self.fullScreen = nil
    end
end

---@private
function KingdomTransitionModule:OnCameraLodChanged(oldLod, newLod)
    if not self.fullScreen or not self.cameraLodData then
        return
    end

    if KingdomMapUtils.MapTypeChanged(oldLod, newLod) then
        g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_TRANSITION_START, oldLod, newLod)
        if self.enableTransition then
            self.isCapturing = true
            self.fullScreen:End()
            self.fullScreen:Capture(function(rt)
                g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_TRANSITION_START_AFTER_CAPTURE, oldLod, newLod)
                self.isCapturing = false
                local newSize = self.cameraLodData:GetSize()
                self:ProcessCullingMask(newSize)
                self.fullScreen:Begin(rt, function()
                    g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_TRANSITION_END, oldLod, newLod)
                end)
            end)
        else
            g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_TRANSITION_START_AFTER_CAPTURE, oldLod, newLod)
            g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_TRANSITION_END, oldLod, newLod)
        end
    end

    self:SwitchMapFogCircles(oldLod, newLod)
    self:SwitchPostProcess(oldLod, newLod)
end

---@private
function KingdomTransitionModule:OnCameraSizeChanged(oldSize, newSize)
    if not self.cameraLodData then 
        return
    end
    local oldLod = self.cameraLodData:CalculateLod(oldSize)
    local newLod = self.cameraLodData:CalculateLod(newSize)
    if KingdomMapUtils.MapTypeChanged(oldLod, newLod) then
        return
    end
    if not self.isCapturing then
        self:ProcessCullingMask(newSize)
    end
end

---@private
function KingdomTransitionModule:ProcessCullingMask(size)
    if not self.mapSystem then
        return
    end
    local camera = self.basicCamera and self.basicCamera.mainCamera
    if not camera then
        return
    end

    self:DisableCullingMask(camera, LayerMask.Tile | LayerMask.Tile3D | LayerMask.Tile2D | LayerMask.MapTerrain | LayerMask.SymbolMap)
    if size < self.planeDecorationSize then
        self:EnableCullingMask(camera, LayerMask.Default | LayerMask.Tile | LayerMask.Tile3D | LayerMask.MapTerrain)
        self.mapSystem:SetFacingCamera(nil)
    elseif self.planeDecorationSize <= size and size < self.symbolDecorationSize then
        self:EnableCullingMask(camera, LayerMask.Default | LayerMask.Tile | LayerMask.Tile2D | LayerMask.MapTerrain)
        self.mapSystem:SetFacingCamera(camera)
    else
        self:EnableCullingMask(camera, LayerMask.Default | LayerMask.SymbolMap)
        self.mapSystem:SetFacingCamera(camera)
    end
end

---@param camera CS.UnityEngine.Camera
---@param mask number
function KingdomTransitionModule:EnableCullingMask(camera, mask)
    if Utils.IsNotNull(camera) then
        local cullingMask = camera.cullingMask
        camera.cullingMask = cullingMask | mask
    end
end

---@param camera CS.UnityEngine.Camera
---@param mask number
function KingdomTransitionModule:DisableCullingMask(camera, mask)
    if Utils.IsNotNull(camera) then
        local cullingMask = camera.cullingMask
        camera.cullingMask = cullingMask & (~mask)
    end
end

function KingdomTransitionModule:EnableTransition()
    self.enableTransition = true
end

function KingdomTransitionModule:DisableTransition()
    self.enableTransition = false
end

---@private
function KingdomTransitionModule:SwitchMapFogCircles(oldLod, newLod)
    local change = KingdomMapUtils.LodSwitched(oldLod, newLod, KingdomConstant.VeryHighLod)
    if change > 0 then
        ModuleRefer.MapFogModule:HideCircleMaskOfType(CircleMaskType.VillageInitialVisible)
    elseif change < 0 then
        ModuleRefer.MapFogModule:ShowCircleMaskOfType(CircleMaskType.VillageInitialVisible)
    end
end

---@private
function KingdomTransitionModule:SwitchPostProcess(oldLod, newLod)
    if not self.basicCamera then
        return
    end
    local camera = self.basicCamera.mainCamera
    if Utils.IsNull(camera) then
        return
    end
    local cameraData = camera:GetUniversalAdditionalCameraData()
    local change = KingdomMapUtils.LodSwitched(oldLod, newLod, KingdomConstant.SymbolLod)
    if change > 0 then
        cameraData.renderPostProcessingEnabled = false
    elseif change < 0 then
        cameraData.renderPostProcessingEnabled = true
    end
end



---@param camera BasicCamera
function KingdomTransitionModule:ZoomInMap(camera)
    local lodData = KingdomMapUtils.GetCameraLodData()
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(ModuleRefer.PlayerModule:GetCastle().MapBasics.Position)
    local anchoredPosition = MapUtils.CalculateCoordToTerrainPosition(tileX, tileZ, KingdomMapUtils.GetMapSystem())
    local enterSize = lodData.mapCameraEnterSize
    local mapCameraEnterNear = lodData.mapCameraEnterNear
    local mapCameraEnterFar = lodData.mapCameraEnterFar
    camera.mainCamera.nearClipPlane = mapCameraEnterNear
    camera.mainCamera.farClipPlane = mapCameraEnterFar
    camera.ignoreLimit = true
    camera:LookAt(anchoredPosition)
    camera:SetSize(enterSize)
    camera:ZoomTo(enterSize - CameraConst.TransitionMapSize, CameraConst.TransitionZoomDuration, function()
        KingdomMapUtils.GetBasicCamera().ignoreLimit = false
    end)
end

---@param city City
function KingdomTransitionModule:ZoomInCity(camera, city, size)
    local minSize, maxSize = city:GetCameraMaxSize()
    if size == nil then
        size = maxSize
    else
        size = math.clamp(size, minSize, maxSize)
    end
    camera:ForceGiveUpTween()
    camera.ignoreLimit = true
    camera:SetSize(maxSize + CameraConst.TransitionCitySize)
    camera:ZoomTo(size, CameraConst.TransitionZoomDuration, function()
        KingdomMapUtils.GetBasicCamera().ignoreLimit = false
    end)
end

function KingdomTransitionModule:ZoomOutCity(camera, city)
    local _, maxSize = city:GetCameraMaxSize()
    camera.ignoreLimit = true
    camera:SetSize(maxSize)
    camera:ZoomTo(maxSize + CameraConst.TransitionCitySize, CameraConst.TransitionZoomDuration, function()
        KingdomMapUtils.GetBasicCamera().ignoreLimit = false
    end)
end

function KingdomTransitionModule:ZoomOutMap(camera, callback)
    local lodData = KingdomMapUtils.GetCameraLodData()

    camera:ForceGiveUpTween()
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(ModuleRefer.PlayerModule:GetCastle().MapBasics.Position)
    local anchoredPosition = MapUtils.CalculateCoordToTerrainPosition(tileX, tileZ, KingdomMapUtils.GetMapSystem())
    local enterSize = lodData.mapCameraEnterSize
    local mapCameraEnterNear = lodData.mapCameraEnterNear
    local mapCameraEnterFar = lodData.mapCameraEnterFar
    camera.mainCamera.nearClipPlane = mapCameraEnterNear
    camera.mainCamera.farClipPlane = mapCameraEnterFar
    camera.ignoreLimit = true
    camera:LookAt(anchoredPosition)
    camera:SetSize(enterSize - CameraConst.TransitionMapSize)
    camera:ZoomTo(enterSize, CameraConst.TransitionZoomDuration, function()
        KingdomMapUtils.GetBasicCamera().ignoreLimit = false
        if callback then callback() end
    end)
end

return KingdomTransitionModule