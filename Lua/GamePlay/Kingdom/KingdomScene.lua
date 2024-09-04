local Utils = require("Utils")
local Scene = require("Scene")
local PvPTileViewFactory = require("PvPTileViewFactory")
local KingdomViewFactory = require("KingdomViewFactory")
local ModuleRefer = require("ModuleRefer")
local PvPRequestService = require('PvPRequestService')
local EventConst = require('EventConst')
local KingdomMediator = require('KingdomMediator')
local UIMediatorNames = require('UIMediatorNames')
local CameraConst = require("CameraConst")
local Delegate = require('Delegate')
local StateMachine = require("StateMachine")
local KingdomSceneStateEntry = require("KingdomSceneStateEntry")
local KingdomSceneStateInCity = require("KingdomSceneStateInCity")
local KingdomSceneStateMap = require("KingdomSceneStateMap")
local KingdomSceneStateEntryToCity = require("KingdomSceneStateEntryToCity")
local KingdomSceneStateEntryToMap = require("KingdomSceneStateEntryToMap")
local KingdomSceneStateMapToCity = require("KingdomSceneStateMapToCity")
local KingdomSceneStateCityToMap = require("KingdomSceneStateCityToMap")
local MapFoundation = require("MapFoundation")
local KingdomMapUtils = require("KingdomMapUtils")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
local ManualResourceConst = require("ManualResourceConst")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local DeviceUtil = require("DeviceUtil")
local MapConfigCache = require("MapConfigCache")

local MapUtils = CS.Grid.MapUtils
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local LuaTileViewFactory = CS.Grid.LuaTileViewFactory
local LuaRequestService = CS.Grid.LuaRequestService
local LuaKingdomViewFactory = CS.Grid.LuaKingdomViewFactory

---@class KingdomScene : Scene
---@field mapSystem CS.Grid.MapSystem
---@field staticMapData CS.Grid.StaticMapData
---@field basicCamera BasicCamera
---@field mapMarkCamera MapMarkCamera
---@field cameraLodData CameraLodData
---@field cameraPlaneData CameraPlaneData
---@field mapFoundation MapFoundation
---@field mediator KingdomMediator
---@field stateMachine StateMachine
---@field customHexChunkAccess KingdomCustomHexChunkAccessModule
local KingdomScene = class("KingdomScene", Scene)

KingdomScene.Name = "KingdomScene"

function KingdomScene:ctor()
    self.helper = GameObjectCreateHelper.Create()
    self.stateMachine = StateMachine.new(true)
    self.mapFoundation = MapFoundation.new()
end

function KingdomScene:EnterScene(param)
    Scene.EnterScene(self, param)

    g_Logger.Log("EnterScene: " .. "KingdomScene")
    local loading = g_Game.StateMachine:ReadBlackboard("KINGDOM_LOADING")
    if loading then
        g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator)
    end

    self:InitStateMachine()

    self.helper:Create(ManualResourceConst.grid_map_system, nil, function(go)
        if Utils.IsNotNull(go) then
            local tileViewFactory = LuaTileViewFactory(PvPTileViewFactory.new())
            local kingdomViewFactory = LuaKingdomViewFactory(KingdomViewFactory.new())
            local requestService = LuaRequestService(PvPRequestService.new())
            local levelBias = g_Game.PerformanceLevelManager.qualityLevelConfig:MapSliceLevelBias()
            self.mapFoundation:Setup(MapFoundation.MapName, go, tileViewFactory, kingdomViewFactory, requestService,  nil, levelBias)
            self.root = self.mapFoundation.root
            self.basicCamera = self.mapFoundation.basicCamera
            self.camera = self.mapFoundation.camera
            self.cameraLodData = self.mapFoundation.cameraLodData
            self.cameraPlaneData = self.mapFoundation.cameraPlaneData
            self.mapSystem = self.mapFoundation.mapSystem
            self.staticMapData = self.mapFoundation.staticMapData
            self.mapMarkCamera = self.mapFoundation.mapMarkCamera

            local maxDecorations, maxUnits = g_Game.PerformanceLevelManager:GetMaxDecorationAndUnitProcessCountPerFrame()
            self.mapSystem.MaxDecorationProcessCountPerFrame = maxDecorations
            self.mapSystem.MaxUnitProcessCountPerFrame = maxUnits

            ---@type CS.UnityEngine.Light
            self.kingdomMainLight = go:GetComponentInChildren(typeof(CS.UnityEngine.Light))
            self.customHexChunkAccess = ModuleRefer.KingdomCustomHexChunkAccessModule
            self:StartKingdom()
        else
            g_Logger.ErrorChannel("KingdomScene", "[KingdomScene]Enter: Failed to load grid map root.")
        end
    end)
    g_Game.ModuleManager:RetrieveModule("CityModule")

    g_Game.EventManager:AddListener(EventConst.CITY_CASTLE_BRIEF_DELETE, Delegate.GetOrCreate(self, self.OnCityCastleBriefDeleted))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))

