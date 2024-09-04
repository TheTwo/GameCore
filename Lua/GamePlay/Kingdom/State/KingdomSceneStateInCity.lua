local KingdomSceneState = require("KingdomSceneState")
local CityCameraSettingsSetter = require("CityCameraSettingsSetter")
local ShadowDistanceControl = require("ShadowDistanceControl")
local URPRendererList = require("URPRendererList")
local KingdomMapUtils = require("KingdomMapUtils")
local ManualResourceConst = require("ManualResourceConst")
local SceneBgmUsage = require("SceneBgmUsage")
local CloudUtils = require("CloudUtils")
local ConfigRefer = require("ConfigRefer")
local FovControl = require("FovControl")
local UIMediatorNames = require("UIMediatorNames")
local CanUnlockFogMarkerGroup = require("CanUnlockFogMarkerGroup")
local TimerUtility = require("TimerUtility")
local CityCameraSizeRule = require("CityCameraSizeRule")
local CityConst = require("CityConst")
local CityCameraLodRule = require("CityCameraLodRule")
local Utils = require("Utils")

---@class KingdomSceneStateInCity:KingdomSceneState
---@field city City|MyCity
---@field new fun(kingdomScene:KingdomScene):KingdomSceneStateInCity
local KingdomSceneStateInCity = class("KingdomSceneStateInCity", KingdomSceneState)
KingdomSceneStateInCity.Name = "KingdomSceneStateInCity"

local Delegate = require("Delegate")
local DeviceUtil = require("DeviceUtil")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local HUDConst = require("HUDConst")

function KingdomSceneStateInCity:ctor(kingdomScene)
    KingdomSceneState.ctor(self, kingdomScene)
    self.cityCameraSizeRule = CityCameraSizeRule.new()
    self.cityCameraLodRule = CityCameraLodRule.new()
    self._markerInitState = nil
end

function KingdomSceneStateInCity:Enter()
    KingdomSceneState.Enter(self)

    self.city = self.stateMachine:ReadBlackboard("City")
    local cameraData = self.kingdomScene.basicCamera.cameraDataPerspective
    self.maxSizeCache = cameraData.maxSize
    self.minSizeCache = cameraData.minSize
    -- self.cityCameraSizeRule:Initialize(self.kingdomScene.basicCamera)
    self.cityCameraLodRule:Initialize(self.kingdomScene.basicCamera)
    self:SetCameraSize()

    local HashSetString = CS.System.Collections.Generic.HashSet(typeof(CS.System.String))
    local set = HashSetString()
    set:Add(ManualResourceConst.city_camera_settings)
    g_Game.AssetManager:EnsureSyncLoadAssets(set, true, Delegate.GetOrCreate(self, self.OnCameraSettingReady))

    self.kingdomScene.basicCamera.mainCamera:GetUniversalAdditionalCameraData():SetRenderer(URPRendererList.City)
    self.city:SetupFogRenderFeature(self.kingdomScene.basicCamera.mainCamera:GetCameraRendererFeature(typeof(CS.RenderExtension.WarFogFeature)))

    self.kingdomScene.mediator.cameraSizeRule:SetBlock(true)
    if not self.stateMachine:ReadBlackboard("SkipMoveCamera") then
        self.kingdomScene.basicCamera:MoveCameraOffset(self.city:WorldOffset())
    end
    --- 美术希望城外也显示，暂不关闭
    self.kingdomScene.basicCamera:SetSunlightEnable(true)
    self.city:OnCameraLoaded(self.kingdomScene.basicCamera)
    self.city:SetActive(true)
    self.kingdomScene.basicCamera:AddSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChanged))
    if UNITY_DEBUG and UNITY_EDITOR then
        g_Game:AddOnDrawGizmos(Delegate.GetOrCreate(self.city, self.city.OnGizmos))
    end

    if self.city:IsMyCity() then
        ModuleRefer.GamePlaySequenceModule:StartSequence_EnterMyCity(self.kingdomScene,self.city)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CAMERA_TWEEN_TO_DEFAULT_VIEWPORT)
    end
    g_Game.EventManager:TriggerEvent(EventConst.HUD_STATE_CHANGED, HUDConst.HUD_STATE.CITY)
    local sizeArray = {}
    for i = 1, ConfigRefer.CityConfig:CityCameraSizeListLength() do
        local value = ConfigRefer.CityConfig:CityCameraSizeList(i)
        table.insert(sizeArray, value)
    end
    local shadowDistanceList = { }
    for i = 1, ConfigRefer.CityConfig:CityShadowDistanceListLength() do
        table.insert(shadowDistanceList, ConfigRefer.CityConfig:CityShadowDistanceList(i))
    end
    if #sizeArray ~= #shadowDistanceList then
        local minLength = math.min(#sizeArray, #shadowDistanceList)
        local sizeOverflow = math.max(0, #sizeArray - minLength)
        for i = 1, sizeOverflow do
            table.remove(sizeArray)
        end
        local distanceOverflow = math.max(0, #shadowDistanceList - minLength)
        for i = 1, distanceOverflow do
            table.remove(shadowDistanceList)
        end
    end

    local fovArray = {}
    for i = 1, ConfigRefer.CityConfig:CityFovListLength() do
        table.insert(fovArray, ConfigRefer.CityConfig:CityFovList(i))
    end

    self.shadowDistanceList = shadowDistanceList
    self.sizeArray = sizeArray
    self.fovArray = fovArray
    self.shadowCascades = ConfigRefer.CityConfig:CityShadowCascades()
    self.cascade2split = ConfigRefer.CityConfig:CityCascade2Split()
    ShadowDistanceControl.SetEnable(true)
    ShadowDistanceControl.ChangeShadowCascades(self.shadowCascades)
    local distance = ShadowDistanceControl.RefreshShadow(self.kingdomScene.basicCamera.mainCamera, self.kingdomScene.basicCamera:GetSize(), self.sizeArray, self.shadowDistanceList)
    ShadowDistanceControl.ChangeCascade2Split(self.cascade2split, distance)
    FovControl.UpdateFov(self.kingdomScene.basicCamera, self.sizeArray, self.fovArray)

    ModuleRefer.ServerPushNoticeModule:AddAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleActivated)
    ModuleRefer.ServerPushNoticeModule:AddAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleStart)
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged))
    g_Game.EventManager:AddListener(EventConst.QUEST_LATE_UPDATE, Delegate.GetOrCreate(self, self.OnTaskChangeCheckBgm))
    self.currentSceneBgm = nil
    if self.city:IsMyCity() then
        self.currentSceneBgm = self:GetCurrentSceneBgmUsage()
        g_Game.SoundManager:OnSceneChange(self.currentSceneBgm, true)
    end
    ModuleRefer.SlgModule:StartRunning()
    
    if self._markerInitState == nil or self._markerInitState then
        self:ShowMarkerHUD()
    end
    CloudUtils.Uncover()

    ModuleRefer.PerformanceModule:AddTag('city')
    -- g_Game:ExtremeGCStrategy()
    local cityScale = self.city.scale or 1
    local vecotr4 = CS.UnityEngine.Vector4(cityScale, 1 / cityScale, 0, 0)
    CS.UnityEngine.Shader.SetGlobalVector(CS.RenderExtension.ShaderConst.globalEffectScaleId ,vecotr4)
    local zeroPoint = self.city.zeroPoint
    CS.UnityEngine.Shader.SetGlobalVector(CS.RenderExtension.ShaderConst.GlobalCityMapParamsId, CS.UnityEngine.Vector4(zeroPoint.x, zeroPoint.z, cityScale, 0))
