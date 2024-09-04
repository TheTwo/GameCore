local KingdomSceneState = require("KingdomSceneState")
local QueuedTask = require("QueuedTask")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local GuideConst = require("GuideConst")
local EventConst = require("EventConst")
local HUDConst = require("HUDConst")
local StateMachine = require("StateMachine")
local MapStateNormal = require("MapStateNormal")
local MapStatePlacingBuilding = require("MapStatePlacingBuilding")
local MapStateRelocate = require("MapStateRelocate")
local KingdomMapUtils = require("KingdomMapUtils")
local URPRendererList = require("URPRendererList")
local SceneBgmUsage = require("SceneBgmUsage")
local CloudUtils = require("CloudUtils")
local DeviceUtil = require("DeviceUtil")
local Utils = require("Utils")
local MyCityMarkerGroup = require("MyCityMarkerGroup")
local MapCameraSettingsSetter = require("MapCameraSettingsSetter")
local KingdomConstant = require("KingdomConstant")
local CameraUtils = require("CameraUtils")
local MapConfigCache = require("MapConfigCache")
local MapAssetNames = require("MapAssetNames")

local ListSingle = CS.System.Collections.Generic.List(typeof(CS.System.Single))


---@class KingdomSceneStateMap:KingdomSceneState
---@field new fun(kingdomScene:KingdomScene):KingdomSceneStateMap
---@field mapStateMachine StateMachine
---@field mapSystem CS.Grid.MapSystem
---@field staticMapData CS.Grid.StaticMapData
---@field basicCamera BasicCamera
---@field isReady boolean
local KingdomSceneStateMap = class("KingdomSceneStateMap", KingdomSceneState)
KingdomSceneStateMap.Name = "KingdomSceneStateMap"

function KingdomSceneStateMap:ctor(kingdomScene)
    KingdomSceneState.ctor(self, kingdomScene)
    self.task = QueuedTask.new()
    self.mapStateMachine = StateMachine.new()
end

function KingdomSceneStateMap:Enter()
    KingdomSceneState.Enter(self)

    local cityScale = 1
    local vecotr4 = CS.UnityEngine.Vector4(cityScale, 1 / cityScale, 0, 0)
    CS.UnityEngine.Shader.SetGlobalVector(CS.RenderExtension.ShaderConst.globalEffectScaleId ,vecotr4)
    
    self.task:WaitResponse(require('UpdateAOIParameter').GetMsgId()
    ):WaitTrue(function()
        return g_Game.UIManager:Name2RuntimeId(UIMediatorNames.HUDMediator) > 0 and self.kingdomScene.basicCamera and self.kingdomScene.basicCamera:Idle()
    end
    ):DoAction(function() 
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.EnterKingdom)       
    end):Start()

    self:StartMap()

    ModuleRefer.PerformanceModule:AddTag('kingdom')
    -- g_Game:ExtremeGCStrategy()
end

function KingdomSceneStateMap:Exit()
    self:EndMap()   
    KingdomSceneState.Exit(self)

    ModuleRefer.PerformanceModule:RemoveTag('kingdom')
end

function KingdomSceneStateMap:Tick(dt)
    self.mapStateMachine:Tick(dt)
end

function KingdomSceneStateMap:LateTick(dt)
    if self.basicCamera and self.basicCamera.hasChanged then
        KingdomMapUtils.Border(self.basicCamera, self.staticMapData)
    end
end

function KingdomSceneStateMap:StartMap()
	ModuleRefer.MapPreloadModule:TempDeleteMistBin()
	
    self.mapSystem = KingdomMapUtils.GetMapSystem()
    self.staticMapData = KingdomMapUtils.GetStaticMapData()
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    self.basicCamera.mainCamera:GetUniversalAdditionalCameraData():SetRenderer(URPRendererList.Map)

    g_Game.EventManager:TriggerEvent(EventConst.ENTER_KINGDOM_MAP_START)

    g_Game.EventManager:TriggerEvent(EventConst.HUD_STATE_CHANGED, HUDConst.HUD_STATE.CITY)
    self.kingdomScene.mediator:Initialize()
    self.kingdomScene.mediator:LoadEnvironmentSettings(self.staticMapData, function()
        self:PostStartMap()
    end)

    self:InitStateMachine()
    self.mapStateMachine:ChangeState(MapStateNormal.Name)