end

function KingdomScene:ExitScene(param)
    if not self.mapSystem then
        return
    end

    self.mapSystem:RemoveTerrainLoadedObserver(self.mediator:GetTerrainLoadedCallback())
    if self.customHexChunkAccess then
        self.mapSystem:RemoveOnCustomHexChunkShow(self.customHexChunkAccess:GetOnShowCallback())
        self.mapSystem:RemoveOnCustomHexChunkHide(self.customHexChunkAccess:GetOnHideCallback())
    end

    g_Game.EventManager:RemoveListener(EventConst.CITY_CASTLE_BRIEF_DELETE, Delegate.GetOrCreate(self, self.OnCityCastleBriefDeleted))
    g_Game.EventManager:RemoveListener(EventConst.HUD_GOTO_KINGDOM, Delegate.GetOrCreate(self, self.LeaveCity))
    g_Game.EventManager:RemoveListener(EventConst.HUD_GOTO_MY_CITY, Delegate.GetOrCreate(self, self.MoveToMyCity))
    g_Game.EventManager:RemoveListener(EventConst.HUD_RETURN_TO_MY_CITY, Delegate.GetOrCreate(self, self.ReturnMyCity))
    self:RemoveSizeChangeListener(Delegate.GetOrCreate(self, self.OnCameraSizeChanged))


    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))

    if self.stateMachine.currentName == KingdomSceneStateMap.Name then
        KingdomSceneStateMap.PostEndMap()
    end

    self.stateMachine:ClearAllStates()

    self.helper:CancelAllCreate()

    MapConfigCache.Dispose()

    g_Game.UIManager:CloseByName(UIMediatorNames.HUDMediator)
    ModuleRefer.SlgInterfaceModule:SetSlgModule(nil)
    g_Game.ModuleManager:RemoveModule("SlgModule")
    ModuleRefer.KingdomInteractionModule:ShutDown()
    local myCity = ModuleRefer.CityModule:GetMyCity()
    myCity:OnCameraUnload()
    myCity:SetActive(false)
    if DeviceUtil.IsLowMemoryDevice() then
        myCity:UnloadView()
        myCity:UnloadBasicResource()
    end
    ModuleRefer.CityModule:SetKingdomMainLight(nil)
    local cityScale = 1
    local vecotr4 = CS.UnityEngine.Vector4(cityScale, 1 / cityScale, 0, 0)
    CS.UnityEngine.Shader.SetGlobalVector(CS.RenderExtension.ShaderConst.globalEffectScaleId ,vecotr4)

    if self.mediator then
    self.mediator = nil
    end

    self.mapFoundation:ShutDown()
    self.basicCamera = nil
    self.camera = nil
    self.cameraLodData = nil
    self.cameraPlaneData = nil
    if self.customHexChunkAccess then
        self.customHexChunkAccess:ClearUp()
    end
    self.customHexChunkAccess = nil
    self.mapMarkCamera = nil

    CS.U2DFontUpdateTracker.ClearTracks()

    KingdomMapUtils.ClearCityPools()
    KingdomMapUtils.ClearKingdomPools()
    UIHelper.DestroyAllTableViewCachedObjects()

    self.mapSystem = nil
    self.staticMapData = nil
    Utils.FullGC()