end

function KingdomSceneStateInCity:OnCameraSettingReady(flag)
    if flag and self.kingdomScene and self.kingdomScene.basicCamera then
        local settingsHandle = g_Game.AssetManager:LoadAsset(ManualResourceConst.city_camera_settings)
        CityCameraSettingsSetter.Set(settingsHandle.Asset, self.kingdomScene.basicCamera, KingdomMapUtils.GetCameraLodData(), KingdomMapUtils.GetCameraPlaneData())
    end
end

function KingdomSceneStateInCity:Tick(deltaTime)
    self.city:Tick(deltaTime)
end

function KingdomSceneStateInCity:Exit()
    self:HideMarkerHUD()
    
    if self.currentSceneBgm then
        g_Game.SoundManager:OnSceneChange(self.currentSceneBgm, false)
        self.currentSceneBgm = nil
    end
    self.kingdomScene.basicCamera:SetFov(30)
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged))
    ModuleRefer.ServerPushNoticeModule:RemoveAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleStart)
    ModuleRefer.ServerPushNoticeModule:RemoveAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleActivated)
    g_Game.EventManager:RemoveListener(EventConst.QUEST_LATE_UPDATE, Delegate.GetOrCreate(self, self.OnTaskChangeCheckBgm))
    self:ResetCameraSize()
    -- self.cityCameraSizeRule:Release()
    self.cityCameraLodRule:Release()
    -- self.kingdomScene.basicCamera.processor = CameraDataPerspectiveProcessor.new()
    self.kingdomScene.mediator.cameraSizeRule:SetBlock(false)
    if self.city:IsMyCity() then
        ModuleRefer.GamePlaySequenceModule:StopSequence_EnterMyCity()
    end
    if UNITY_DEBUG and UNITY_EDITOR then
        g_Game:RemoveOnDrawGizmos(Delegate.GetOrCreate(self.city, self.city.OnGizmos))
    end
    self.kingdomScene.basicCamera:SetSunlightEnable(false)
    self.kingdomScene.basicCamera:RemoveSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChanged))
    self.city = nil
    self.shadowDistanceList = nil
    self.shadowCascades = nil
    self.cascade2split = nil
    ModuleRefer.SlgModule:Pause()
    KingdomSceneState.Exit(self)

    ModuleRefer.PerformanceModule:RemoveTag('city')

    if DeviceUtil.IsLowMemoryDevice() then
        KingdomMapUtils.ClearCityPools()
        Utils.FullGC()
    end
    -- g_Game:RelaxedGCStrategy()
    -- local cityScale = 1
    -- local vecotr4 = CS.UnityEngine.Vector4(cityScale, 1 / cityScale, 0, 0)
    -- CS.UnityEngine.Shader.SetGlobalVector(CS.RenderExtension.ShaderConst.globalEffectScaleId ,vecotr4)
