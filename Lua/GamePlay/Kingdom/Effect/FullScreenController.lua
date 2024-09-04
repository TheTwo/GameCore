local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local EventConst = require("EventConst")
local Utils = require("Utils")

local Color = CS.UnityEngine.Color
local RenderTexture = CS.UnityEngine.RenderTexture
local RTHandles = CS.UnityEngine.Rendering.RTHandles
local Screen = CS.UnityEngine.Screen
local Graphics = CS.UnityEngine.Graphics
local UniversalRenderPipeline = CS.UnityEngine.Rendering.Universal.UniversalRenderPipeline

---@class FullScreenController
---@field gameObject CS.UnityEngine.GameObject
---@field renderer CS.UnityEngine.MeshRenderer
---@field rt CS.UnityEngine.RenderTexture
---@field timer number
---@field duration number
---@field feature CS.RenderExtension.FullScreenUIFeature
---@field settings CS.Kingdom.MapHUDSettings
---@field cameraSize number
---@field transitionEndCallback
local FullScreenController = class("FullScreenController")

function FullScreenController:Initialize()
    self.feature = KingdomMapUtils.GetBasicCamera().mainCamera:GetCameraRendererFeature(typeof(CS.RenderExtension.FullScreenFeature), "SceneGrab")
    self.settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Kingdom.MapHUDSettings))
end

function FullScreenController:Dispose()
    self.transitionEndCallback = nil
    self:End()
    if self.feature then
        self.feature:SetOnComplete(nil)
    end
    self.feature = nil
    self.settings = nil
end

---@private
---@param captureEndCallback fun(tex:CS.UnityEngine.RenderTexture)
function FullScreenController:Capture(captureEndCallback)
    if Utils.IsNotNull(self.feature) then
        local rtW = Screen.width;
        local rtH = Screen.height;
        local rt = RenderTexture.GetTemporary(rtW, rtH, 0,CS.RenderPiplineUtil.MakeRenderTextureGraphicsFormat(true, false))
        self.feature.BlurTex = RTHandles.Alloc(rt)
        self.feature:SetActive(true)
        self.feature:EnableCopy(true)
        self.feature:SetOnComplete(function()
            if Utils.IsNotNull(self.feature) then
                self.feature:SetActive(false)
            end
            captureEndCallback(rt)
        end)
    end
end

---@param rt CS.UnityEngine.RenderTexture
function FullScreenController:Begin(rt, transitionEndCallback)
    if Utils.IsNotNull(self.rt) then
        RenderTexture.ReleaseTemporary(self.rt)
        self.rt = nil
    end
    self.rt = rt
    
    self.renderer.sharedMaterial:SetTexture("_MainTex", rt)
    self.cameraSize = KingdomMapUtils.GetBasicCamera():GetSize()
    self.timer = self.settings.LodTransitionDuration
    self.transitionEndCallback = transitionEndCallback
    self:SetColor(Color.clear)
    self.gameObject:SetActive(true)

    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    
    --g_Logger.Error("begin -> " .. rt.name)
end

function FullScreenController:End()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    
    self.gameObject:SetActive(false)
    if Utils.IsNotNull(self.rt) then
        RenderTexture.ReleaseTemporary(self.rt)
        self.rt = nil
    end

    if self.transitionEndCallback then
        self.transitionEndCallback()
    end
end

function FullScreenController:Tick(dt)
    if not self.timer or self.timer <= 0 then
        return
    end

    if Utils.IsNotNull(self.rt) then
        self.timer = self.timer - dt
        local alpha = self.timer / self.settings.LodTransitionDuration
        self:SetColor(Color(1, 1, 1, alpha))
    else
        self:SetColor(Color.clear)
    end

    if self.timer <= 0 then
        self:End()
    end
end

function FullScreenController:OnCameraSizeChanged(oldSize, newSize)
    if math.abs(newSize - self.cameraSize) > self.settings.LodCameraSizeChangeThreshold then
        self:End()
    end
end

function FullScreenController:SetColor(color)
    self.renderer.sharedMaterial:SetColor("_Color", color)
end

return FullScreenController