end

function KingdomScene:Tick(dt)
    self.stateMachine:Tick(dt)
end

function KingdomScene:OnLateUpdate(dt)
    self.stateMachine:LateTick(dt)
    self.mapFoundation:Tick(dt)
end

function KingdomScene:InitStateMachine()
    self.stateMachine.enableLog = true
    self.stateMachine.allowReEnter = true
    self.stateMachine:AddState(KingdomSceneStateEntry.Name, KingdomSceneStateEntry.new(self))
    self.stateMachine:AddState(KingdomSceneStateInCity.Name, KingdomSceneStateInCity.new(self))
    self.stateMachine:AddState(KingdomSceneStateMap.Name, KingdomSceneStateMap.new(self))
    self.stateMachine:AddState(KingdomSceneStateEntryToCity.Name, KingdomSceneStateEntryToCity.new(self))
    self.stateMachine:AddState(KingdomSceneStateEntryToMap.Name, KingdomSceneStateEntryToMap.new(self))
    self.stateMachine:AddState(KingdomSceneStateMapToCity.Name, KingdomSceneStateMapToCity.new(self))
    self.stateMachine:AddState(KingdomSceneStateCityToMap.Name, KingdomSceneStateCityToMap.new(self))
end

function KingdomScene:StartKingdom()
    self.mediator = KingdomMediator.new()
    self.mapSystem:AddTerrainLoadedObserver(self.mediator:GetTerrainLoadedCallback())

    g_Game.EventManager:TriggerEvent(EventConst.ENTER_SCENE_QUALITY_CHANGED)

    --- Testing City Logic ---
    ModuleRefer.CityModule:SetKingdomMainLight(self.kingdomMainLight)
    ModuleRefer.SlgModule:Init()
    ModuleRefer.SlgInterfaceModule:SetSlgModule(ModuleRefer.SlgModule)
    ModuleRefer.KingdomInteractionModule:Setup()

    local param = { isCity = Delegate.GetOrCreate(self, self.IsInCity), isMyCity = Delegate.GetOrCreate(self, self.IsInMyCity)};
	g_Game.UIManager:Open(UIMediatorNames.HUDMediator, param, function(BaseUIMediator)
        --self:EnterStateNormal()
        self.stateMachine:ChangeState(KingdomSceneStateEntry.Name)
        --g_Game.SoundManager:PlayBgm("bgm_se_city")
        g_Game.EventManager:AddListener(EventConst.HUD_GOTO_KINGDOM, Delegate.GetOrCreate(self, self.LeaveCity))
        g_Game.EventManager:AddListener(EventConst.HUD_GOTO_MY_CITY, Delegate.GetOrCreate(self, self.MoveToMyCity))
        g_Game.EventManager:AddListener(EventConst.HUD_RETURN_TO_MY_CITY, Delegate.GetOrCreate(self, self.ReturnMyCity))
        self:AddSizeChangeListener(Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    end)
end

function KingdomScene:SetupCustomHexChunkEvent(add)
    if add then
        self.mapSystem:AddOnCustomHexChunkShow(self.customHexChunkAccess:GetOnShowCallback())
        self.mapSystem:AddOnCustomHexChunkHide(self.customHexChunkAccess:GetOnHideCallback())
    else
        self.mapSystem:RemoveOnCustomHexChunkShow(self.customHexChunkAccess:GetOnShowCallback())
        self.mapSystem:RemoveOnCustomHexChunkHide(self.customHexChunkAccess:GetOnHideCallback())
        self.customHexChunkAccess:ClearUp()
    end
end

function KingdomScene:GetLod()
    if self.cameraLodData then
        return self.cameraLodData:GetLod()
    else
        return 0
    end
end

function KingdomScene:GetCamSize()
    if self.cameraLodData then
        return self.cameraLodData:GetSize()
    else
        return 1000
    end
end

function KingdomScene:InCityLod()
    return self:GetLod() <= CameraConst.CITY_LOD
end

function KingdomScene:InKingdomLod()
    return self:GetLod() >= CameraConst.KINGDOM_LOD
end

---@return City
function KingdomScene:GetCurrentViewedCity()
    if self.stateMachine.currentName == KingdomSceneStateInCity.Name then
        return self.stateMachine.currentState.city
    end
end

function KingdomScene:IsInMyCity()
    return self.stateMachine.currentName == KingdomSceneStateInCity.Name and self.stateMachine.currentState.city:IsMyCity()
end

function KingdomScene:IsInCity()
    return self.stateMachine.currentName == KingdomSceneStateInCity.Name
end

function KingdomScene:OnCameraSizeChanged(oldSize, newSize)
    if not KingdomMapUtils.IsMapState() then
        return
    end
    local showFogShadow = newSize <= self.mapFoundation.cameraLodData:GetSizeByLod(2)
    local settingsObject = self.mediator:GetEnvironmentSettings()
    if Utils.IsNotNull(settingsObject) then
        settingsObject:GetComponent(typeof(CS.Kingdom.MapSettings)):EnableCloudShadow(showFogShadow)
    end
end

function KingdomScene:MoveToMyCity()
    --090 改为点一下就直接回城
    self:ReturnMyCity()

    --if self:CheckFocusTileIsCity() then
    --    self:ReturnMyCity()
    --else
    --    self:FocusToMyCityTile()
    --end
end

function KingdomScene:FocusToMyCityTile()
    local myCityCoord = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    local x = math.floor(myCityCoord.X)
    local y = math.floor(myCityCoord.Y)
    local myCityPosition = MapUtils.CalculateCoordToTerrainPosition(x, y, KingdomMapUtils.GetMapSystem())
    KingdomMapUtils.MoveAndZoomCamera(myCityPosition, KingdomMapUtils.GetCameraLodData().mapCameraEnterSize, 0.3, 0.3)
end

function KingdomScene:CheckFocusTileIsCity()
    local _, anchorCoordinate = KingdomMapUtils.GetCameraAnchorTerrainCoordinate()
    local tile = KingdomMapUtils.RetrieveMap(anchorCoordinate.X, anchorCoordinate.Y)
    return tile.entity and tile.entity.TypeHash == require("DBEntityType").CastleBrief and tile.entity.Owner.PlayerID == ModuleRefer.PlayerModule.playerId
end

function KingdomScene:ReturnMyCity(callback)
    local city = ModuleRefer.CityModule.myCity
    local success = ModuleRefer.EnterSceneModule:NoticeEnterScene(require('GotoUtils').SceneId.MainCity, 0)
    if success then
        local myCityCoord = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
        local x = math.floor(myCityCoord.X)
        local y = math.floor(myCityCoord.Y)
        local myCityPosition = MapUtils.CalculateCoordToTerrainPosition(x, y, KingdomMapUtils.GetMapSystem())
        KingdomMapUtils.GetMapSystem():SetTimerRunning(false)
        KingdomMapUtils.GetBasicCamera():LookAt(myCityPosition)
        KingdomMapUtils.GetBasicCamera():ZoomTo(KingdomMapUtils.GetCameraLodData().mapCameraEnterSize)
        self:TransNormalToCity(city, callback)
    end
end

function KingdomScene:LeaveCity(callback)
    local castle_born = NewFunctionUnlockIdDefine.KingdomScene_radar_world_unlock
    local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(castle_born)
    if not unlocked then
        ModuleRefer.NewFunctionUnlockModule:ShowLockedTipToast(castle_born)
        return
    end

    if self.stateMachine:IsCurrentState(KingdomSceneStateInCity.Name) then
        local success = ModuleRefer.EnterSceneModule:NoticeEnterScene(require('GotoUtils').SceneId.Kingdom, 0)
        if success then
            g_Game.StateMachine:WriteBlackboard("City", self.stateMachine.currentState.city)
            g_Game.StateMachine:WriteBlackboard("EnterKingdomCallback", callback)
            self.stateMachine:ChangeState(KingdomSceneStateCityToMap.Name)
        end
    end
end

function KingdomScene:AddLodChangeListener(listener)
    if self.mapFoundation.cameraLodData and listener then
        self.mapFoundation.cameraLodData:AddLodChangeListener(listener)
    end
end
---@param listener fun(oldLod:number,newLod:number)
function KingdomScene:RemoveLodChangeListener(listener)
    if self.mapFoundation.cameraLodData and listener then
        self.mapFoundation.cameraLodData:RemoveLodChangeListener(listener)
    end
end

---@param listener fun(oldSize:number,newSize:number)
function KingdomScene:AddSizeChangeListener(listener)
    if self.mapFoundation.cameraLodData and listener then
        self.mapFoundation.cameraLodData:AddSizeChangeListener(listener)
    end
end
---@param listener fun(oldSize:number,newSize:number)
function KingdomScene:RemoveSizeChangeListener(listener)
    if self.mapFoundation.cameraLodData and listener then
        self.mapFoundation.cameraLodData:RemoveSizeChangeListener(listener)
    end
end

function KingdomScene:TransCityToNormal(city)
    self.stateMachine:WriteBlackboard("City", city)
    self.stateMachine:ChangeState(KingdomSceneStateCityToMap.Name)
end

function KingdomScene:TransNormalToCity(city, callback)
    self.stateMachine:WriteBlackboard("City", city)
    self.stateMachine:WriteBlackboard("EnterCityCallback", callback)
    self.stateMachine:ChangeState(KingdomSceneStateMapToCity.Name)
end

function KingdomScene:OnCityCastleBriefDeleted(city)
    if self.stateMachine.currentName == KingdomSceneStateMap.Name then
        return
    end

    local curState = self.stateMachine.currentState
    if curState.city == city then
        self:TransCityToNormal(city)
    end
end

function KingdomScene:MoveCity(tileX, tileZ)
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if serverTime < ModuleRefer.PlayerModule:GetCastle().BasicInfo.MoveCityTime.Seconds then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_build_qclq"))
        return
    end

    local message = require("MoveCityParameter").new()
    message.args.DestX = tileX
    message.args.DestY = tileZ
    message.args.Typo = wrpc.MoveCityType.MoveCityType_MoveToAllianceTerrain
    message:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            ModuleRefer.CityModule.myCity:SetCityPosition(tileX, tileZ, KingdomMapUtils.GetStaticMapData())
        end
    end)
