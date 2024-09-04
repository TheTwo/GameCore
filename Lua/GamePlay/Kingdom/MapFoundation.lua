local Utils = require("Utils")
local CameraSettingsSetter = require("CameraSettingsSetter")
local CameraLodData = require("CameraLodData")
local CameraPlaneData = require("CameraPlaneData")
local KingdomConstant = require("KingdomConstant")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")

local MapSystem = CS.Grid.MapSystem
local StaticMapData = CS.Grid.StaticMapData
local LuaTileViewFactory = CS.Grid.LuaTileViewFactory
local LuaRequestService = CS.Grid.LuaRequestService
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper


---@class MapFoundation
---@field root CS.UnityEngine.Transform
---@field camera CS.UnityEngine.Camera
---@field cameraLodData CameraLodData
---@field cameraPlaneData CameraPlaneData
---@field basicCamera BasicCamera
---@field mapMarkCamera MapMarkCamera
---@field staticMapData CS.Grid.StaticMapData
---@field mapSystem CS.Grid.MapSystem
---@field lastSize number
---@field lastLod number
---@field cameraBox CS.DragonReborn.AABB
---@field cameraBoxFrame number
local MapFoundation = class("MapFoundation")
MapFoundation.MapName = "v3"
MapFoundation.HideObject = false

---@param mapName string
---@param root CS.UnityEngine.GameObject
---@param tileViewFactory any
---@param kingdomViewFactory any
---@param requestService any
---@param sliceLevelBias number
function MapFoundation:Setup(mapName, root, tileViewFactory, kingdomViewFactory, requestService, globalOffset, sliceLevelBias)
    if Utils.IsNull(root) then
        return
    end
    
    self.root = root
    local basicCameraComp = root:GetLuaBehaviourInChildren("BasicCamera", true)
    self.basicCamera = basicCameraComp.Instance
    self.cameraLodData = CameraLodData.new(self.basicCamera)
    self.cameraPlaneData = CameraPlaneData.new(self.basicCamera)
    self.mapMarkCamera = root:GetLuaBehaviourInChildren("MapMarkCamera", true).Instance
    CameraSettingsSetter.Set(self.basicCamera.settings, self.basicCamera, self.cameraLodData, self.cameraPlaneData)
    self.camera = self.basicCamera.mainCamera
    CS.U2DFacingCamera.MainCamera = self.camera
    self.cameraLodData:Initialize()
    self.cameraPlaneData:Initialize()
    self.mapMarkCamera:Setup()
    self.audio_listener_go = nil

    self.staticMapData = StaticMapData()
    self.staticMapData:Load(mapName, sliceLevelBias, KingdomConstant.SymbolLod)
    
    globalOffset = globalOffset or CS.UnityEngine.Vector2.zero
    self.mapSystem = MapSystem(self.staticMapData, tileViewFactory, kingdomViewFactory, requestService, self.root.transform, globalOffset, MapFoundation.HideObject)

    local audioListener = basicCameraComp.transform:Find("audio_listener")
    if Utils.IsNotNull(audioListener) then
        self.audio_listener_go = audioListener
        g_Game.SoundManager:SetSceneListener(audioListener)
    end
    
    g_Game.EventManager:AddListener(EventConst.BASIC_CAMERA_SETTING_REFRESH, Delegate.GetOrCreate(self, self.OnSettingRefresh))
end

function MapFoundation:ShutDown()
    g_Game.EventManager:RemoveListener(EventConst.BASIC_CAMERA_SETTING_REFRESH, Delegate.GetOrCreate(self, self.OnSettingRefresh))
    if self.mapMarkCamera ~= nil then
        self.mapMarkCamera:ShutDown()
        self.mapMarkCamera = nil
    end
    
    if self.mapSystem ~= nil then
        self.mapSystem:Release()
        self.mapSystem = nil
    end

    if self.cameraLodData ~= nil then
        self.cameraLodData:Release()
        self.cameraLodData = nil
    end

    if self.cameraPlaneData ~= nil then
        self.cameraPlaneData:Release()
        self.cameraPlaneData = nil
    end

    self.camera = nil
    if self.basicCamera then
        self.basicCamera:Release()
        self.basicCamera = nil
    end

    if self.staticMapData ~= nil then
        self.staticMapData:Release()
        self.staticMapData = nil
    end
    self.audio_listener_go = nil

    if Utils.IsNotNull(self.root) then
        GameObjectCreateHelper.DestroyGameObject(self.root)
        self.root = nil
    end

    g_Game.SoundManager:SetSceneListener(nil)
end

function MapFoundation:Tick(dt)
    if self.mapSystem and self.cameraLodData and Utils.IsNotNull(self.camera) then
        local size = self.cameraLodData:GetSize()
        --if not self.lastSize then
        --    self.lastSize = size
        --end
        local lod = self.cameraLodData:GetLod()
        if not self.lastLod then
            self.lastLod = lod
        end

        local enableTransition = ModuleRefer.KingdomTransitionModule.enableTransition
        if not enableTransition or not KingdomMapUtils.MapTypeChanged(self.lastLod, lod) then
            self.mapSystem:UpdateCamera(self.camera, lod, size, dt)
        end

        
        CS.Lod.SceneCameraUtils.Lod = lod
        CS.Lod.SceneCameraUtils.Size = size

        if self.lastLod ~= lod then
            g_Game.EventManager:TriggerEvent(EventConst.CAMERA_LOD_CHANGED, self.lastLod, lod)
        end
        self.lastLod = lod

        --if self.lastSize ~= size then
        --    g_Game.EventManager:TriggerEvent(EventConst.CAMERA_SIZE_CHANGED, self.lastSize, size)
        --    g_Logger.Log("size change: lod=%s, size=%s", lod, size)
        --end
        --self.lastSize = size
        
    end
end

function MapFoundation:OnSettingRefresh()
    if not self.basicCamera then return end
    if not self.cameraLodData then return end
    if not self.cameraPlaneData then return end

    CameraSettingsSetter.Set(self.basicCamera.settings, self.basicCamera, self.cameraLodData, self.cameraPlaneData)
end

---@return CS.Grid.StaticMapData
function MapFoundation.LoadStaticMapData()
    local qualityLevel = g_Game.PerformanceLevelManager.qualityLevelConfig:MapSliceLevelBias()
    local staticMapData = StaticMapData()
    staticMapData:Load(MapFoundation.MapName, qualityLevel, KingdomConstant.SymbolLod)
    return staticMapData
end

---@param staticMapData CS.Grid.StaticMapData
function MapFoundation.UnloadStaticMapData(staticMapData)
    staticMapData:Release()
end

---@return CS.DragonReborn.AABB
function MapFoundation:GetCameraBox()
    local frame = g_Game.Time.frameCount
    if frame ~= self.cameraBoxFrame then
        self.cameraBox = self.mapSystem.CameraBox
        self.cameraBoxFrame = frame
    end
    return self.cameraBox
end

function MapFoundation:UpdateSceneAudioListenerPos(vec3Pos)
    if Utils.IsNull(self.audio_listener_go) then
        return
    end
    if not vec3Pos then
        self.audio_listener_go.transform.localPosition = CS.UnityEngine.Vector3.zero
    else
        self.audio_listener_go.transform.position = vec3Pos
    end
end

return MapFoundation
