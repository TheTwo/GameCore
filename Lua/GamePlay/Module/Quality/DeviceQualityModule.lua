local BaseModule = require("BaseModule")
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local Delegate = require('Delegate')

local PerformanceHelper = CS.DragonReborn.Performance.PerformanceHelper
local Screen = CS.UnityEngine.Screen
local Shader = CS.UnityEngine.Shader
local QualitySettings = CS.UnityEngine.QualitySettings
local DeviceLevel = CS.DragonReborn.Performance.DeviceLevel
local AntialiasingMode = CS.UnityEngine.Rendering.Universal.AntialiasingMode
local RenderPiplineUtil = CS.RenderPiplineUtil

--按比例设置完的screenwidth
local ScreenWidth

---@class DeviceQualityModule
local cls = class("DeviceQualityModule", BaseModule)

function cls:OnRegister()
    -- 重载此函数
    g_Game.EventManager:AddListener(EventConst.OPEN_3D_SHOW_UI, Delegate.GetOrCreate(self, self.OnHeroUIOpened))
    g_Game.EventManager:AddListener(EventConst.CLOSE_3D_SHOW_UI, Delegate.GetOrCreate(self, self.OnHeroUIClosed))
    g_Game.EventManager:AddListener(EventConst.KINGDOM_TRANSITION_START, Delegate.GetOrCreate(self, self.OnKingdomTransitionStart))
    g_Game.EventManager:AddListener(EventConst.KINGDOM_TRANSITION_END, Delegate.GetOrCreate(self, self.OnKingdomTransitionEnd))
end

function cls:OnRemove()
    -- 重载此函数
    g_Game.EventManager:RemoveListener(EventConst.OPEN_3D_SHOW_UI, Delegate.GetOrCreate(self, self.OnHeroUIOpened))
    g_Game.EventManager:RemoveListener(EventConst.CLOSE_3D_SHOW_UI, Delegate.GetOrCreate(self, self.OnHeroUIClosed))
    g_Game.EventManager:RemoveListener(EventConst.KINGDOM_TRANSITION_START, Delegate.GetOrCreate(self, self.OnKingdomTransitionStart))
    g_Game.EventManager:RemoveListener(EventConst.KINGDOM_TRANSITION_END, Delegate.GetOrCreate(self, self.OnKingdomTransitionEnd))
end

function cls:Release()
    -- 重载此函数
end

function cls:OnHeroUIOpened()
    if not self.qualityConfig then return end

    self:SetRenderScale(self.qualityConfig:HighLevelResolution())
    self:SetShadowResolution(self.qualityConfig:ShadowResolution())
end

function cls:OnHeroUIClosed()
    if not self.qualityConfig then return end

    self:SetRenderScale(self.qualityConfig:CameraResolution())
    self:SetShadowResolution(self.qualityConfig:ShadowResolution())
end

function cls:OnKingdomTransitionStart()
    if not self.qualityConfig then return end

    self:SetRenderScale(self.qualityConfig:ScreenResolution())
    self:SetShadowResolution(self.qualityConfig:ShadowResolution())
end

function cls:OnKingdomTransitionEnd()
    if not self.qualityConfig then return end

    self:SetRenderScale(self.qualityConfig:CameraResolution())
    self:SetShadowResolution(self.qualityConfig:ShadowResolution())
end

-- add your quality logic
---@param qualityConfig QualityLevelConfigCell
function cls:UpdateQualitySettings(qualityConfig)
    self.qualityConfig = qualityConfig

    local qualityLevel = qualityConfig:QualityNumber()
    QualitySettings.SetQualityLevel(qualityLevel, true)
    Shader.globalMaximumLOD = qualityConfig:ShaderLod()
    QualitySettings.lodBias = qualityConfig:LodBias()
    self:SetScreenResolution(qualityConfig:ScreenResolution())
    self:SetRenderScale(qualityConfig:CameraResolution(), qualityConfig:ScreenResolution())
    self:SetShadowResolution(qualityConfig:ShadowResolution())
    self:SetAllowHDR(qualityConfig:AllowHDR() == 1 and true or false)
end

-- add your quality logic (after game scene loaded)
---@param qualityConfig QualityLevelConfigCell
function cls:UpdateEnterSceneQualitySetting(qualityConfig)
    local camera = KingdomMapUtils.GetBasicCamera().mainCamera
    PerformanceHelper.SetBloomNumOfPass(camera, qualityConfig:BloomIterationTimes())
end

function cls:SetShadowResolution(resolution)
    RenderPiplineUtil.SetMainLightShadowmapResolution(resolution)
end

function cls:SetAllowHDR(allowHDR)
    RenderPiplineUtil.SetAllowHDR(allowHDR)
end

function cls:SetScreenResolution(resolution)
    if not UNITY_ANDROID and not UNITY_IOS then
        ScreenWidth = Screen.width
        return Screen.width
    end
    
    local width = Screen.width
    local height = Screen.height
    local aspectRatio = height / width
    --以长度为尺，等比缩放
    if width > resolution then
        width = resolution
        height = CS.UnityEngine.Mathf.RoundToInt(resolution * aspectRatio)
        
        Screen.SetResolution(width, height, true)
    end
    ScreenWidth = width
end

function cls:SetRenderScale(maxCameraWidth,maxScreenWidth)
	if not UNITY_ANDROID and not UNITY_IOS then
		return
	end	
	
    local renderScale = 1.0
    local deviceScreenWidth = Screen.width;
    --实际根本不需要这层判断，直接设置scale就对了
    --此处应当是当前实际的screenWidth
    --if deviceScreenWidth >= maxScreenWidth then
    renderScale = maxCameraWidth * 1.0 / ScreenWidth;

    RenderPiplineUtil.SetRenderScale(renderScale)
    g_Logger.Log('[DeviceQualityModule] SetRenderScale %s, maxCameraWidth %s maxScreenWidth %s Sceen.with %s', renderScale, maxCameraWidth, maxScreenWidth, deviceScreenWidth)
end

return cls
