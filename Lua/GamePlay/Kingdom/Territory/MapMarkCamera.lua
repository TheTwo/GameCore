local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")

local RenderTexture = CS.UnityEngine.RenderTexture
local RenderTextureDescriptor = CS.UnityEngine.RenderTextureDescriptor
local RenderTextureFormat = CS.UnityEngine.RenderTextureFormat
local Color = CS.UnityEngine.Color
local GL = CS.UnityEngine.GL

---@class MapMarkCamera
---@field markCamera CS.UnityEngine.Camera
---@field markTransform CS.UnityEngine.Transform
---@field basicCamera BasicCamera
---@field mapSystem CS.Grid.MapSystem
---@field markRT CS.UnityEngine.RenderTexture
---@field enabled boolean
---@field isDirty boolean
local MapMarkCamera = class("MapMarkCamera")

function MapMarkCamera:Setup()
    KingdomMapUtils.GetKingdomScene():AddLodChangeListener(Delegate.GetOrCreate(self, self.OnLodChanged))
    self.enabled = true
end

function MapMarkCamera:ShutDown()
    KingdomMapUtils.GetKingdomScene():RemoveLodChangeListener(Delegate.GetOrCreate(self, self.OnLodChanged))

    self.isDirty = false
    RenderTexture.ReleaseTemporary(self.markRT)
end

function MapMarkCamera:OnLodChanged(oldLod, newLod)
    --if KingdomMapUtils.InMapNormalLod(newLod) then
    --    self:ClearMark()
    --    self.enabled = false
    --    ModuleRefer.KingdomInteractionModule:SetEnabled(false)
    --else
    --    self.enabled = true
    --    ModuleRefer.KingdomInteractionModule:SetEnabled(true)
    --end
end

function MapMarkCamera:SetDirty()
    self.isDirty = true
end

function MapMarkCamera:Update()
    --if not KingdomMapUtils.IsMapState() or not self.enabled then
    --    return
    --end
    --self:InitOnceCamera()
    --if self.basicCamera.hasChanged or self.isDirty then
    --    self.markTransform.position = self.mapSystem.CameraBox.Center
    --    self.markCamera.orthographicSize = self.mapSystem.CameraBox.Size.x / 2
    --    self.markCamera:Render()
    --    KingdomMapUtils.GetMapSystem():SetTerrainMarkRenderTexture(self.markRT)
    --    self.isDirty = false
    --end
end

function MapMarkCamera:ClearMark()
    --RenderTexture.active = self.markRT
    --GL.Clear(true, true, Color.clear);

end

function MapMarkCamera:InitOnceCamera()
    if not self.basicCamera then
        self.basicCamera = KingdomMapUtils.GetBasicCamera()
        self.mapSystem = KingdomMapUtils.GetMapSystem()

        self.markCamera.nearClipPlane = -1000
        self.markCamera.farClipPlane = 1000
        self.markCamera.aspect = 1
        self.markCamera.enabled = false
        self.markCamera.allowMSAA = false
        self.markCamera.clearFlags = CS.UnityEngine.CameraClearFlags.SolidColor
        self.markCamera.forceIntoRenderTexture = true

        local size = 1300
        local desc = RenderTextureDescriptor(size, size, RenderTextureFormat.ARGB32, 8)
        desc.msaaSamples = 1
        desc.sRGB = false
        desc.volumeDepth = 1
        self.markRT = RenderTexture.GetTemporary(desc)
        self.markRT.name = "Map Mark RT"
        self.markRT:Create()

        self.markCamera.targetTexture = self.markRT
    end
end

return MapMarkCamera