end

function KingdomScene:MoveCityByType(tileX, tileZ, type)
    local message = require("MoveCityParameter").new()
    message.args.DestX = tileX
    message.args.DestY = tileZ
    message.args.Typo = type
    message:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            ModuleRefer.CityModule.myCity:SetCityPosition(tileX, tileZ, KingdomMapUtils.GetStaticMapData())
        end
    end)
end

function KingdomScene:CanLightRestart()
    if self.stateMachine.currentState then
        return self.stateMachine.currentState:CanLightRestart()
    end
    return false
end

function KingdomScene:OnLightRestartBegin()
    g_Game.UIManager:CloseByName(UIMediatorNames.HUDMediator)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnLightRestartBegin()
    end
end

function KingdomScene:OnLightRestartEnd()
    local param = { isCity = Delegate.GetOrCreate(self, self.IsInCity), isMyCity = Delegate.GetOrCreate(self, self.IsInMyCity)};
    g_Game.UIManager:Open(UIMediatorNames.HUDMediator, param, function(BaseUIMediator)
        local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
        if hudMediator then
            hudMediator:OnLodChanged(nil, self:GetLod())
        end
        g_Game.EventManager:TriggerEvent(EventConst.HUD_MEDIATOR_RESTARTEND_SHOW)
    end)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnLightRestartEnd()
    end
end

function KingdomScene:OnLightRestartFailed()
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnLightRestartFailed()
    end
end

function KingdomScene:IsLoaded()
    if self.stateMachine and self.stateMachine.currentState then
        return self.stateMachine.currentState:IsLoaded()
    end
    return Scene.IsLoaded(self)
end

return KingdomScene