end

function KingdomSceneStateMap:PostStartMap()
    ---@type CS.Kingdom.MapSettings
    local settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Kingdom.MapSettings))
    local cameraSettings = settings.CameraSettings
    MapCameraSettingsSetter.Set(cameraSettings, self.basicCamera, KingdomMapUtils.GetCameraLodData(), KingdomMapUtils.GetCameraPlaneData())
    KingdomMapUtils.SetGlobalCityMapParamsId(true)
    
    self:InitializeMapSystem()

    self:AddListeners()

    ModuleRefer.SlgModule:StartRunning()
    self:ShowMarkerHUD()

    KingdomSceneStateMap.SetupModules()

    CloudUtils.Uncover()
    ModuleRefer.KingdomTransitionModule:ZoomOutMap(self.basicCamera, function()
        local enterCallback = g_Game.StateMachine:ReadBlackboard("EnterKingdomCallback")
        if enterCallback then
            enterCallback()
        end
        self.kingdomScene.mediator.cameraSizeRule:SetBlock(false)
        self.isReady = true
        g_Game.SoundManager:OnSceneChange(SceneBgmUsage.KingdomMap, true)
        g_Game.EventManager:TriggerEvent(EventConst.ENTER_KINGDOM_MAP_END)
    end)
end

function KingdomSceneStateMap:EndMap()
    self.isReady = false

    g_Game.EventManager:TriggerEvent(EventConst.LEAVE_KINGDOM_MAP_START)
    
    self:HideMarkerHUD()

    self.mapStateMachine:ClearAllStates()
    self.kingdomScene.mediator:Release()
    ModuleRefer.SlgModule:Pause()
  
    self:RemoveListeners()

    g_Game.SoundManager:OnSceneChange(SceneBgmUsage.KingdomMap, false)
end

function KingdomSceneStateMap.PostEndMap()
    KingdomSceneStateMap.ShutDownModules()
    -- 通知后端离开所有的地块，关闭地图UpdateCamera
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem then
        mapSystem:Leave()
    end

    if DeviceUtil.IsLowMemoryDevice() then
        KingdomMapUtils.ClearKingdomPools()
        Utils.FullGC()
    end
    -- g_Game:RelaxedGCStrategy()
    
    g_Game.EventManager:TriggerEvent(EventConst.LEAVE_KINGDOM_MAP_END)
end

function KingdomSceneStateMap.SetupModules()
    MapConfigCache.Initialize()
    ModuleRefer.MapUnitModule:Setup()
    ModuleRefer.TerritoryModule:SetupView()
    ModuleRefer.RoadModule:Setup()
    ModuleRefer.MapCreepModule:Setup()
    ModuleRefer.MapFogModule:Setup()
    ModuleRefer.MapHUDModule:Setup()
    ModuleRefer.KingdomTransitionModule:Setup()
    ModuleRefer.MapSlgInteractorModule:Setup()
    ModuleRefer.WorldRewardInteractorModule:Setup()
    ModuleRefer.KingdomVfxModule:Setup()
end

function KingdomSceneStateMap.ShutDownModules()
    ModuleRefer.KingdomTouchInfoModule:Hide()
    ModuleRefer.TerritoryModule:ReleaseView()
    ModuleRefer.KingdomPlacingModule:Release()
    ModuleRefer.MapUnitModule:ShutDown()
    ModuleRefer.RoadModule:ShutDown()
    ModuleRefer.MapCreepModule:ShutDown()
    ModuleRefer.MapFogModule:ShutDown()
    ModuleRefer.MapHUDModule:ShutDown()
    ModuleRefer.KingdomTransitionModule:ShutDown()
    ModuleRefer.MapSlgInteractorModule:ShutDown()
    ModuleRefer.WorldRewardInteractorModule:ShutDown()
    ModuleRefer.KingdomVfxModule:ShutDown()
    ModuleRefer.KingdomCustomHexChunkAccessModule:ClearUp()
end

function KingdomSceneStateMap:AddListeners()
    ModuleRefer.ServerPushNoticeModule:AddAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleActivated)
    ModuleRefer.ServerPushNoticeModule:AddAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleStart)
    ModuleRefer.ServerPushNoticeModule:AddAllowMask(wrpc.PushNoticeType.PushNoticeType_SlgCreepRemoveEnterSE)
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    scene:SetupCustomHexChunkEvent(true)
end