end

function KingdomSceneStateInCity:OnSizeChanged(from, to)
    local distance = ShadowDistanceControl.RefreshShadow(self.kingdomScene.basicCamera.mainCamera, to, self.sizeArray, self.shadowDistanceList)
    ShadowDistanceControl.ChangeCascade2Split(self.cascade2split, distance)
    FovControl.UpdateFov(self.kingdomScene.basicCamera, self.sizeArray, self.fovArray)
end

function KingdomSceneStateInCity:OnZoneStatusChanged()
    self:SetCameraSize()
end

function KingdomSceneStateInCity:SetCameraSize()
    local minSize, maxSize = self.city:GetCameraMaxSize()
    local cameraData = self.kingdomScene.basicCamera.cameraDataPerspective
    cameraData.maxSize = maxSize
    cameraData.maxSizeBuffer = self.maxSizeCache - maxSize
    cameraData.minSize = minSize
    cameraData.minSizeBuffer = self.minSizeCache - minSize
    self.kingdomScene.basicCamera:SetSize(self.kingdomScene.basicCamera:GetSize())
end

function KingdomSceneStateInCity:TempSetCameraSize(maxSize)
    local minSize, _ = self.city:GetCameraMaxSize()
    local cameraData = self.kingdomScene.basicCamera.cameraDataPerspective
    cameraData.maxSize = maxSize
    cameraData.maxSizeBuffer = self.maxSizeCache - maxSize
    cameraData.minSize = minSize
    cameraData.minSizeBuffer = self.minSizeCache - minSize
    self.kingdomScene.basicCamera:SetSize(self.kingdomScene.basicCamera:GetSize())
end

function KingdomSceneStateInCity:ResetCameraSize()
    local cameraData = self.kingdomScene.basicCamera.cameraDataPerspective
    cameraData.maxSize = self.maxSizeCache
    cameraData.maxSizeBuffer = 0
    cameraData.minSize = self.minSizeCache
    cameraData.minSizeBuffer = 0
    -- self.kingdomScene.basicCamera:SetSize(self.kingdomScene.basicCamera:GetSize())
end

function KingdomSceneStateInCity:ShowMarkerHUD()
    if self.city:IsMyCity() then
        self.markerHudRuntimeId = g_Game.UIManager:Open(UIMediatorNames.UnitMarkerHudUIMediator, CanUnlockFogMarkerGroup.new(self.city, self.kingdomScene.basicCamera))
    end
    self._markerInitState = true
end

function KingdomSceneStateInCity:HideMarkerHUD()
    if self.markerHudRuntimeId then
        g_Game.UIManager:Close(self.markerHudRuntimeId)
        self.markerHudRuntimeId = nil
    end
    self._markerInitState = false
end

function KingdomSceneStateInCity:OnLightRestartBegin()
    if self.city then
        self.city.stateMachine:WriteBlackboard("ENTER_NORMAL_REASON", "OnLightRestartBegin")
        self.city.stateMachine:ChangeState(CityConst.STATE_NORMAL)
        self.city.mediator:SetEnableGesture(false)
    end
end

function KingdomSceneStateInCity:CanLightRestart()
    return self.city ~= nil
end

function KingdomSceneStateInCity:OnLightRestartEnd()
    if not self.city.inRestarting then
        self.city:MarkAsLightRestart()
        if self.city.showed then
            self.city:OnCityInactiveForManagers()
        end
        self.city:UnloadView()
        self.city:UnloadData()
    end

    TimerUtility.DelayExecuteInFrame(function()
        self.city:UpdateCastle()
        self.city:LoadData()
        self.city:LoadView()
        if self.city.stateMachine.currentState then
            self.city.stateMachine.currentState:OnLightRestartEnd()
        end
    end, 1, true)
end

function KingdomSceneStateInCity:OnLightRestartFailed()
    ---DO Nothing
end

function KingdomSceneStateInCity:IsLoaded()
    return self.city ~= nil
end

function KingdomSceneStateInCity:OnTaskChangeCheckBgm()
    if not self.currentSceneBgm then return end
    local bgm = self:GetCurrentSceneBgmUsage()
    if bgm == self.currentSceneBgm then return end
    self.currentSceneBgm = bgm
    g_Game.SoundManager:OnSceneChange(self.currentSceneBgm, true)
end

function KingdomSceneStateInCity:GetCurrentSceneBgmUsage()
    local switchConfig = ConfigRefer.CityConfig:CityBgmStageTask()
    if switchConfig ~= 0 then
        local isFinished = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(switchConfig) == wds.TaskState.TaskStateFinished
        if isFinished then
            return SceneBgmUsage.SelfCityStage1
        end
    end
    return SceneBgmUsage.SelfCity
end

return KingdomSceneStateInCity