function KingdomSceneStateMap:RemoveListeners()
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    scene:SetupCustomHexChunkEvent(false)
    ModuleRefer.ServerPushNoticeModule:RemoveAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleStart)
    ModuleRefer.ServerPushNoticeModule:RemoveAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleActivated)
    ModuleRefer.ServerPushNoticeModule:RemoveAllowMask(wrpc.PushNoticeType.PushNoticeType_SlgCreepRemoveEnterSE)
end

function KingdomSceneStateMap:ShowMarkerHUD()
    self.markerHudRuntimeId = g_Game.UIManager:Open(UIMediatorNames.UnitMarkerHudUIMediator, MyCityMarkerGroup.new(self.basicCamera))
end

function KingdomSceneStateMap:HideMarkerHUD()
    if self.markerHudRuntimeId then
        g_Game.UIManager:Close(self.markerHudRuntimeId)
        self.markerHudRuntimeId = nil
    end
end

function KingdomSceneStateMap:InitStateMachine()
    self.mapStateMachine.enableLog = true
    self.mapStateMachine.allowReEnter = true
    self.mapStateMachine:AddState(MapStateNormal.Name, MapStateNormal.new())
    self.mapStateMachine:AddState(MapStatePlacingBuilding.Name, MapStatePlacingBuilding.new())
    self.mapStateMachine:AddState(MapStateRelocate.Name, MapStateRelocate.new())
end

function KingdomSceneStateMap:GetCurrentMapState()
    return self.mapStateMachine:GetCurrentState()
end

function KingdomSceneStateMap:EnterNormal()
    self.mapStateMachine:ChangeState(MapStateNormal.Name)
end

function KingdomSceneStateMap:EnterPlacingBuilding()
    self.mapStateMachine:ChangeState(MapStatePlacingBuilding.Name)
end

function KingdomSceneStateMap:InitializeMapSystem()
    -- 装饰物缩放参数
    local cameraLodData = KingdomMapUtils.GetCameraLodData()
    local sizeList = ListSingle()
    for _, size in ipairs(cameraLodData.mapCameraSizeList) do
        sizeList:Add(size)
    end
    local scaleList = ListSingle()
    for _, scale in ipairs(cameraLodData.mapDecorationScaleList) do
        scaleList:Add(scale)
    end
    self.mapSystem:SetCameraLodConfig(self.basicCamera.mainCamera, KingdomConstant.KingdomLodMax, sizeList, scaleList)
    self.mapSystem:SetNoCullingLod(KingdomConstant.NoCullingLod)
    
    local settingObject = KingdomMapUtils.GetKingdomMapSettings()
    self.mapSystem:Enter(settingObject)

    -- 开启UpdateCamera
    self.mapSystem:SetTimerRunning(true)
    
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local x, z = KingdomMapUtils.ParseBuildingPos(castle.MapBasics.BuildingPos)
    self.mapSystem:ForceLoadHeightMap(x, z)
    ModuleRefer.SlgModule:OnMapStaticDataLoaded()
end

function KingdomSceneStateMap:EnterRelocate()
    self.mapStateMachine:ChangeState(MapStateRelocate.Name)
end

function KingdomSceneStateMap:CanLightRestart()
    return true
end

function KingdomSceneStateMap:OnLightRestartBegin()
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    if basicCamera then
        basicCamera.enablePinch = false
        basicCamera.enableDragging = false
    end
    self.mapSystem:SetTimerRunning(false)
    
    ModuleRefer.PetModule:RestoreAllUnits()
    ModuleRefer.WorldRewardInteractorModule:RestoreAllUnits()
    ModuleRefer.MapSlgInteractorModule:RestoreAllUnits()
    
    self.mapSystem:ClearUnits()
end

function KingdomSceneStateMap:OnLightRestartEnd()
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    if basicCamera then
        basicCamera.enablePinch = true
        basicCamera.enableDragging = true
    end
    self.mapSystem:SetTimerRunning(true)

    self.mapSystem:ReconnectRequest()
end

function KingdomSceneStateMap:IsLoaded()
    return true
end

return KingdomSceneStateMap
