--    Author:	ZhangYang
--    Date:	2021-12-28
--    Description:	原CityScene的概念，由于现在是一个嵌入在KingdomScene里的存在，实际可能同时存在多个副本
local Utils = require("Utils")
local CityMediator = require("CityMediator")
local CitySEMediator = require("CitySEMediator")
local CityGrid = require("CityGrid")
local CityGridView = require("CityGridView")
local CityGridConfig = require("CityGridConfig")
local CityZoneManager = require("CityZoneManager")
local CityStaticTilesManager = require("CityStaticTilesManager")
local Delegate = require("Delegate")
local CityBasicDataLoadManager = require("CityBasicDataLoadManager")
local CityBasicAssetManager = require("CityBasicAssetManager")
local StateMachine = require("StateMachine")
local CityStateEntry = require("CityStateEntry")
local CityStateAirView = require("CityStateAirView")
local CityStateExit = require("CityStateExit")
local OtherCityStateNormal = require("OtherCityStateNormal")
local OtherCityStateBuildingSelect = require("OtherCityStateBuildingSelect")
local OtherCityStateFurnitureSelect = require("OtherCityStateFurnitureSelect")
local CityUtils = require("CityUtils")
local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local EventConst = require('EventConst')
local CityFogManager = require("CityFogManager")
local CityFurniture = require("CityFurniture")
local CityCreepManager = require("CityCreepManager")
local ModuleRefer = require("ModuleRefer")
local CityGridLayer = require("CityGridLayer")
local CityBuildingManager = require("CityBuildingManager")
local CityBuilding = require("CityBuilding")
local CityFurnitureManager = require("CityFurnitureManager")
local CityWorkManager = require("CityWorkManager")
local CityElementManager = require("CityElementManager")
local CityLegoBuildingManager = require("CityLegoBuildingManager")
local CityGridLayerMask = require("CityGridLayerMask")
local CityConst = require("CityConst")
local CastleBuildingActivateParameter = require("CastleBuildingActivateParameter")
local CastleDelFurnitureParameter = require("CastleDelFurnitureParameter")
local CastleBuildingUpgradeParameter = require("CastleBuildingUpgradeParameter")
local RoomScorePopDatum = require("RoomScorePopDatum")
local CastleFurnitureLvUpConfirmParameter = require("CastleFurnitureLvUpConfirmParameter")
local OnChangeHelper = require("OnChangeHelper")
local KingdomMapUtils = require("KingdomMapUtils")
local CitySafeAreaWallManager = require("CitySafeAreaWallManager")
local CityUnitMoveGridEventProvider = require("CityUnitMoveGridEventProvider")
local CitySlgLifeBarManager = require("CitySlgLifeBarManager")
local CityFarmlandManager = require("CityFarmlandManager")
local CitySoundManager = require("CitySoundManager")
local CityPetManager = require("CityPetManager")
local CityMaterialDissolveShareManager = require("CityMaterialDissolveShareManager")
local CityUnitPositionQuadTree = require("CityUnitPositionQuadTree")
local AudioConsts = require("AudioConsts")
local CityElementType = require("CityElementType")
local SdkCrashlytics = require("SdkCrashlytics")
local CityManagerBase = require("CityManagerBase")
local DeviceUtil = require("DeviceUtil")
local I18N = require("I18N")
local ProtocolId = require("ProtocolId")
local CityAttrType = require("CityAttrType")
local CityFurniturePlaceUINodeDatum = require("CityFurniturePlaceUINodeDatum")
local LoadState = CityManagerBase.LoadState

local Vector3 = CS.UnityEngine.Vector3
local Plane = CS.UnityEngine.Plane
local cityKingdomTiles = 4 --- 主城在Kingdom上占的边长
local cityMaxViewSize = 4 --- City展开在Kingdom上占的边长
local loadTickInterval = 0.033 --- 单Tick加载耗时间隔

---@class City
---@field new fun(id:number, x:number, y:number, kingdomMapData:CS.Grid.StaticMapData):City
---@field managers table<string, CityManagerBase> 所有Manager
---@field orderedManagers CityManagerBase[] 所有Manager有序加载列表
---@field basicResLoadWaitList CityManagerBase[] 等待列表
---@field dataLoadWaitList CityManagerBase[] 等待列表
---@field viewLoadWaitList CityManagerBase[] 等待列表
---@field zeroPoint CS.UnityEngine.Vector3 零点的世界坐标
---@field scale number 倍率
---@field camera BasicCamera 相机
---@field CityRoot CS.UnityEngine.GameObject
---@field fogController CS.CityFogController
---@field creepController CS.CityCreepController
---@field createHelper CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@field cityCitizenManager CityCitizenManager|nil
---@field cityExplorerManager CityExplorerManager|nil
---@field outlineController CityOutlineController
---@field safeAreaWallController CS.DragonReborn.City.CitySafeAreaWallController
---@field seMapRoot CS.SEForCityMapInfo
---@field seFloatingTextMgr CS.SEFloatingTextManager
local City = class("City")

local function Warn(fmt, ...)
    if DEBUG_CITY then
        g_Logger.WarnChannel("City", fmt, ...)
    end
end

local function Error(fmt, ...)
    if DEBUG_CITY then
        g_Logger.ErrorChannel("City", fmt, ...)
    end
end

---@param uid number
---@param x number
---@param y number
---@param UnitsPerTileX number
---@param UnitsPerTileZ number
function City:ctor(uid, x, y, UnitsPerTileX, UnitsPerTileZ)
    self.createHelper = CityUtils.GetPooledGameObjectCreateHelper()
    self.managers = {}
    self.orderedManagers = {}

    self.basicResLoadWaitList = {}
    self.dataLoadWaitList = {}
    self.viewLoadWaitList = {}

    self.uid = uid
    self.castle = self:LoadCastle()
    self:SetCityPosition(x, y, UnitsPerTileX, UnitsPerTileZ)

    self.gridConfig = self:LoadGridConfig()
    self:SetZeroPoint(self:CalculateZeroPoint())
    self:SetScale(self:CalculateScaleFromKingdom(UnitsPerTileX))

    self.mediator = CityMediator.new()
    self.seMediator = CitySEMediator.new(false)
    self:AddAllCityManager()
    self:CalculateNeedLoadManagerCount()

    self.unitPositionQuadTree = CityUnitPositionQuadTree.new()
    self.unitPositionQuadTree:Init(self.zeroPoint.x, self.zeroPoint.z, self.mapX * cityMaxViewSize * self.scale, self.mapY * cityMaxViewSize * self.scale)

    self.cameraSize = 0
    --- 房顶是否隐藏
    self.roofHide = false

    self.loadViewAfterResAndDataLoaded = false
    --- 是否在加载完成后OnEnable
    self.showAfterLoaded = false

    self.cameraAreaMarginLeft = 6
    self.cameraAreaMarginRight = 6
    self.cameraAreaMarginTop = 6
    self.cameraAreaMarginBottom = 6

    self.editMode = false

    self.showed = false
    self.releaseViewWhenHide = false

    ---@type CS.CityGroundNavMarker[]
    self.cityGroundMarkers = nil

    self.unitMoveGridEventProvider = CityUnitMoveGridEventProvider.new()
    self.unitMoveGridEventProvider:Init(self.gridConfig.cellsX, self.gridConfig.cellsY)

    self:InitStateMachine()
    self.resStatus = LoadState.NotStart
    self.dataStatus = LoadState.NotStart
    self.viewStatus = LoadState.NotStart

    ---@type table<number, boolean>
    self.sendingRibbonCutBuildingIds = {}
    self.isCloseToBorder = nil
end

---@generic T : CityManagerBase
---@param manager T
function City:AddCityManager(manager)
    local name = manager:GetName()
    if self.managers[name] then
        Error("Manager named as [%s] 重复", name)
        return nil
    else
        self.managers[name] = manager
        table.insert(self.orderedManagers, manager)
        table.sort(self.orderedManagers, CityManagerBase.OrderByPriority)
    end
    return manager
end

function City:AddAllCityManager()
    self.basicDataLoadManager = self:AddCityManager(CityBasicDataLoadManager.new(self))
    self.basicAssetManager = self:AddCityManager(CityBasicAssetManager.new(self, self.basicDataLoadManager))
    self.grid = self:AddCityManager(CityGrid.new(self))
    self.gridLayer = self:AddCityManager(CityGridLayer.new(self, self.grid))
    self.buildingManager = self:AddCityManager(CityBuildingManager.new(self, self.grid, self.gridLayer))
    self.legoManager = self:AddCityManager(CityLegoBuildingManager.new(self, self.gridLayer))
    self.furnitureManager = self:AddCityManager(CityFurnitureManager.new(self, self.grid, self.gridLayer, self.legoManager))
    self.elementManager =  self:AddCityManager(CityElementManager.new(self, self.grid, self.gridLayer))
    self.cityWorkManager = self:AddCityManager(CityWorkManager.new(self, self.furnitureManager, self.elementManager, self.gridLayer))
    self.gridView = self:AddCityManager(CityGridView.new(self))
    self.staticTilesManager = self:AddCityManager(CityStaticTilesManager.new(self))
    self.zoneManager = self:AddCityManager(CityZoneManager.new(self, self.staticTilesManager))
    self.safeAreaWallMgr = self:AddCityManager(CitySafeAreaWallManager.new(self, self.gridLayer))
    self.farmlandManager = self:AddCityManager(CityFarmlandManager.new(self))
    self.soundManager = self:AddCityManager(CitySoundManager.new(self))
    self.slgLifeBarManager = self:AddCityManager(CitySlgLifeBarManager.new(self))
    self.fogManager = self:AddCityManager(CityFogManager.new(self, self.zoneManager))
    self.creepManager = self:AddCityManager(CityCreepManager.new(self, self.furnitureManager))
    self.petManager = self:AddCityManager(CityPetManager.new(self, self.furnitureManager))
    self.matDissolveManager = self:AddCityManager(CityMaterialDissolveShareManager.new(self))
end

function City:CalculateNeedLoadManagerCount()
    self.needLoadBasicResCount = 0
    self.needLoadDataCount = 0
    self.needLoadViewCount = 0
    for i, v in ipairs(self.orderedManagers) do
        if v:NeedLoadBasicAsset() then
            self.needLoadBasicResCount = self.needLoadBasicResCount + 1
        end
        if v:NeedLoadData() then
            self.needLoadDataCount = self.needLoadDataCount + 1
        end
        if v:NeedLoadView() then
            self.needLoadViewCount = self.needLoadViewCount + 1
        end
    end

    self.hasLoadedBasicResCount = 0
    self.hasLoadedDataCount = 0
    self.hasLoadedViewCount = 0
    self.defaultDescription = I18N.Get("loading_info_loading")
    self.loadDescription = self.defaultDescription
end

function City:SetCityPosition(x, y, UnitsPerTileX, UnitsPerTileZ)
    self.mapX = x * UnitsPerTileX
    self.mapY = y * UnitsPerTileZ
    self.x = 0
    self.y = 0
    self.realWorldCenter = Vector3(self.x + UnitsPerTileX * cityMaxViewSize * 0.5, 0, self.y + UnitsPerTileZ * cityMaxViewSize * 0.5)
    self.mapWorldCenter = Vector3(self.mapX + UnitsPerTileX * cityMaxViewSize * 0.5, 0, self.mapY + UnitsPerTileZ * cityMaxViewSize * 0.5)
    self.worldOffset = Vector3(self.x - self.mapX, 0, self.y - self.mapY)
end

function City:InitStateMachine()
    self.stateMachine = StateMachine.new(true)
    self.stateMachine.allowReEnter = true
    self.stateMachine:AddState(CityConst.STATE_ENTRY, CityStateEntry.new(self))
    self.stateMachine:AddState(CityConst.STATE_EXIT, CityStateExit.new(self))
    self.stateMachine:AddState(CityConst.STATE_NORMAL, OtherCityStateNormal.new(self))
    self.stateMachine:AddState(CityConst.STATE_BUILDING_SELECT, OtherCityStateBuildingSelect.new(self))
    self.stateMachine:AddState(CityConst.STATE_FURNITURE_SELECT, OtherCityStateFurnitureSelect.new(self))
    self.stateMachine:AddState(CityConst.STATE_AIR_VIEW, CityStateAirView.new(self))
end

---@return wds.CastleBrief
function City:GetCastleBrief()
    return g_Game.DatabaseManager:GetEntity(self.uid, DBEntityType.CastleBrief)
end

---@return wds.Castle
function City:LoadCastle()
    local castleBrief = self:GetCastleBrief()
    if castleBrief then
        return castleBrief.Castle
    end
    return nil
end

function City:UpdateCastle()
    self.castle = self:LoadCastle()
end

function City:MarkAsLightRestart()
    self.inRestarting = true
end

---@return CityGridConfig
function City:LoadGridConfig()
    return CityGridConfig.Instance
end

function City:OnCameraLoaded(camera)
    if self.camera ~= nil and self.camera == camera then
        return
    end

    if self:IsMyCity() then
        SdkCrashlytics.RecordCrashlyticsLog("[CityCamera] Set Instance")
    end
    g_Game.SoundManager:SetCustomRTPCValue("bigmap_position_rtpc_x", 100)
    self.camera = camera
    self.camera:AddSizeChangeListener(Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    self.camera:AddTransformChangeListener(Delegate.GetOrCreate(self, self.OnCameraTransfomChanged))
    self:OnCameraSizeChanged(self.cameraSize, self.camera:GetSize())
    self:OnCameraLoadedForManagers(camera)
    self:UpdateSceneCameraAudioListenerPos()
end

function City:OnCameraUnload()
    g_Game.SoundManager:SetCustomRTPCValue("bigmap_position_rtpc_x", 100)
    if self:IsMyCity() then
        SdkCrashlytics.RecordCrashlyticsLog("[CityCamera] Set nil")
    end

    if self.camera == nil then
        return
    end

    self.camera:RemoveSizeChangeListener(Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    self.camera:RemoveTransformChangeListener(Delegate.GetOrCreate(self, self.OnCameraTransfomChanged))
    self.camera = nil
    self:OnCameraUnloadForManagers()
    self:UpdateSceneCameraAudioListenerPos(true)
end

function City:UpdateSceneCameraAudioListenerPos(restoreToDefault)
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene or not scene.mapFoundation then return end
    if restoreToDefault then
        scene.mapFoundation:UpdateSceneAudioListenerPos(nil)
    elseif self.camera then
        local pos = self.camera:GetLookAtPosition()
        scene.mapFoundation:UpdateSceneAudioListenerPos(pos)
    else
        scene.mapFoundation:UpdateSceneAudioListenerPos(nil)
    end
end

---@return BasicCamera|nil
function City:GetCamera()
    return self.camera
end

---@param light CS.UnityEngine.Light
function City:SetKingdomMainLight(light)
    ---@type CS.UnityEngine.Light
    self.kingdomMainLight = light
end

---@param point CS.UnityEngine.Vector3
function City:SetZeroPoint(point)
    self.zeroPoint = point
    if Utils.IsNotNull(self.CityRoot) then
        local rootTrans = self.CityRoot.transform
        rootTrans.position = self:GetCenter()

        local bulidingRoot = rootTrans:Find("building")
        bulidingRoot.position = point
        local decorationRoot = rootTrans:Find("decoration")
        decorationRoot.position = point
        local resourceRoot = rootTrans:Find("resource")
        resourceRoot.position = point
        local npcRoot = rootTrans:Find("npc")
        npcRoot.position = point
        local terrain = rootTrans:Find("CIty_Lowpoly_Root_01")
        terrain.position = point
    end
end

---@param scale number
function City:SetScale(scale)
    self.scale = scale
    if self.CityRoot then
        self.CityRoot.transform.localScale = CS.UnityEngine.Vector3.one * self.scale
    end
end

function City:IsMyCity()
    return false
end

function City:Dispose()
    self:OnCameraUnload()
    self:UnloadView()
    self:UnloadData()
    self:UnloadBasicResource()
    self:OnDispose()
end

function City:OnDispose()
    self.basicDataLoadManager:OnDispose()
end

function City:AddDataChangedListener()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.MsgPath, Delegate.GetOrCreate(self, self.OnCastleModify))
end

function City:RemoveDataChangedListener()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.MsgPath, Delegate.GetOrCreate(self, self.OnCastleModify))
end

---@param entity wds.CastleBrief
function City:OnCastleModify(entity, changeTable)
    if entity.ID ~= self.uid then return end

    local batchEvts = {}
    -- if changeTable.BuildingInfos and self.buildingManager:IsDataReady() then
    --     self:OnBuildingsModify(entity, changeTable.BuildingInfos, batchEvts)
    -- end
    if changeTable.CastleWork and self.cityWorkManager:IsDataReady() then
        self:OnWorkModify(entity, changeTable.CastleWork, batchEvts)
    end
    if changeTable.CastleFurniture and self.furnitureManager:IsDataReady() then
        self:OnFurnitureModify(entity, changeTable.CastleFurniture, batchEvts)
    end
    if changeTable.Zones and self.zoneManager:IsDataReady() then
        self:OnZoneChanged(entity, changeTable.Zones, batchEvts)
    end
    if changeTable.CastleElements and self.elementManager:IsDataReady() then
        self:OnElementModify(entity, changeTable.CastleElements, batchEvts)
    end
    if changeTable.Buildings and self.legoManager:IsDataReady() then
        self:OnLegoModify(entity, changeTable.Buildings, batchEvts)
    end
    if changeTable.CastlePets and self.petManager:IsDataReady() then
        self:OnPetModify(entity, changeTable.CastlePets, batchEvts)
    end
    if changeTable.LastWorkUpdateTime then
        table.insert(batchEvts, {Event = EventConst.CITY_WORK_UPDATE_TIME})
    end
    for i, v in ipairs(batchEvts) do
        g_Game.EventManager:TriggerEvent(v.Event, self, v)
    end
end

function City:AddServerPushListener()
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushZoneRecover, Delegate.GetOrCreate(self, self.OnServerPushZoneRecover))
end

function City:RemoveServerPushListener()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushZoneRecover, Delegate.GetOrCreate(self, self.OnServerPushZoneRecover))
end

---@param isSuccess boolean
---@param rsp wrpc.PushZoneRecoverRequest
function City:OnServerPushZoneRecover(isSuccess, rsp)
    if not isSuccess then return end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ZONE_SERVER_PUSH_RECOVERED, self, rsp.ZoneId, rsp.ElementDataIds)
end

---@return CS.UnityEngine.Vector3
function City:GetCenter()
    return self.realWorldCenter
end

function City:GetKingdomMapPosition()
    self.mapWorldCenter.y = KingdomMapUtils.SampleHeight(self.mapWorldCenter.x, self.mapWorldCenter.z)
    return self.mapWorldCenter
end

function City:WorldOffset()
    return self.worldOffset
end

---@return CS.UnityEngine.GameObject
function City:GetRoot()
    return self.CityRoot
end

function City:LoadFinished()
    return self.resStatus == LoadState.Loaded
end

function City:DataFinished()
    return self.dataStatus == LoadState.Loaded
end

function City:IsGridViewActive()
    return self.gridView.viewStatus == LoadState.Loaded
end

function City:ViewFinished()
    return self.viewStatus == LoadState.Loaded
end

function City:AllLoadFinished()
    return self:LoadFinished() and self:DataFinished() and self:ViewFinished()
end

local layerCity = CS.UnityEngine.LayerMask.NameToLayer("City")
local layerCityStatic = CS.UnityEngine.LayerMask.NameToLayer("CityStatic")
local layerScene3DUI = CS.UnityEngine.LayerMask.NameToLayer("Scene3DUI")
local layerDepthForFog = CS.UnityEngine.LayerMask.NameToLayer("DepthForFog")
local layerMaskCityStatic = CS.UnityEngine.LayerMask.GetMask("CityStatic")

---@param rootTrans CS.UnityEngine.Transform
function City:PostLayerProcess(rootTrans)
    for i = 0, rootTrans.childCount - 1 do
        local child = rootTrans:GetChild(i)
        local layer = child.gameObject.layer
        if layer ~= layerCity and layer ~= layerCityStatic and layer ~= layerScene3DUI and layer ~= layerDepthForFog then
            child.gameObject.layer = layerCity
        end
        self:PostLayerProcess(child)
    end
end

function City:CalculateScaleFromKingdom(UnitsPerTileX)
    local cityBase = self.gridConfig.cellsX * self.gridConfig.unitsPerCellX
    local kingdomBase = UnitsPerTileX * cityMaxViewSize
    return kingdomBase / cityBase
end

function City:CalculateZeroPoint()
    return Vector3.zero
end

---@private
function City:AddElement(id)
    local element = self.elementManager:AddConfigElement(id)
    if element then
        self.grid:AddCell(element:ToCityNode())
    end
end

function City:AddGeneratedElement(id, data)
    local element = self.elementManager:AddGeneratedRes(id, data)
    if element then
        self.grid:AddCell(element:ToCityNode())
    end
end

function City:RemoveElement(x, y)
    if self.elementManager:Exist(x, y) then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_PRE_REMOVE, self, x, y)
        self.elementManager:Remove(x, y)
        self.grid:RemoveCell(x, y)
    end
end

function City:AddSpawnerActiveStatus(spawnerId, status)
    self.elementManager:AddSpawnerActiveStatus(spawnerId, status)
end

function City:RemoveSpawnerActiveStatus(spawnerId)
    self.elementManager:RemoveSpawnerActiveStatus(spawnerId)
end

function City:UpdateSpawnerActiveStatus(spawnerId, status)
    self.elementManager:UpdateSpawnerActiveStatus(spawnerId, status)
end

function City:UpdateElementViewById(id)
    local element = self.elementManager:GetElementById(id)
    if not element then return end

    local x, y = element.x, element.y
    if not self.elementManager:Exist(x, y) then return end

    --- 只需要更新表现层
    self.gridView:OnCellUpdate(self, x, y, 0)
end
function City:UpdateFog()
    self.fogController.CityScale = self.scale and self.scale > 0 and self.scale or 1
    self.fogController:ChangeZoneFogStatus(self.fogManager:GetZoneStatusMap())
end

function City:UpdateMapGridView()
    self.mapGridView:Initialize(self.fogController)
end

function City:SetActive(flag)
    if flag then
        if self.showed then return end

        if self:AllLoadFinished() then
            self.showed = flag
            self:OnEnable()
        else
            self.showAfterLoaded = flag
        end
    else
        if not self.showed then return end

        if self:AllLoadFinished() then
            self.showed = flag
            self:OnDisable()
        else
            self.showAfterLoaded = flag
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_STATE_CHANGED, flag)
end

function City:OnEnable()
    self.CityRoot:SetActive(true)
    self:OnCityActiveForManagers()
    self.mediator:Initialize(self)
    self.seMediator:Initialize()
    if Utils.IsNotNull(self.kingdomMainLight) then
        self.kingdomMainLight.enabled = false
    end
    self:RefreshBorderParams()
    self:PopupOfflineUIMediator()
    self:SwitchFog(true)
    self:UpdateFog()
    local hideRoof = self.cameraSize < CityConst.RoofHideCameraSize
    self:ChangeRoofState(hideRoof)
    self:ChangeWallHideState(false)
    self.stateMachine:ChangeState(CityConst.STATE_ENTRY)

    g_Game.EventManager:AddListener(EventConst.APPLICATION_FOCUS, Delegate.GetOrCreate(self, self.OnApplicationFocus))
    g_Game.ServiceManager:AddResponseCallback(CastleFurnitureLvUpConfirmParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnLvUpConfirm))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushAutoPlaceFurniture, Delegate.GetOrCreate(self, self.OnServerPushPlaceFurnitureAndLook))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SET_ACTIVE, true, self)
    g_Game.EventManager:TriggerEvent(EventConst.ENTER_CITY_TRIGGER)
end

function City:OnCityActiveForManagers()
    for name, manager in pairs(self.managers) do
        manager:OnCityActive()
    end
end

function City:OnDisable()
    table.clear(self.sendingRibbonCutBuildingIds)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SET_ACTIVE, false, self)
    g_Game.ServiceManager:RemoveResponseCallback(CastleFurnitureLvUpConfirmParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnLvUpConfirm))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushAutoPlaceFurniture, Delegate.GetOrCreate(self, self.OnServerPushPlaceFurnitureAndLook))
    g_Game.EventManager:RemoveListener(EventConst.APPLICATION_FOCUS, Delegate.GetOrCreate(self, self.OnApplicationFocus))
    self.stateMachine:ChangeState(CityConst.STATE_EXIT)
    self:DisableCameraBorderCheck()
    self:SwitchFog(false)
    if Utils.IsNotNull(self.kingdomMainLight) then
        self.kingdomMainLight.enabled = true
    end
    self.seMediator:Release()
    self.mediator:Release()
    self:OnCityInactiveForManagers()
    self.CityRoot:SetActive(false)
    self:UnloadViewPartialWhenDisable()
    self.isCloseToBorder = nil
    g_Game.EventManager:TriggerEvent(EventConst.RENDER_FRAME_RATE_OVERRIDE)
end

function City:OnCityInactiveForManagers()
    for name, manager in pairs(self.managers) do
        manager:OnCityInactive()
    end
end

function City:Tick(deltaTime)
    self.stateMachine:Tick(deltaTime)
    if self:IsGridViewActive() then
        self.gridView:Tick(deltaTime)
    end

    ---debug draw
    --if self.unitMoveGridEventProvider then
    --    self.unitMoveGridEventProvider:DebugDrawGrid(self)
    --end
    --if self.unitPositionQuadTree then
    --    self.unitPositionQuadTree:DebugDrawGrid(self)
    --end
end

function City:IsLocationValid(x, y)
    return self.gridConfig:IsLocationValid(x, y) and self.zoneManager:IsZoneRecovered(x, y)
end

function City:IsLocationValidForConstruction(x, y)
    return self:GetMapData():IsLocationValid(x, y) and self:IsLocationValid(x, y)
end

--TODO:增加安全区/室内可建造位置判断
function City:IsLocationValidForFurniture(x, y, furnitureCategory)
    local ret = self:IsLocationValidForConstruction(x, y)
    if not ret then
        return false
    end
    if self:IsInnerBuildingMask(x, y) then
        return true
    end
    return self.safeAreaWallMgr:IsLocationValidForOutDoorFurniture(x, y, furnitureCategory)
end

function City:IsLocationEmpty(x, y)
    return self.gridLayer:IsEmpty(x, y)
end

function City:IsInnerBuildingMask(x, y)
    return self.gridLayer:IsInnerBuildingMask(x, y)
end

---@return boolean 是否需要被迷雾覆盖
function City:IsFogMask(x, y)
    if not self.gridConfig:IsLocationValid(x, y) then
        return true
    end
    local zone = self.zoneManager:GetZone(x, y)
    if zone == nil then
        return true
    end

    return not zone:IsHideFog()
end

function City:IsFogMaskRect(x, y, sizeX, sizeY)
    for i = x, x + sizeX - 1 do
        for j = y, y + sizeY - 1 do
            if not self:IsFogMask(i, j) then
                return false
            end
        end
    end

    return true
end

function City:IsConstruction(x, y)
    local mainCell = self.grid:GetCell(x, y)
    return mainCell and mainCell:IsBuilding()
end

function City:GetBuilding(x, y)
    local mainCell = self.grid:GetCell(x, y)
    if mainCell and mainCell:IsBuilding() then
        return mainCell
    end
    return nil
end

function City:IsSquareValidForBuilding(x, y, sizeX, sizeY)
    for i = x, x + sizeX - 1 do
        for j = y, y + sizeY - 1 do
            if not self:IsLocationValidForConstruction(i, j) then
                return false
            end
        end
    end

    return true
end

function City:IsInLego(x, y)
    return CityGridLayerMask.IsInLego(self.gridLayer:Get(x, y))
end

function City:IsSquareValidForFurniture(x, y, sizeX, sizeY)
    local inLego, outLego = 0, 0
    for i = x, x + sizeX - 1 do
        for j = y, y + sizeY - 1 do
            if not self:IsLocationValidForConstruction(i, j) then
                return false
            end
            if self:IsInLego(i, j) then
                inLego = inLego + 1
            else
                outLego = outLego + 1
            end
        end
    end

    return inLego == 0 or outLego == 0
end

function City:GetFixCoord(x, y, sizeX, sizeY)
    ---todo 考虑区域
    local fixX = math.clamp(x, 0, self.gridConfig.cellsX - sizeX)
    local fixY = math.clamp(y, 0, self.gridConfig.cellsY - sizeY)
    return fixX, fixY
end

---@return CS.UnityEngine.Vector3
function City:GetPlanePositionFromCoord(x, y)
    local anchor = self.zeroPoint
    local scale = self.scale
    local offset = self.gridConfig:GetLocalPosition(x, y)
    return anchor + (offset * scale)
end

---@param serverCoord wds.Vector2F
---@return CS.UnityEngine.Vector3
function City:GetWorldPositionFromServerCoord(serverCoord, skipPostProcess)
    local CameraUtils = require("CameraUtils")
    local planePos = self:GetPlanePositionFromCoord(serverCoord.X, serverCoord.Y)
    local ray = CS.UnityEngine.Ray(planePos + CS.UnityEngine.Vector3.up * 1000, CS.UnityEngine.Vector3.down)
    local point = CameraUtils.GetHitPointOnMeshCollider(ray, layerMaskCityStatic)
    if point == nil then
        point = planePos
    end
    if skipPostProcess then
        return point
    else
        return point + self:GetLegoBuildingBaseOffset(serverCoord.X, serverCoord.Y)
    end
end

---@return CS.UnityEngine.Vector3
function City:GetWorldPositionFromCoord(x, y, skipPostProcess)
    local CameraUtils = require("CameraUtils")
    local planePos = self:GetPlanePositionFromCoord(x, y)
    local offset = self:GetLegoBuildingBaseOffset(x, y)
    local ray = CS.UnityEngine.Ray(planePos + CS.UnityEngine.Vector3.up * 1000, CS.UnityEngine.Vector3.down)
    local point = CameraUtils.GetHitPointOnMeshCollider(ray, layerMaskCityStatic)
    if point == nil then
        point = planePos
    end
    if skipPostProcess then
        return point
    else
        return point + offset
    end
end

---@return CS.UnityEngine.Vector3
function City:GetCenterPlanePositionFromCoord(x, y, sx, sy)
    x = x + 0.5 * sx
    y = y + 0.5 * sy
    return self:GetPlanePositionFromCoord(x, y)
end

---@return CS.UnityEngine.Vector3
function City:GetCenterWorldPositionFromCoord(x, y, sx, sy, skipPostProcess)
    x = x + 0.5 * sx
    y = y + 0.5 * sy
    return self:GetWorldPositionFromCoord(x, y, skipPostProcess)
end

---@param x number
---@param y number
---@param npcConfig CityElementNpcConfigCell
---@return CS.UnityEngine.Vector3
function City:GetElementNpcInteractPos(x,y, npcConfig, skipPostProcess)
    if not npcConfig then
        return self:GetCenterGridEdgeWorldPositionFromCoord(x, y, 1, 1, skipPostProcess)
    end
    local isOffsetOrigin = npcConfig:InteractOffsetOnOrigin()
    local offsetX = npcConfig:InteractOffsetX()
    local offsetY = npcConfig:InteractOffsetY()
    if not isOffsetOrigin then
        return self:GetCenterGridEdgeWorldPositionFromCoord(x + offsetX, y + offsetY, npcConfig:SizeX(), npcConfig:SizeY(), skipPostProcess)
    else
        return self:GetWorldPositionFromCoord(x + offsetX, y + offsetY, skipPostProcess)
    end
end

---@return CS.UnityEngine.Vector3
function City:GetCenterGridEdgeWorldPositionFromCoord(x, y, sx, sy, skipPostProcess)
    if sx < 2 or sy < 2 then
        return self:GetCenterWorldPositionFromCoord(x, y, sx, sy, skipPostProcess)
    end
    x = x + 0.5 * sx - 0.5
    y = y + 0.5 * sy - 0.5
    return self:GetWorldPositionFromCoord(x, y, skipPostProcess)
end

---@param pos CS.UnityEngine.Vector3
---@param notUseFloorInt boolean @default false
---@return number,number
function City:GetCoordFromPosition(pos, notUseFloorInt)
    local anchor = self.zeroPoint
    local scale = self.scale
    local relativePos = (pos - anchor) / scale
    return self.grid:GetCoordFromLocalPosition(relativePos, notUseFloorInt)
end

---@param pos CS.UnityEngine.Vector3
function City:FixHeightWorldPosition(pos, skipPostProcess)
    local planePos = CS.UnityEngine.Vector3(pos.x, self.zeroPoint.y, pos.z)
    local CameraUtils = require("CameraUtils")
    local ray = CS.UnityEngine.Ray(planePos + CS.UnityEngine.Vector3.up * 1000, CS.UnityEngine.Vector3.down)
    local point = CameraUtils.GetHitPointOnMeshCollider(ray, layerMaskCityStatic)
    if point == nil then
        point = planePos
    end

    if skipPostProcess then
        return point
    else
        local x, y = self:GetCoordFromPosition(planePos)
        return point + self:GetLegoBuildingBaseOffset(x, y)
    end
end

function City:ShowMapGridView()
    if self.mapGridViewRoot then
        self.mapGridViewRoot:SetActive(true)
    end
end

function City:HideMapGridView()
    if self.mapGridViewRoot then
        self.mapGridViewRoot:SetActive(false)
    end
end

function City:OnCameraTransfomChanged()
    self:UpdateSceneCameraAudioListenerPos()
    self:AdjustFrameCountWhenCloseBorder()
end

function City:OnCameraSizeChanged(oldSize, newSize)
    if not self.showed then return end

    self.cameraSize = newSize
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnCameraSizeChanged(oldSize, newSize)
    end
    local lerpValue = math.inverseLerp(CityConst.CITY_NEAR_CAMERA_SIZE, CityConst.CITY_FAR_CAMERA_SIZE, newSize)
    g_Game.SoundManager:SetCustomRTPCValue("bigmap_position_rtpc_x", lerpValue * 100)
    if self.roofHide then
        if newSize > CityConst.RoofShowCameraSize then
            self:ChangeRoofState(false)
        end
    else
        if newSize < CityConst.RoofHideCameraSize then
            self:ChangeRoofState(true)
        end
    end
end

---@param position CS.UnityEngine.Vector3 屏幕坐标
---@return number, number, number, CS.UnityEngine.Vector3, CityFurnitureTile, CityCellTile, CityLegoBuildingTile
function City:RaycastAnyTileBase(position)
    local point = self:GetCamera():GetHitPoint(position)
    local x, y = self:GetCoordFromPosition(point)

    local mask = self.gridLayer:Get(x, y)
    local furTile, cellTile, legoTile, doorFurTile
    local count = 0
    if CityGridLayerMask.HasFurniture(mask) and self:IsLocationValid(x, y) then
        local furniture = self.furnitureManager:GetPlaced(x, y)
        if furniture then
            furTile = self.gridView:GetFurnitureTile(furniture.x, furniture.y)
            count = count + 1
        end
    end
    if CityGridLayerMask.IsPlacedCellTile(mask) and self:IsLocationValid(x, y) then
        local mainCell = self.grid:GetCell(x, y)
        if mainCell then
            cellTile = self.gridView:GetCellTile(mainCell.x, mainCell.y)
            count = count + 1
        end
    end
    if CityGridLayerMask.IsInLego(mask) and self:IsLocationValid(x, y) then
        local legoBuilding = self.legoManager:GetLegoBuildingAt(x, y)
        if legoBuilding then
            legoTile = self.gridView:GetLegoTile(legoBuilding.id)
            count = count + 1
        end
    end
    if CityGridLayerMask.IsSafeAreaWall(mask) and self:IsLocationValid(x, y) then
        local furType = ConfigRefer.CityConfig:CityWallFurnitureType()
        if furType > 0 then
            local doorFurniture = self.furnitureManager:GetFurnitureByTypeCfgId(furType)
            if doorFurniture then
                doorFurTile = self.gridView:GetFurnitureTile(doorFurniture.x, doorFurniture.y)
                count = count + 1
            end
        end
    end

    return count, x, y, point, furTile, cellTile, legoTile, doorFurTile
end

---@param position CS.UnityEngine.Vector3 屏幕坐标
---@return CityCellTile,number,number,CS.UnityEngine.Vector3
function City:RaycastNpcTile(position)
    local point = self:GetCamera():GetHitPoint(position)
    local x, y = self:GetCoordFromPosition(point)

    local mask = self.gridLayer:Get(x, y)
    if (CityGridLayerMask.HasNpc(mask) and self.zoneManager:IsZoneHideFog(x, y)) then
        local mainCell = self.grid:GetCell(x, y)
        if mainCell then
            return self.gridView:GetCellTile(mainCell.x, mainCell.y),x,y,point
        end
    end
    return nil,x,y,point
end

---@param position CS.UnityEngine.Vector3 屏幕坐标
---@return CityCellTile,CityFurnitureTile
function City:RaycastTileBaseTwoRet(position)
    local point = self:GetCamera():GetHitPoint(position)
    local x, y = self:GetCoordFromPosition(point)

    local cityCellTile, cityFurnitureTile
    local mask = self.gridLayer:Get(x, y)
    if CityGridLayerMask.HasFurniture(mask) and self:IsLocationValid(x, y) then
        local furniture = self.furnitureManager:GetPlaced(x, y)
        if furniture then
            cityFurnitureTile = self.gridView:GetFurnitureTile(furniture.x, furniture.y)
        end
    end
    if CityGridLayerMask.IsPlacedCellTile(mask) and self:IsLocationValid(x, y)then
        local mainCell = self.grid:GetCell(x, y)
        if mainCell then
            cityCellTile = self.gridView:GetCellTile(mainCell.x, mainCell.y)
        end
    end
    return cityCellTile, cityFurnitureTile
end

---@return CityCellTile,CityFurnitureTile @ResourceTile,FurnitureTile
function City:QueryFurnitureResourceTileAtCoord(x, y)
    if not self:IsLocationValid(x, y) then
        return nil,nil
    end
    local cityCellTile, cityFurnitureTile
    local mask = self.gridLayer:Get(x, y)
    if CityGridLayerMask.HasFurniture(mask)  then
        local furniture = self.furnitureManager:GetPlaced(x, y)
        if furniture then
            cityFurnitureTile = self.gridView:GetFurnitureTile(furniture.x, furniture.y)
        end
    end
    if CityGridLayerMask.HasResource(mask) then
        local mainCell = self.grid:GetCell(x, y)
        if mainCell then
            cityCellTile = self.gridView:GetCellTile(mainCell.x, mainCell.y)
        end
    end
    return cityCellTile,cityFurnitureTile
end

---@param position CS.UnityEngine.Vector3 屏幕坐标
---@return CityFurnitureTile
function City:RaycastFurnitureTile(position)
    local point = self:GetCamera():GetHitPoint(position)
    local x, y = self:GetCoordFromPosition(point)
    if not self:IsLocationValid(x, y) then
        return nil, x, y, point
    end

    local mask = self.gridLayer:Get(x, y)
    if CityGridLayerMask.HasFurniture(mask) then
        local furniture = self.furnitureManager:GetPlaced(x, y)
        if furniture then
            return self.gridView:GetFurnitureTile(furniture.x, furniture.y), x, y, point
        end
    end
    return nil, x, y, point
end

---@param position CS.UnityEngine.Vector3 屏幕坐标
---@return CityCellTile,number,number,CS.UnityEngine.Vector3
function City:RaycastCityCellTile(position)
    local point = self.camera:GetHitPoint(position)
    local x, y = self:GetCoordFromPosition(point)
    if self.gridConfig:IsLocationValid(x, y) then
        local mask = self.gridLayer:Get(x, y)
        if (CityGridLayerMask.IsPlacedCellTileWithoutNpc(mask) and self.zoneManager:IsZoneRecovered(x, y))
                or (CityGridLayerMask.HasNpc(mask) and self.zoneManager:IsZoneExploredOrRecovered(x, y)) then
            local mainCell = self.grid:GetCell(x, y)
            if mainCell then
                return self.gridView:GetCellTile(mainCell.x, mainCell.y),x,y,point
            end
        end
    end
    return nil,x,y,point
end

---@param position CS.UnityEngine.Vector3 @屏幕坐标
---@return CS.UnityEngine.Vector3 @pos on plane
function City:RaycastPostionOnPlane(position)
    return self:GetCamera():GetPlaneHitPoint(position)
end

---@param trigger CityTrigger
function City:OnPressTrigger(trigger)
    if self.stateMachine.currentState then
        return self.stateMachine.currentState:OnPressTrigger(trigger)
    end
end

---@param gesture CS.DragonReborn.TapGesture
function City:OnPressDown(gesture, trigger)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnPressDown(gesture, trigger)
    end
end

---@param gesture CS.DragonReborn.TapGesture
function City:OnPress(gesture)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnPress(gesture)
    end
end

---@param trigger CityTrigger
---@param position CS.UnityEngine.Vector3 @gesture.position
---@return boolean 返回true时不渗透Click
function City:OnClickTrigger(trigger, position)
    if self.stateMachine.currentState then
        return self.stateMachine.currentState:OnClickTrigger(trigger, position)
    end
end

---@param gesture CS.DragonReborn.TapGesture
function City:OnClick(gesture)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnClick(gesture)
    end
end

function City:OnPinch(gesture)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnPinch(gesture)
    end
end

function City:OnClickEmpty()
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnClickEmpty()
    end
end

---@param gesture CS.DragonReborn.DragGesture
function City:OnDragStart(gesture)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnDragStart(gesture)
    end
end

---@param gesture CS.DragonReborn.DragGesture
function City:OnDragUpdate(gesture)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnDragUpdate(gesture)
    end
end

---@param gesture CS.DragonReborn.DragGesture
function City:OnDragEnd(gesture)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnDragEnd(gesture)
    end
end

---@param gesture CS.DragonReborn.TapGesture
function City:OnRelease(gesture)
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnRelease(gesture)
    end
end

function City:RefreshBorderParams()
    if self.editBuilding then
        self:StrictBorderInLegoBuilding(self.editBuilding)
    else
        self:InitBorderParams()
    end
end

function City:InitBorderParams()
    local bottomLeft, topRight = self:GetCameraBorder()
    self.borderMinX, self.borderMinY = bottomLeft.x, bottomLeft.z
    self.borderMaxX, self.borderMaxY = topRight.x, topRight.z

    if self.camera then
        self.camera:EnableBorderCheck(self.borderMinX, self.borderMinY, self.borderMaxX, self.borderMaxY)
    end
end

function City:StrictBorderInLegoBuilding(legoBuilding)
    local bottomLeft, topRight = self:GetCurrentGridBorderWithLego(legoBuilding)
    self.borderMinX, self.borderMinY = bottomLeft.x, bottomLeft.z
    self.borderMaxX, self.borderMaxY = topRight.x, topRight.z

    if self.camera then
        self.camera:EnableBorderCheck(self.borderMinX, self.borderMinY, self.borderMaxX, self.borderMaxY)
    end
end

function City:GetCameraBorder()
    local minX, minY, maxX, maxY = self:GetCurrentGridBorder()
    local planePosBL = self:GetPlanePositionFromCoord(minX, minY)
    local planePosTR = self:GetPlanePositionFromCoord(maxX, maxY)
    return planePosBL, planePosTR
end

function City:GetCurrentGridBorder()
    --- 取出CityConfig配置的最外环
    local minX, minY, maxX, maxY = self:GetCityConfigDefaultBorder()

    --- 取出当前区域解锁情况下的Border信息
    local zMinX, zMinY, zMaxX, zMaxY = self.zoneManager:GetCurrentZoneCityBorder()
    if zMinX == nil then
        return minX, minY, maxX, maxY
    end

    --- Zone解锁区域不能超出CityConfig配置的范围
    minX = math.max(minX, zMinX)
    minY = math.max(minY, zMinY)
    maxX = math.min(maxX, zMaxX)
    maxY = math.min(maxY, zMaxY)
    return minX, minY, maxX, maxY
end

function City:GetCurrentGridBorderWithLego(legoBuilding)
    local minX, minY, maxX, maxY = self:GetBorderFromLegoBuilding(legoBuilding)
    local planePosBL = self:GetPlanePositionFromCoord(minX, minY)
    local planePosTR = self:GetPlanePositionFromCoord(maxX, maxY)
    return planePosBL, planePosTR
end

---@param legoBuilding CityLegoBuilding
function City:GetBorderFromLegoBuilding(legoBuilding)
    --- 取出CityConfig配置的最外环
    local minX, minY, maxX, maxY = self:GetCityConfigDefaultBorder()
    local bMinX, bMinY, bMaxX, bMaxY = legoBuilding:GetBorder()

    --- 取出当前区域解锁情况下的Border信息
    local zMinX, zMinY, zMaxX, zMaxY = self.zoneManager:GetCurrentZoneCityBorder()
    if zMinX == nil then
        zMinX, zMinY, zMaxX, zMaxY = minX, minY, maxX, maxY
    end

    --- 区域不能超出CityConfig配置的范围
    minX = math.max(minX, zMinX, bMinX)
    minY = math.max(minY, zMinY, bMinY)
    maxX = math.min(maxX, zMaxX, bMaxX)
    maxY = math.min(maxY, zMaxY, bMaxY)
    return minX, minY, maxX, maxY
end


function City:GetCityConfigDefaultBorder()
    if ConfigRefer.CityConfig:DefaultCityBorderLength() ~= 2 then
        return 15, 15, 250, 250
    end

    local bl = ConfigRefer.CityConfig:DefaultCityBorder(1)
    local tr = ConfigRefer.CityConfig:DefaultCityBorder(2)
    local x1, y1, x2, y2 = bl:X(), bl:Y(), tr:X(), tr:Y()
    local minX, maxX = math.min(x1, x2), math.max(x1, x2)
    local minY, maxY = math.min(y1, y2), math.max(y1, y2)
    return minX, minY, maxX, maxY
end

---@param vec3 CS.UnityEngine.Vector3
function City:CheckPosition(vec3)
    if not self:LoadFinished() or not self.camera then
        return vec3
    end

    return self:GetClosestPoint(vec3)
end

---@param lookAt CS.UnityEngine.Vector3
function City:GetClosestPoint(lookAt)
    local mapLeft = self.zeroPoint + Vector3(0, 0, self.gridConfig.cellsY * self.gridConfig.unitsPerCellY * self.scale)
    local mapRight = self.zeroPoint + Vector3(self.gridConfig.cellsX * self.gridConfig.unitsPerCellX * self.scale, 0, 0)
    local mapTop = self.zeroPoint + Vector3(self.gridConfig.cellsX * self.gridConfig.unitsPerCellX * self.scale, 0, self.gridConfig.cellsY * self.gridConfig.unitsPerCellY * self.scale)
    local mapBottom = self.zeroPoint

    local screenLeft = self.camera:GetPlaneHitPoint(Vector3(0, self.camera:ScreenHeight() * 0.5))
    local screenRight = self.camera:GetPlaneHitPoint(Vector3(self.camera:ScreenWidth(), self.camera:ScreenHeight() * 0.5))
    local screenTop = self.camera:GetPlaneHitPoint(Vector3(self.camera:ScreenWidth() * 0.5, self.camera:ScreenHeight()))
    local screenBottom = self.camera:GetPlaneHitPoint(Vector3(self.camera:ScreenWidth() * 0.5, 0))

    local dirTop = (screenTop - screenBottom).normalized
    local dirBottom = -dirTop
    local dirRight = (screenRight - screenLeft).normalized
    local dirLeft = -dirRight

    local planeLeft = Plane(dirLeft, mapLeft + dirLeft * self.cameraAreaMarginLeft)
    local planeRight = Plane(dirRight, mapRight + dirRight * self.cameraAreaMarginRight)
    local planeTop = Plane(dirTop, mapTop + dirTop * self.cameraAreaMarginTop)
    local planeBottom = Plane(dirBottom, mapBottom + dirBottom * self.cameraAreaMarginBottom)

    local disScreenLeft = planeLeft:GetDistanceToPoint(screenLeft)
    local disScreenRight = planeRight:GetDistanceToPoint(screenRight)
    local disScreenTop = planeTop:GetDistanceToPoint(screenTop)
    local disScreenBottom = planeBottom:GetDistanceToPoint(screenBottom)

    if (disScreenLeft > 0 and disScreenRight > 0) or (disScreenTop > 0 and disScreenBottom > 0) then
        -- 让相机只看着City正中心
        return
    end

    if disScreenLeft > 0 then
        lookAt = lookAt + disScreenLeft * dirRight
    end

    if disScreenRight > 0 then
        lookAt = lookAt + disScreenRight * dirLeft
    end

    if disScreenTop > 0 then
        lookAt = lookAt + disScreenTop * dirBottom
    end

    if disScreenBottom > 0 then
        lookAt = lookAt + disScreenBottom * dirTop
    end

    return lookAt
end

function City:TryEnterEditMode(legoBuilding, focusConfigId)
    if not self:DataFinished() then
        return
    end

    if self.cameraSize <= CityConst.AIR_VIEW_THRESHOLD then
        self.mediator:EnterEditMode(legoBuilding, focusConfigId)
    else
        if legoBuilding then
            self:StrictBorderInLegoBuilding(legoBuilding)
        end

        local lookAtPosition = self:GetCamera():GetLookAtPosition()
        local x, y = self:GetCoordFromPosition(lookAtPosition)
        if self:IsLocationValid(x, y) then
            self:GetCamera():Zoom(CityConst.CITY_RECOMMEND_CAMERA_SIZE - self.cameraSize, 0.25, function()
                self.mediator:EnterEditMode(legoBuilding, focusConfigId)
            end)
        else
            self:GetCamera():ZoomWithAnchor(CityConst.CITY_RECOMMEND_CAMERA_SIZE - self.cameraSize, self:GetCenter(), 0.25, function()
                self.mediator:EnterEditMode(legoBuilding, focusConfigId)
            end)
        end
    end
end

function City:ChangeRoofState(hideValue)
    local value = hideValue == true
    if value ~= self.roofHide then
        self.roofHide = value
        self.gridView:ChangeAllBuildingRoofState(value)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    end
end

function City:ChangeWallHideState(hideValue)
    local value = hideValue == true
    if value ~= self.wallHide then
        self.wallHide = value
        self.gridView:ChangeAllBuildingWallHide(value)
    end
end

function City:OnWorkModify(entity, changeTable, batchEvts)
    if entity.ID ~= self.uid then return end
    local ret = self.cityWorkManager:OnCastleWorkChanged(entity, changeTable)
    if ret then
        table.insert(batchEvts, ret)
    end
end

---@param entity wds.CastleBrief
function City:OnFurnitureModify(entity, changedData, batchEvts)
    if entity.ID ~= self.uid then return end
    ---@type table<number, wds.CastleFurniture>
    local AddMap
    ---@type table<number, wds.CastleFurniture>
    local RemoveMap
    ---@type table<number, wds.CastleFurniture[]>
    local ChangedMap
    ---@type table<number, boolean>
    local LvUpChangeMap = {}
    ---@type table<number, boolean>
    local UpgradeStateChangeMap = {}
    ---@type table<number, boolean>
    local lockedDirty = {}

    local batchEvt = {Event = EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Add = {}, Remove = {}, Change = {}}
    AddMap, RemoveMap, ChangedMap = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.CastleFurniture)
    RemoveMap, ChangedMap = OnChangeHelper.PostFixChangeMap(entity.Castle.CastleFurniture, RemoveMap, ChangedMap)

    if RemoveMap then
        for singleId, furnitureInfo in pairs(RemoveMap) do
            local x, y = furnitureInfo.Pos.X, furnitureInfo.Pos.Y
            local furniture = self.furnitureManager:StorageFurniture(x, y)
            self:OnStorageFurniture(singleId, furnitureInfo)
            batchEvt.Remove[singleId] = true

            if furniture:IsMainFurniture() then
                self.furnitureManager.mainFurniture = nil
                g_Game.EventManager:TriggerEvent(EventConst.CITY_MAIN_FURNITURE_REMOVE, furniture)
            end

            if furnitureInfo.BuildingId > 0 then
                local score = furniture.furnitureCell:AddScore()
                if score > 0 then
                    local datum = RoomScorePopDatum.new(x + furniture.sizeX * 0.5, y + furniture.sizeY * 0.5, -score)
                    ModuleRefer.RewardModule:ShowResourcePopType(self, datum)
                end
            end
        end
    end

    if AddMap then
        for singleId, furnitureInfo in pairs(AddMap) do
            local furniture = CityFurniture.new(self.furnitureManager, furnitureInfo.ConfigId, singleId, furnitureInfo.Dir)
            self.furnitureManager:PlaceFurniture(furnitureInfo.Pos.X, furnitureInfo.Pos.Y, furniture)
            furniture:MarkIsNew()
            self:OnAddFurniture(singleId, furnitureInfo)
            batchEvt.Add[singleId] = true

            if furniture:IsMainFurniture() then
                self.furnitureManager.mainFurniture = furniture
                g_Game.EventManager:TriggerEvent(EventConst.CITY_MAIN_FURNITURE_ADD, furniture)
            end

            if furnitureInfo.BuildingId > 0 then
                local score = furniture.furnitureCell:AddScore()
                if score > 0 then
                    local datum = RoomScorePopDatum.new(furnitureInfo.Pos.X + furniture.sizeX * 0.5, furnitureInfo.Pos.Y + furniture.sizeY * 0.5, score)
                    ModuleRefer.RewardModule:ShowResourcePopType(self, datum)
                end
            end
        end
    end

    if ChangedMap then
        local batchMoving = {}
        ---@type {id:number, newValue:boolean}[]
        local pollutedDirty = {}
        for singleId, changedInfos in pairs(ChangedMap) do
            if changedInfos[1].Pos.X ~= changedInfos[2].Pos.X or changedInfos[1].Pos.Y ~= changedInfos[2].Pos.Y or changedInfos[1].Dir ~= changedInfos[2].Dir then
                table.insert(batchMoving, changedInfos)
            end
            if changedInfos[1].Polluted ~= changedInfos[2].Polluted then
                table.insert(pollutedDirty, {id = singleId, newValue = changedInfos[2].Polluted})
            end
            if changedInfos[1].Locked ~= changedInfos[2].Locked then
                lockedDirty[singleId] = changedInfos[2].Locked
            end

            local furniture = self.furnitureManager:UpdateFurnitureCfgId(singleId, changedInfos[2].ConfigId)
            self:OnUpdateFurniture(singleId, changedInfos[1], changedInfos[2])
            batchEvt.Change[singleId] = true

            if changedInfos[1].LevelUpInfo.Working ~= changedInfos[2].LevelUpInfo.Working then
                if changedInfos[2].LevelUpInfo.Working then
                    UpgradeStateChangeMap[singleId] = true
                end
            end

            if changedInfos[1].ConfigId ~= changedInfos[2].ConfigId then
                local oldLvCfg = ConfigRefer.CityFurnitureLevel:Find(changedInfos[1].ConfigId)
                local newLvCfg = ConfigRefer.CityFurnitureLevel:Find(changedInfos[2].ConfigId)
                if oldLvCfg:Type() == newLvCfg:Type() and newLvCfg:Level() > oldLvCfg:Level() then
                    LvUpChangeMap[singleId] = true
                end
            end

            local isUpgradingFinished = changedInfos[2].LevelUpInfo.Working and changedInfos[2].LevelUpInfo.CurProgress >= changedInfos[2].LevelUpInfo.TargetProgress
            local oldUpgradingFinished = changedInfos[1].LevelUpInfo.Working and changedInfos[1].LevelUpInfo.CurProgress >= changedInfos[1].LevelUpInfo.TargetProgress

            if isUpgradingFinished and isUpgradingFinished ~= oldUpgradingFinished then
                UpgradeStateChangeMap[singleId] = false
            end

            if furniture:IsMainFurniture() then
                g_Game.EventManager:TriggerEvent(EventConst.CITY_MAIN_FURNITURE_UPDATE, furniture)
            end

            if changedInfos[1].BuildingId ~= changedInfos[2].BuildingId then
                local score = furniture.furnitureCell:AddScore()
                if score > 0 then
                    if changedInfos[1].BuildingId > 0 then
                        local datum = RoomScorePopDatum.new(changedInfos[1].Pos.X + furniture.sizeX * 0.5, changedInfos[1].Pos.Y + furniture.sizeY * 0.5, -score)
                        ModuleRefer.RewardModule:ShowResourcePopType(self, datum)
                    end

                    if changedInfos[2].BuildingId > 0 then
                        local datum = RoomScorePopDatum.new(changedInfos[2].Pos.X + furniture.sizeX * 0.5, changedInfos[2].Pos.Y + furniture.sizeY * 0.5, score)
                        ModuleRefer.RewardModule:ShowResourcePopType(self, datum)
                    end
                end
            elseif changedInfos[2].BuildingId > 0 and lockedDirty[singleId] == false then
                local score = furniture.furnitureCell:AddScore()
                if score > 0 then
                    local datum = RoomScorePopDatum.new(changedInfos[2].Pos.X + furniture.sizeX * 0.5, changedInfos[2].Pos.Y + furniture.sizeY * 0.5, score)
                    ModuleRefer.RewardModule:ShowResourcePopType(self, datum)
                end
            elseif changedInfos[2].BuildingId > 0 and changedInfos[1].ConfigId ~= changedInfos[2].ConfigId then
                local oldLvCfg = ConfigRefer.CityFurnitureLevel:Find(changedInfos[1].ConfigId)
                local newLvCfg = ConfigRefer.CityFurnitureLevel:Find(changedInfos[2].ConfigId)
                if oldLvCfg and newLvCfg then
                    local oldScore = oldLvCfg:AddScore()
                    local newScore = newLvCfg:AddScore()
                    if oldScore ~= newScore then
                        local delta = newScore - oldScore
                        local datum = RoomScorePopDatum.new(changedInfos[2].Pos.X + furniture.sizeX * 0.5, changedInfos[2].Pos.Y + furniture.sizeY * 0.5, delta)
                        ModuleRefer.RewardModule:ShowResourcePopType(self, datum)
                    end
                end
            end
        end
        if #batchMoving > 0 then
            if #batchMoving == 1 then
                local changedInfos = batchMoving[1]
                self.furnitureManager:MovingRotateFurniture(self, changedInfos[1].Pos.X, changedInfos[1].Pos.Y, changedInfos[2])
            else
                self.furnitureManager:BatchMovingRotateFurniture(self, batchMoving)
            end
        end

        if #pollutedDirty > 0 then
            for i, v in ipairs(pollutedDirty) do
                --- 这里没有像Element那样直接操作gridView, 是因为上文有可能有移动家具事件与此事件同时发生, 因此需要按事件先后顺序进入队列
                if v.newValue then
                    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_POLLUTED_IN, v.id)
                else
                    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_POLLUTED_OUT, v.id)
                end
            end
        end
    end
    table.insert(batchEvts, batchEvt)

    if table.nums(LvUpChangeMap) > 0 then
        local lvUpEvt = {Event = EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Change = LvUpChangeMap}
        table.insert(batchEvts, lvUpEvt)
    end

    if table.nums(UpgradeStateChangeMap) > 0 then
        for id, flag in pairs(UpgradeStateChangeMap) do
            if flag then
                table.insert(batchEvts, {Event = EventConst.CITY_FURNITURE_UPGRADE_START, furnitureId = id})
            else
                table.insert(batchEvts, {Event = EventConst.CITY_FURNITURE_UPGRADE_FINISHED, furnitureId = id})
            end
        end
    end

    if table.nums(lockedDirty) > 0 then
        local lockEvt = {Event = EventConst.CITY_BATCH_FURNITURE_LOCK_STATS_CHANGE, Change = lockedDirty}
        table.insert(batchEvts, lockEvt)
    end
end

---@param entity wds.ViewCastleBriefForMap|wds.CastleBrief
function City:OnBuildingsModify(entity, changedData)
    if entity.ID ~= self.uid then return end

    ---@type table<number, wds.CastleBuildingInfo>
    local AddMap = changedData.Add
    ---@type table<number, wds.CastleBuildingInfo>
    local RemoveMap = changedData.Remove
    ---@type table<number, wds.CastleBuildingInfo[]>
    local ChangedMap = {}
    local batchEvt = {Event = EventConst.CITY_BATCH_WDS_CASTLE_BUILDING_UPDATE, Add = {}, Remove = {}, Change = {}}

    if AddMap and RemoveMap then
        for k, v in pairs(AddMap) do
            if RemoveMap[k] then
                ChangedMap[k] = {RemoveMap[k], v}
            end
        end
    end

    if RemoveMap then
        for tileId, buildingInfo in pairs(RemoveMap) do
            if not ChangedMap[tileId] then
                self.buildingManager:RemoveBuilding(tileId)
                self:OnStorageBuilding(tileId, buildingInfo)
                batchEvt.Remove[tileId] = true
            end
        end
    end

    if AddMap then
        for tileId, buildingInfo in pairs(AddMap) do
            if not ChangedMap[tileId] then
                self.buildingManager:PlaceBuilding(CityBuilding.new(self.buildingManager, tileId, buildingInfo))
                self:OnAddBuilding(tileId, buildingInfo)
                batchEvt.Add[tileId] = true
            end
        end
    end

    if ChangedMap then
        for tileId, changedInfos in pairs(ChangedMap) do
            local building = self.buildingManager:GetBuilding(tileId)
            if building == nil then
                self.buildingManager:PlaceBuilding(CityBuilding.new(self.buildingManager, tileId, changedInfos[2]))
                self:OnAddBuilding(tileId, changedInfos[2])
                goto continue
            end

            if changedInfos[1].BuildingType ~= changedInfos[2].BuildingType then
                Error(("建筑 %d 类型发生变化, from %d to %d"):format(tileId, changedInfos[1].BuildingType, changedInfos[2].BuildingType))
                goto continue
            end

            if changedInfos[1].Pos.X ~= changedInfos[2].Pos.X or changedInfos[1].Pos.Y ~= changedInfos[2].Pos.Y then
                self.buildingManager:MoveBuilding(tileId, changedInfos[1].Pos.X, changedInfos[1].Pos.Y, changedInfos[2].Pos.X, changedInfos[2].Pos.Y)
            end

            local oldStatus = CityUtils.IsStatusReadyForFurniture(changedInfos[1].Status)
            local newStatus = CityUtils.IsStatusReadyForFurniture(changedInfos[2].Status)
            if oldStatus ~= newStatus then
                local cell = self.grid:GetCell(changedInfos[2].Pos.X, changedInfos[2].Pos.Y)
                self.gridLayer:PlusLayerByBuilding(cell)
            end

            self.buildingManager:UpdateBuilding(tileId)
            self:OnUpdateBuilding(tileId, changedInfos[1], changedInfos[2])
            batchEvt.Change[tileId] = true
            ::continue::
        end
    end
end

---@param buildingInfo wds.CastleBuildingInfo
function City:OnStorageBuilding(tileId, buildingInfo)

end

---@param buildingInfo wds.CastleBuildingInfo
function City:OnAddBuilding(tileId, buildingInfo)
    if not self:ViewFinished() then return end
    local building = self.buildingManager:GetBuilding(tileId)
    if building then
        self.soundManager:PlayPutDownSound(building:CenterPos())
    end
end

---@param oldInfo wds.CastleBuildingInfo
---@param newInfo wds.CastleBuildingInfo
function City:OnUpdateBuilding(tileId, oldInfo, newInfo)
    if not self:ViewFinished() then return end

    local building = self.buildingManager:GetBuilding(tileId)
    if not building then return end

    if oldInfo.Status ~= newInfo.Status then
        if oldInfo.Status == wds.enum.CastleBuildingStatus.CastleBuildingStatus_Upgrading then
            self.soundManager:StopUpgradingBuilding(building)
        elseif newInfo.Status == wds.enum.CastleBuildingStatus.CastleBuildingStatus_Upgrading then
            self.soundManager:PlayUpgradingBuilding(building)
        end
    end

    if oldInfo.Pos.X ~= newInfo.Pos.X or oldInfo.Pos.Y ~= newInfo.Pos.Y then
        self.soundManager:PlayPutDownSound(building:CenterPos())
    end
end

---@param furnitureInfo wds.CastleFurniture
function City:OnStorageFurniture(tileId, furnitureInfo)

end

---@param furnitureInfo wds.CastleFurniture
function City:OnAddFurniture(tileId, furnitureInfo)
    if not self:ViewFinished() then return end

    local furniture = self.furnitureManager:GetFurnitureById(tileId)
    if furniture then
        self.soundManager:PlayPutDownSound(furniture:CenterPos())
        self.furnitureManager:PlayPutDownVfx(furniture)
    end
end

---@param oldInfo wds.CastleFurniture
---@param newInfo wds.CastleFurniture
function City:OnUpdateFurniture(tileId, oldInfo, newInfo)
    if not self:ViewFinished() then return end

    if oldInfo.Pos.X ~= newInfo.Pos.X or oldInfo.Pos.Y ~= newInfo.Pos.Y then
        local furniture = self.furnitureManager:GetFurnitureById(tileId)
        if furniture then
            self.soundManager:PlayPutDownSound(furniture:CenterPos())
        end
    end

    if oldInfo.ConfigId ~= newInfo.ConfigId then
        local furniture = self.furnitureManager:GetFurnitureById(tileId)
        if furniture then
            self.furnitureManager:TryStartFurnitureAutoWork(furniture)
        end
    end
end

---@param entity wds.ViewCastleBriefForMap|wds.CastleBrief
function City:OnZoneChanged(entity, changedData)
    if entity.ID ~= self.uid then return end

    if changedData.Add then
        for k, v in pairs(changedData.Add) do
            local zone = self.zoneManager:GetZoneById(k)
            local lastStatus = zone.status
            zone:UpdateStatus(v)
            self.zoneManager:OnZoneChangedStatus(zone, lastStatus, zone.status)
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ZONE_STATUS_CHANGED, self, k, lastStatus, zone.status)
        end
        self.zoneManager:RefreshZonePops()
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, self, changedData.Add)
    end
    self:RefreshBorderParams()
    self.elementManager:RefreshAllSpawnerBubbleTileShow()
end

function City:SeExploreZoneChanged(exploreZoneId)
    local changedZones = self.zoneManager:SeExploreZoneChanged(exploreZoneId)
    local dummyChangeData = {}
    for zoneId, zone in pairs(changedZones) do
        self.zoneManager:OnZoneChangedStatus(zone, zone.status, zone.status)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ZONE_STATUS_CHANGED, self, zoneId, zone.status, zone.status)
        dummyChangeData[zoneId] = zone.status
    end
    self.zoneManager:RefreshZonePops()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, self, dummyChangeData)
    self:RefreshBorderParams()
    self.elementManager:RefreshAllSpawnerBubbleTileShow()
end

function City:LocalAddSeExploreZone(exploreZoneId)
    local changedZones = self.zoneManager:LocalAddSeExploreZone(exploreZoneId)
    local dummyChangeData = {}
    for zoneId, zone in pairs(changedZones) do
        self.zoneManager:OnZoneChangedStatus(zone, zone.status, zone.status)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ZONE_STATUS_CHANGED, self, zoneId, zone.status, zone.status)
        dummyChangeData[zoneId] = zone.status
    end
    self.zoneManager:RefreshZonePops()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, self, dummyChangeData)
    self:RefreshBorderParams()
    self.elementManager:RefreshAllSpawnerBubbleTileShow()
end

---@param entity wds.ViewCastleBriefForMap|wds.CastleBrief
function City:OnElementStatusMapChanged(entity, changedData, batchEvt)
    if entity.ID ~= self.uid then return end

    local AddMap, RemoveMap, ChangedMap = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    RemoveMap, ChangedMap = OnChangeHelper.PostFixChangeMap(entity.Castle.CastleElements.Status, RemoveMap, ChangedMap)

    if RemoveMap then
        for k, v in pairs(RemoveMap) do
            if not ChangedMap[k] then
                for i = 0, 0x3f do
                    local mask = 1 << i
                    if (v & mask) ~= 0 then
                        local id = tonumber(k) * 0x40 + i
                        -- 长出资源
                        self:AddElement(id)
                        batchEvt.Add[id] = true
                    end
                end
            end
        end
    end

    if ChangedMap then
        for k, v in pairs(ChangedMap) do
            local oldValue, newValue = v[1], v[2]
            local diff = oldValue ~ newValue
            for i = 0, 0x3f do
                local mask = 1 << i
                if (diff & mask) ~= 0 then
                    local id = tonumber(k) * 0x40 + i
                    if (oldValue & mask) ~= 0 then
                        -- 长出资源
                        self:AddElement(id)
                        batchEvt.Add[id] = true
                    else
                        -- 抹掉资源
                        local cell = ConfigRefer.CityElementData:Find(id)
                        if not cell then
                            Error(("Can't find ID:%d CityElementData"):format(id))
                        else
                            local x, y = cell:Pos():X(), cell:Pos():Y()
                            self:RemoveElement(x, y)
                            batchEvt.Remove[id] = true
                        end
                    end
                end
            end
        end
    end

    if AddMap then
        for k, v in pairs(AddMap) do
            for i = 0, 0x3f do
                local mask = 1 << i
                if (v & mask) ~= 0 then
                    local id = tonumber(k) * 0x40 + i
                    -- 抹掉资源
                    local cell = ConfigRefer.CityElementData:Find(id)
                    if not cell then
                        Error(("Can't find ID:%d CityElementData"):format(id))
                    else
                        local x, y = cell:Pos():X(), cell:Pos():Y()
                        self:RemoveElement(x, y)
                        batchEvt.Remove[id] = true
                    end
                end
            end
        end
    end
end

---@param entity wds.CastleBrief
function City:OnGeneratedResourceMapChanged(entity, changeData, batchEvt)
    if entity.ID ~= self.uid then return end

    local AddMap, RemoveMap, ChangeMap = OnChangeHelper.GenerateMapFieldChangeMap(changeData, wds.CastleResourcePoint)
    RemoveMap, ChangeMap = OnChangeHelper.PostFixChangeMap(entity.Castle.CastleElements.GeneratedResourcePoint, RemoveMap, ChangeMap)
    if AddMap then
        for id, data in pairs(AddMap) do
            self:AddGeneratedElement(id, data)
            batchEvt.Add[id] = true
        end
    end

    if RemoveMap then
        for id, data in pairs(RemoveMap) do
            self:RemoveElement(data.Pos.X, data.Pos.Y)
            batchEvt.Remove[id] = true
        end
    end

    local posChanged = {}
    if ChangeMap then
        for id, wrap in pairs(ChangeMap) do
            local oldData, newData = wrap[1], wrap[2]
            if oldData.Pos.X ~= newData.Pos.X or oldData.Pos.Y ~= newData.Pos.Y then
                posChanged[id] = wrap
                batchEvt.Change[id] = true
            end
        end
    end

    for id, wrap in pairs(posChanged) do
        local oldData = wrap[1]
        self:RemoveElement(oldData.Pos.X, oldData.Pos.Y)
    end

    for id, wrap in pairs(posChanged) do
        local newData = wrap[2]
        self:AddGeneratedElement(id, newData)
    end
end

---@param entity wds.CastleBrief
function City:OnElementModify(entity, changeTable, batchEvts)
    if entity.ID ~= self.uid then return end

    local batchEvt = {Event = EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Add = {}, Remove = {}, Change = {}}
    if changeTable.Status then
        self:OnElementStatusMapChanged(entity, changeTable.Status, batchEvt)
    end

    if changeTable.GeneratedResourcePoint then
        self:OnGeneratedResourceMapChanged(entity, changeTable.GeneratedResourcePoint, batchEvt)
    end

    if changeTable.HiddenElements then
        self:HiddenMapModify(entity, changeTable.HiddenElements, batchEvt)
    end

    if changeTable.PollutedElements then
        self:PollutedElementsModify(entity, changeTable.PollutedElements, batchEvt)
    end
    if changeTable.ActivatedSpawner then
        self:ActivatedSpawnerModify(entity, changeTable.ActivatedSpawner, batchEvt)
    end
    table.insert(batchEvts, batchEvt)
end

function City:HiddenMapModify(entity, changedData, batchEvt)
    if entity.ID ~= self.uid then return end

    local AddMap, RemoveMap, ChangeMap = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    RemoveMap, ChangeMap = OnChangeHelper.PostFixChangeMap(entity.Castle.CastleElements.HiddenElements, RemoveMap, ChangeMap)

    if not RemoveMap then return end
    for id, element in pairs(self.elementManager.hiddenMap) do
        if RemoveMap[element.id] ~= nil and not batchEvt.Remove[element.id] then
            self.elementManager.elementMap:Add(element.x, element.y, element)
            self.grid:AddCell(element:ToCityNode(true))
            if element:IsResource() then
                self.elementManager.eleResHashMap[element.id] = element
                element:RegisterInteractPoints()
            elseif element:IsNpc() then
                self.elementManager.eleNpcHashMap[element.id] = element
                element:RegisterInteractPoints()
            end
            batchEvt.Add[element.id] = true
        end
    end

    for id, _ in pairs(RemoveMap) do
        self.elementManager.hiddenMap[id] = nil
    end
end

function City:PollutedElementsModify(entity, changeData, batchEvt)
    if entity.ID ~= self.uid then return end

    local AddMap, RemoveMap, ChangedMap = OnChangeHelper.GenerateMapFieldChangeMap(changeData)
    RemoveMap, ChangedMap = OnChangeHelper.PostFixChangeMap(entity.Castle.CastleElements.PollutedElements, RemoveMap, ChangedMap)

    if AddMap then
        for id, value in pairs(AddMap) do
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_POLLUTED_IN, id)
            self:UpdateElementViewById(id)
            batchEvt.Change[id] = true
        end
    end

    if RemoveMap then
        for id, value in pairs(RemoveMap) do
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_POLLUTED_OUT, id)
            self:UpdateElementViewById(id)
            batchEvt.Change[id] = true
        end
    end

    if ChangedMap then
        for id, value in pairs(ChangedMap) do
            if value[2] then
                g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_POLLUTED_IN, id)
            else
                g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_POLLUTED_OUT, id)
            end
            self:UpdateElementViewById(id)
            batchEvt.Change[id] = true
        end
    end
end

---@param entity wds.CastleBrief
function City:ActivatedSpawnerModify(entity, changeData, batchEvt)
    if entity.ID ~= self.uid then return end
    local AddMap, RemoveMap, ChangedMap = OnChangeHelper.GenerateMapFieldChangeMap(changeData)
    RemoveMap, ChangedMap = OnChangeHelper.PostFixChangeMap(entity.Castle.CastleElements.ActivatedSpawner, RemoveMap, ChangedMap)

    if AddMap then
        for id, value in pairs(AddMap) do
            self:AddSpawnerActiveStatus(id, value)
            batchEvt.Change[id] = true
        end
    end

    if RemoveMap then
        for id, _ in pairs(RemoveMap) do
            self:RemoveSpawnerActiveStatus(id)
            batchEvt.Change[id] = true
        end
    end

    if ChangedMap then
        for id, value in pairs(ChangedMap) do
            self:UpdateSpawnerActiveStatus(id, value[2])
            batchEvt.Change[id] = true
        end
    end
end

function City:OnLegoModify(entity, changeTable, batchEvts)
    if entity.ID ~= self.uid then return end

    self.legoManager:OnLegoBuildingChanged(entity, changeTable, batchEvts)
end

function City:OnPetModify(entity, changeTable, batchEvts)
    if entity.ID ~= self.uid then return end

    local batchEvt = self.petManager:OnCastlePetsChanged(entity, changeTable)
    if batchEvt then
        table.insert(batchEvts, batchEvt)
    end
end

---@return CityCellTile
function City:GetCellTileFromBuildingId(id)
    if self.gridView.city ~= self then
        return nil
    end

    local castle = self:GetCastle()
    if castle == nil then
        return nil
    end

    local building = castle.BuildingInfos[id]
    if building == nil then
        return nil
    end

    return self.gridView.cellTiles:Get(building.Pos.X, building.Pos.Y)
end

---@return wds.Castle
function City:GetCastle()
    return self.castle
end

function City:SwitchFog(value)
    if self.fogController then
        self.fogController:SwitchFog(value)
    end
end

---@param cellTile CityCellTile
---@return CityFurnitureTile[]|nil
function City:GetRelativeFurnitureTile(cellTile)
    local tiles = {}
    local gridCell = cellTile:GetCell()
    if gridCell == nil then
        return tiles
    end

    local furniture = self.furnitureManager:GetRelativeFurniture(gridCell)
    for k, v in pairs(furniture) do
        local tile = self.gridView:GetFurnitureTile(v.x, v.y)
        if tile then
            table.insert(tiles, tile)
        end
    end
    return tiles
end

function City:GetSuitableIdleState(cameraSize)
    if self.editMode then
        return CityConst.STATE_EDIT_IDLE
    else
        return CityConst.STATE_NORMAL
    end
end

---@param legoBuilding CityLegoBuilding
function City:EnterEditMode(legoBuilding)
    self.editMode = true
    self.editBuilding = legoBuilding
    self.enableMovingLego = false
    self.stateMachine:ChangeState(CityConst.STATE_EDIT_IDLE)
    -- self:ChangeWallHideState(true)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_EDIT_MODE_CHANGE, true)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    if self.editBuilding ~= nil then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_MAP_GRID_ONLY_SHOW_IN_BUILDING)
    else
        g_Game.EventManager:TriggerEvent(EventConst.CITY_MAP_GRID_DEFAULT)
    end
end

function City:ExitEditMode()
    self.editMode = false
    self.editBuilding = nil
    self.enableMovingLego = false
    self.stateMachine:ChangeState(self:GetSuitableIdleState(self.cameraSize))
    -- self:ChangeWallHideState(false)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_EDIT_MODE_CHANGE, false)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
end

function City:IsEditMode()
    return self.editMode
end

function City:IsInSeBattleMode()
    return false
end

function City:IsInSingleSeExplorerMode()
    return false
end

function City:IsInRecoverZoneEffectMode()
    return false
end

function City:RibbonCut(bulidingId)
    if self.sendingRibbonCutBuildingIds[bulidingId] then
        return
    end
    self.sendingRibbonCutBuildingIds[bulidingId] = true
    local param = CastleBuildingActivateParameter.new()
    param.args.BuildingId = bulidingId
    param:SendOnceCallback(nil, nil, nil, function(cmd, isSuccess, rsp)
        self.sendingRibbonCutBuildingIds[bulidingId] = nil
    end)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_cleanup)
    self:GetCamera():ZoomToMaxSize(0.5)
end

---@param furniture CityFurniture
function City:StorageFurniture(furniture)
    local lvCfgId = furniture.furnitureCell:Id()
    local msg = CastleDelFurnitureParameter.new()
    msg.args.Id = furniture.singleId
    msg:SendWithFullScreenLockAndOnceCallback(nil, true, function()
        self.furnitureManager:ClearRedPoint(lvCfgId)
    end)
end

---@param workerData CityCitizenData
---@param uiLockable CS.UnityEngine.Transform
function City:UpgradeBuilding(buildingId, x, y, workerData, uiLockable)
    local msg = CastleBuildingUpgradeParameter.new()
    msg.args.BuildingInstanceId = buildingId
    msg.args.NewPos = wds.Point2.New(x, y)
    msg.args.CitizenId = workerData ~= nil and workerData._id or 0
    msg:SendOnceCallback(uiLockable, nil, nil)
end

---@param tile CityTileBase
function City:LookAtTile(tile, duration, simClick)
    if not tile then return end

    local cell = tile:GetCell()
    if not cell then return end

    local x, y = cell.x + cell.sizeX * 0.5, cell.y + cell.sizeY * 0.5
    self:LookAtCoord(x, y, duration, simClick)
end

function City:LookAtCoord(x, y, duration, simClick)
    local pos = self:GetCenterWorldPositionFromCoord(x, y, 1, 1)

    if simClick then
        self.camera:LookAt(pos, duration, function()
            local screenPos = self.camera.mainCamera:WorldToScreenPoint(pos)
            screenPos.z = 0
            local p = {position = screenPos}
            self.mediator:OnClick(p)
            self.seMediator:OnClick(p)
        end)
    else
        self.camera:LookAt(pos, duration)
    end
end

---@param typ number BuildingType
---@return CityCellTile[]
function City:GetCityCellTilesByBuildingType(typ)
    local ret = {}
    if typ == nil or not self:DataFinished() or not self:IsGridViewActive() then
        return ret
    end

    for id, building in pairs(self.buildingManager.buildingMap) do
        if building.info.BuildingType == typ then
            local tile = self.gridView.cellTiles:Get(building.x, building.y)
            if tile then
                table.insert(ret, tile)
            end
        end
    end

    return ret
end

---@param typ number FurnitureTypeId
---@return CityFurnitureTile[]
function City:GetFurnitureTilesByFurnitureType(typ)
    local ret = {}
    if typ == nil or not self:DataFinished() or not self:IsGridViewActive() then
        return ret
    end

    ---@param tile CityFurnitureTile
    for x, y, tile in self.gridView.furnitureTiles:pairs() do
        local buildingType = tile:GetFurnitureType()
        if buildingType == typ then
            table.insert(ret, tile)
        end
    end

    return ret
end

---@param id number CityElementNpc-Id
---@param excludeInFog boolean 是否忽略掉被雾覆盖的
---@return CityCellTile[]
function City:GetCellTilesByNpcConfigId(id, excludeInFog)
    local ret = {}
    if id == nil or not self:DataFinished() or not self:IsGridViewActive() then
        return ret
    end

    ---@param tile CityCellTile
    for x, y, tile in self.gridView.cellTiles:pairs() do
        local cell = tile:GetCell()
        if cell == nil or not cell:IsNpc() then
            goto continue
        end

        local element = ConfigRefer.CityElementData:Find(cell.configId)
        if element:ElementId() == id then
            if excludeInFog then
                for i = cell.x, cell.x + cell.sizeX - 1 do
                    for j = cell.y, cell.y + cell.sizeY - 1 do
                        if self:IsFogMask(i, j) then
                            goto continue
                        end
                    end
                end
            end
            table.insert(ret, tile)
        end
        ::continue::
    end
    return ret
end

---@param id number CityElementResource-Id
---@param excludeInFog boolean 是否忽略掉被雾覆盖的
---@return CityCellTile[]
function City:GetCellTilesByResourceConfigId(id, excludeInFog)
    local ret = {}
    if id == nil or not self:DataFinished() or not self:IsGridViewActive() then
        return ret
    end

    ---@param tile CityCellTile
    for x, y, tile in self.gridView.cellTiles:pairs() do
        local cell = tile:GetCell()
        if cell == nil or tile:IsPolluted() or not cell:IsResource() then
            goto continue
        end

        local element = self.elementManager:GetElementById(cell.tileId)
        if element.resCfgId == id then
            if excludeInFog then
                for i = cell.x, cell.x + cell.sizeX - 1 do
                    for j = cell.y, cell.y + cell.sizeY - 1 do
                        if self:IsFogMask(i, j) then
                            goto continue
                        end
                    end
                end
            end
            table.insert(ret, tile)
        end
        ::continue::
    end
    return ret
end

---@param id number CityElementResource-Id
---@param excludeInFog boolean 是否忽略掉被雾覆盖的
---@return CityCellTile[]
function City:GetCellTilesByCreepConfigId(id, excludeInFog)
    local ret = {}
    if id == nil or not self:DataFinished() or not self:IsGridViewActive() then
        return ret
    end

    ---@param tile CityCellTile
    for x, y, tile in self.gridView.cellTiles:pairs() do
        local cell = tile:GetCell()
        if cell == nil or not cell:IsCreepNode() then
            goto continue
        end

        local element = ConfigRefer.CityElementData:Find(cell.configId)
        if element:ElementId() ~= id then
            goto continue
        end

        if excludeInFog then
            for i = cell.x, cell.x + cell.sizeX - 1 do
                for j = cell.y, cell.y + cell.sizeY - 1 do
                    if self:IsFogMask(i, j) then
                        goto continue
                    end
                end
            end
        end
        table.insert(ret, tile)
        ::continue::
    end
    return ret
end

---@param type number CityElementResource-ResourceType
---@param excludeInFog boolean 是否忽略掉被雾覆盖的
---@return CityCellTile[]
function City:GetCellTilesByResourceType(type, excludeInFog)
    local ret = {}
    if type == nil or not self:DataFinished() or not self:IsGridViewActive() then
        return ret
    end

    ---@param tile CityCellTile
    for x, y, tile in self.gridView.cellTiles:pairs() do
        local cell = tile:GetCell()
        if cell == nil or tile:IsPolluted() or not cell:IsResource() then
            goto continue
        end

        local element = self.elementManager:GetElementById(cell.tileId)
        if element and element.resourceConfigCell:ResourceType() == type then
            if excludeInFog then
                for i = cell.x, cell.x + cell.sizeX - 1 do
                    for j = cell.y, cell.y + cell.sizeY - 1 do
                        if self:IsFogMask(i, j) then
                            goto continue
                        end
                    end
                end
            end
            table.insert(ret, tile)
        end
        ::continue::
    end
    return ret
end

---@param type number CityElementResource-CityElementResType
---@param excludeInFog boolean 是否忽略掉被雾覆盖的
---@return CityCellTile[]
function City:GetCellTilesByCityElementResType(type, excludeInFog)
    local ret = {}
    if type == nil or not self:DataFinished() or not self:IsGridViewActive() then
        return ret
    end

    ---@param tile CityCellTile
    for x, y, tile in self.gridView.cellTiles:pairs() do
        local cell = tile:GetCell()
        if cell == nil or tile:IsPolluted() or not cell:IsResource() then
            goto continue
        end

        local element = self.elementManager:GetElementById(cell.tileId)
        if element and element.resourceConfigCell:Type() == type then
            if excludeInFog then
                for i = cell.x, cell.x + cell.sizeX - 1 do
                    for j = cell.y, cell.y + cell.sizeY - 1 do
                        if self:IsFogMask(i, j) then
                            goto continue
                        end
                    end
                end
            end
            table.insert(ret, tile)
        end
        ::continue::
    end
    return ret
end


---@param id number CityElementSpawner-Id
---@return CS.UnityEngine.Vector3
function City:GetWorldPositionBySpawnerConfigId(id)
    for i, v in ConfigRefer.CityElementData:pairs() do
        if v:Type() == CityElementType.Spawner and v:ElementId() == id then
            local x = v:Pos():X()
            local y = v:Pos():Y()
            return self:GetWorldPositionFromCoord(x, y)
        end
    end
    return nil
end

function City:HasWallOrDoorAtTop(tileX, tileY)
    local worldIdx = tileY + 1
    local worldNumber = tileX
    return self.buildingManager:HasHWallOrDoor(worldIdx, worldNumber)
end

function City:HasWallOrDoorAtBottom(tileX, tileY)
    local worldIdx = tileY
    local worldNumber = tileX
    return self.buildingManager:HasHWallOrDoor(worldIdx, worldNumber)
end

function City:HasWallOrDoorAtLeft(tileX, tileY)
    local worldIdx = tileX
    local worldNumber = tileY
    return self.buildingManager:HasVWallOrDoor(worldIdx, worldNumber)
end

function City:HasWallOrDoorAtRight(tileX, tileY)
    local worldIdx = tileX + 1
    local worldNumber = tileY
    return self.buildingManager:HasVWallOrDoor(worldIdx, worldNumber)
end

function City:GetWallAtTop(tileX, tileY)
    local worldIdx = tileY + 1
    local worldNumber = tileX
    return self.buildingManager:GetHWall(worldIdx, worldNumber)
end

function City:GetWallAtBottom(tileX, tileY)
    local worldIdx = tileY
    local worldNumber = tileX
    return self.buildingManager:GetHWall(worldIdx, worldNumber)
end

function City:GetWallAtLeft(tileX, tileY)
    local worldIdx = tileX
    local worldNumber = tileY
    return self.buildingManager:GetVWall(worldIdx, worldNumber)
end

function City:GetWallAtRight(tileX, tileY)
    local worldIdx = tileX + 1
    local worldNumber = tileY
    return self.buildingManager:GetVWall(worldIdx, worldNumber)
end

function City:GetDoorAtTop(tileX, tileY)
    local worldIdx = tileY + 1
    local worldNumber = tileX
    return self.buildingManager:GetHDoor(worldIdx, worldNumber)
end

function City:GetDoorAtBottom(tileX, tileY)
    local worldIdx = tileY
    local worldNumber = tileX
    return self.buildingManager:GetHDoor(worldIdx, worldNumber)
end

function City:GetDoorAtLeft(tileX, tileY)
    local worldIdx = tileX
    local worldNumber = tileY
    return self.buildingManager:GetVDoor(worldIdx, worldNumber)
end

function City:GetDoorAtRight(tileX, tileY)
    local worldIdx = tileX + 1
    local worldNumber = tileY
    return self.buildingManager:GetVDoor(worldIdx, worldNumber)
end

function City:GetRoomAt(x, y)
    return self.buildingManager:GetRoomAt(x, y)
end

function City:GetMapData()
    return require("CityMapBinaryData").Instance
end

function City:GetCameraMaxSize()
    local near, far = self.zoneManager:GetCurrentZoneCameraSize()
    if near and near > 0 and far and far > 0 then
        return near, far
    end
    return CityConst.CITY_NEAR_CAMERA_SIZE, CityConst.CITY_FAR_CAMERA_SIZE
end

function City:SetupFogRenderFeature(feature)
    self.fogFeature = feature
    if self.fogController then
        self.fogController.CityScale = self.scale and self.scale > 0 and self.scale or 1
        self.fogController:SetupRenderFeature(self.fogFeature)
    end
end

---@param go CS.UnityEngine.GameObject
---@param duration number
---@param safeArea {minX:number, minY:number, maxX:number, maxY:number}
function City:MoveGameObjIntoCamera(go, duration, safeArea)
    local flag, minV, maxV = go:GetChildrenMeshBoundsViewport(self:GetCamera().mainCamera)
    if not flag then return end

    local left, right, bottom, top = safeArea.minX, safeArea.maxX, safeArea.minY, safeArea.maxY
    local minX, minY, maxX, maxY = minV.x, minV.y, maxV.x, maxV.y

    local lm = math.min(minX - left, 0)
    local rm = math.max(maxX - right, 0)
    local bm = math.min(minY - bottom, 0)
    local tm = math.max(maxY - top, 0)

    if lm == 0 and rm == 0 and bm == 0 and tm == 0 then return end

    local xOffset = 0
    local yOffset = 0

    if maxY - minY > top - bottom then
        local center = (top + bottom) * 0.5
        local safeCenter = (maxY + minY) * 0.5
        yOffset = safeCenter - center
    else
        yOffset = math.abs(bm) > math.abs(tm) and bm or tm
        if yOffset > 0 then
            yOffset = yOffset + 0.1
        end
    end

    if maxX - minX > right - left then
        local center = (left + right) * 0.5
        local safeCenter = (maxX + minX) * 0.5
        xOffset = safeCenter - center
    else
        xOffset = math.abs(lm) > math.abs(rm) and lm or rm
    end

    local viewport = self:GetCamera().mainCamera:WorldToViewportPoint(go.transform.position)
    self:GetCamera():MoveWithFocus(CS.UnityEngine.Vector3(viewport.x - xOffset, viewport.y - yOffset, 0), go.transform.position, duration)
end

local Gizmos = CS.UnityEngine.Gizmos
local magenta = CS.UnityEngine.Color.magenta

function City:Corner()
    local mapLeft = self.zeroPoint + Vector3(0, 0, self.gridConfig.cellsY * self.gridConfig.unitsPerCellY * self.scale)
    local mapRight = self.zeroPoint + Vector3(self.gridConfig.cellsX * self.gridConfig.unitsPerCellX * self.scale, 0, 0)
    local mapTop = self.zeroPoint + Vector3(self.gridConfig.cellsX * self.gridConfig.unitsPerCellX * self.scale, 0, self.gridConfig.cellsY * self.gridConfig.unitsPerCellY * self.scale)
    local mapBottom = self.zeroPoint
    return mapLeft, mapRight, mapTop, mapBottom
end

function City:OnGizmos()
    Gizmos.color = magenta
    local l, r, t, b = self:Corner()
    Gizmos.DrawLine(l, t)
    Gizmos.DrawLine(l, b)
    Gizmos.DrawLine(r, t)
    Gizmos.DrawLine(r, b)
end

---@return CS.DragonReborn.City.ICityZoneSliceDataProviderUsage
function City:GetZoneSliceDataUsage()
    return self.basicDataLoadManager.zoneSliceDataUsage
end

---@return CS.DragonReborn.City.ICityZoneSliceDataProviderUsage
function City:GetSafeAreaSliceDataUsage()
    return self.basicDataLoadManager.safeAreaDataUsage
end

---@return CS.DragonReborn.City.ICityZoneSliceDataProviderUsage
function City:GetSafeAreaWallSliceDataUsage()
    return self.basicDataLoadManager.safeAreaWallDataUsage
end

---@return CS.DragonReborn.City.ISafeAreaEdgeDataUsage
function City:GetSafeAreaEdgeDataUsage()
    return self.basicDataLoadManager.safeAreaEdgeDataUsage
end

function City:ForceSelectFurniture(furnitureId)
    if not self.furnitureManager.dataStatus == LoadState.Loaded then return end
    if not self.gridView.viewStatus == LoadState.Loaded then return end

    local furniture = self.furnitureManager:GetFurnitureById(furnitureId)
    if not furniture then return end

    local furnitureTile = self.gridView.furnitureTiles:Get(furniture.x, furniture.y)
    if not furnitureTile then return end

    self.stateMachine:WriteBlackboard("furniture", furnitureTile, true)
    self.stateMachine:ChangeState(CityConst.STATE_FURNITURE_SELECT)
end

function City:DebugDrawGrid(x, y, color, duration, depthTest)
    duration = duration or 0.03
    depthTest = depthTest or false
    local anchor = self.zeroPoint
    local scale = self.scale
    local point0 = anchor + self.gridConfig:GetLocalPosition(x, y) * scale
    local point1 = anchor + self.gridConfig:GetLocalPosition(x+1, y) * scale
    local point2 = anchor + self.gridConfig:GetLocalPosition(x+1, y+1) * scale
    local point3 = anchor + self.gridConfig:GetLocalPosition(x, y+1) * scale
    local Debug = CS.UnityEngine.Debug
    Debug.DrawLine(point0, point1, color, duration, depthTest)
    Debug.DrawLine(point1, point2, color, duration, depthTest)
    Debug.DrawLine(point2, point3, color, duration, depthTest)
    Debug.DrawLine(point3, point0, color, duration, depthTest)
end

function City:OnApplicationFocus(focus)
    if not focus then return end
    if Utils.IsNotNull(self.fogController) and self.fogManager:IsValid() then
        self:UpdateFog()
    end
end

function City:LoadBasicResource()
    if self.resStatus == LoadState.NotStart then
        self:BasicResourceLoadStart()
    else
        Warn("City:LoadBasicResource() called when resStatus is not NotStart or Unloaded")
    end
end

function City:LoadData()
    if self.dataStatus == LoadState.NotStart then
        self:DataLoadStart()
    else
        Warn("City:LoadData() called when dataStatus is not NotStart or Unloaded")
    end
end

function City:LoadView()
    if self.resStatus ~= LoadState.Loaded or self.dataStatus ~= LoadState.Loaded then
        self.loadViewAfterResAndDataLoaded = true
        return
    end

    if self.viewStatus == LoadState.NotStart then
        self:ViewLoadStart()
    elseif self.viewStatus == LoadState.PartialLoaded then
        self:ViewLoadPartial()
    else
        Warn("City:LoadView() called when viewStatus is not NotStart or Unloaded")
    end
end

function City:UnloadBasicResource()
    if self.resStatus == LoadState.Loaded or self.resStatus == LoadState.Loading then
        self:BasicResourceUnloadStart()
    else
        Warn("City:UnloadBasicResource() called when resStatus is not Loaded")
    end
end

function City:UnloadData()
    if self.dataStatus == LoadState.Loaded or self.dataStatus == LoadState.Loading then
        self:DataUnloadStart()
    else
        Warn("City:UnloadData() called when dataStatus is not Loaded")
    end
end

function City:UnloadView()
    if self.viewStatus == LoadState.Loaded or self.viewStatus == LoadState.Loading or self.viewStatus == LoadState.PartialLoaded or self.viewStatus == LoadState.PartialLoading then
        self:ViewUnloadStart()
    elseif self.loadViewAfterResAndDataLoaded then
        self.loadViewAfterResAndDataLoaded = false
    else
        Warn("City:UnloadView() called when viewStatus is not Loaded")
    end
end

function City:UnloadViewPartialWhenDisable()
    for _, manager in ipairs(self.orderedManagers) do
        if manager:NeedLoadView() and manager:NeedUnloadViewWhenDisable() then
            manager:OnViewUnloadStart()
            manager:DoViewUnload()
            manager.viewStatus = LoadState.NotStart
            manager:OnViewUnloadFinish()
            self.viewStatus = LoadState.PartialLoaded
        end
    end
end

function City:NeedUnloadViewWhenDisable()
    if not self:IsMyCity() then return true end

    if DeviceUtil.IsLowMemoryDevice() then return true end
    if g_Game.PerformanceLevelManager:IsHighLevel() then return false end
    return true
end

function City:NeedUnloadDataWhenDisable()
    return not self:IsMyCity()
end

function City:NeedUnloadBasicResource()
    if not self:IsMyCity() then return true end

    if DeviceUtil.IsLowMemoryDevice() then return true end
    if g_Game.PerformanceLevelManager:IsLowLevel() then return true end
    return false
end

---@private
function City:BasicResourceLoadStart()
    self.hasLoadedBasicResCount = 0
    self.resStatus = LoadState.Loading
    self.basicResLoadWaitList = {}
    self.basicResLoadWaitMap = {}
    for _, manager in ipairs(self.orderedManagers) do
        if manager:NeedLoadBasicAsset() then
            table.insert(self.basicResLoadWaitList, manager)
            self.basicResLoadWaitMap[manager] = true
        end
        manager:OnBasicResourceLoadStart()
    end

    local description = nil
    local startTime = CS.UnityEngine.Time.realtimeSinceStartup
    for _, manager in ipairs(self.basicResLoadWaitList) do
        manager:TryDoBasicResourceLoad()
        if description == nil then
            description = manager:GetLoadDescription()
            self.loadDescription = description
        end
        if CS.UnityEngine.Time.realtimeSinceStartup - startTime > loadTickInterval then
            break
        end
    end

    if next(self.basicResLoadWaitMap) then
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.BasicResourceLoadTick))
    end

    self.hasLoadedBasicResCount = self.needLoadBasicResCount - table.nums(self.basicResLoadWaitMap)
    self:TriggerLoadingEvent()
end

---@private
function City:BasicResourceLoadTick()
    local startTime = CS.UnityEngine.Time.realtimeSinceStartup
    local description = nil
    for _, manager in ipairs(self.basicResLoadWaitList) do
        if manager.basicResourceStatus == LoadState.NotStart then
            manager:TryDoBasicResourceLoad()
            if description == nil then
                description = manager:GetLoadDescription()
                self.loadDescription = description
            end
        end
        if CS.UnityEngine.Time.realtimeSinceStartup - startTime > loadTickInterval then
            break
        end
    end

    if next(self.basicResLoadWaitMap) == nil then
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.BasicResourceLoadTick))
    end

    self.hasLoadedBasicResCount = self.needLoadBasicResCount - table.nums(self.basicResLoadWaitMap)
    self:TriggerLoadingEvent()
end

---@private
---@param manager CityManagerBase
function City:OnSingleBasicResourceManagerFinish(manager)
    self.basicResLoadWaitMap[manager] = nil

    if next(self.basicResLoadWaitMap) == nil then
        self:BasicResourceLoadFinish()
    end
end

---@private
function City:BasicResourceLoadFinish()
    for name, manager in pairs(self.managers) do
        manager:OnBasicResourceLoadFinish()
    end
    self.resStatus = LoadState.Loaded
    self:CheckLoadViewAfterResAndDataLoaded()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_RES_LOADED, self)
end

---@private
function City:DataLoadStart()
    self.hasLoadedDataCount = 0
    self.dataStatus = LoadState.Loading
    self.dataLoadWaitList = {}
    self.dataLoadWaitMap = {}
    for _, manager in ipairs(self.orderedManagers) do
        if manager:NeedLoadData() then
            table.insert(self.dataLoadWaitList, manager)
            self.dataLoadWaitMap[manager] = true
        end
        manager:OnDataLoadStart()
    end

    local startTime = CS.UnityEngine.Time.realtimeSinceStartup
    local description = nil
    for _, manager in pairs(self.dataLoadWaitList) do
        manager:TryDoDataLoad()
        if description == nil then
            description = manager:GetLoadDescription()
            self.loadDescription = description
        end
        if CS.UnityEngine.Time.realtimeSinceStartup - startTime > loadTickInterval then
            break
        end
    end

    if next(self.dataLoadWaitMap) then
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.DataLoadTick))
    end

    self.hasLoadedDataCount = self.needLoadDataCount - table.nums(self.dataLoadWaitMap)
    self:TriggerLoadingEvent()
    self:AddDataChangedListener()
    self:AddServerPushListener()
end

---@private
function City:DataLoadTick()
    local startTime = CS.UnityEngine.Time.realtimeSinceStartup
    local description = nil
    for _, manager in ipairs(self.dataLoadWaitList) do
        if manager.dataStatus == LoadState.NotStart then
            manager:TryDoDataLoad()
            if description == nil then
                description = manager:GetLoadDescription()
                self.loadDescription = description
            end
        end
        if CS.UnityEngine.Time.realtimeSinceStartup - startTime > loadTickInterval then
            break
        end
    end

    if next(self.dataLoadWaitMap) == nil then
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.DataLoadTick))
    end

    self.hasLoadedDataCount = self.needLoadDataCount - table.nums(self.dataLoadWaitMap)
    self:TriggerLoadingEvent()
end

---@private
---@param manager CityManagerBase
function City:OnSingleDataManagerLoadFinish(manager)
    self.dataLoadWaitMap[manager] = nil

    if next(self.dataLoadWaitMap) == nil then
        self:DataLoadFinish()
    end
end

---@private
function City:DataLoadFinish()
    for name, manager in pairs(self.managers) do
        manager:OnDataLoadFinish()
    end
    self.dataStatus = LoadState.Loaded
    self:CheckLoadViewAfterResAndDataLoaded()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_DATA_LOADED, self)
end

function City:CheckLoadViewAfterResAndDataLoaded()
    if not self.loadViewAfterResAndDataLoaded then return end
    if self:LoadFinished() and self:DataFinished() then
        self.loadViewAfterResAndDataLoaded = false
        self:LoadView()
    end
end

---@private
function City:ViewLoadStart()
    self.hasLoadedViewCount = 0
    self.viewStatus = LoadState.Loading
    self.viewLoadWaitList = {}
    self.viewLoadWaitMap = {}
    for _, manager in ipairs(self.orderedManagers) do
        if manager:NeedLoadView() and not manager:IsViewReady() then
            table.insert(self.viewLoadWaitList, manager)
            self.viewLoadWaitMap[manager] = true
        end
        manager:OnViewLoadStart()
    end

    for _, manager in ipairs(self.viewLoadWaitList) do
        if manager:TryDoViewLoad() ~= LoadState.Loaded then
            self.loadDescription = manager:GetLoadDescription()
        end
    end

    if next(self.viewLoadWaitMap) then
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.ViewLoadTick))
    end

    self.hasLoadedViewCount = self.needLoadViewCount - table.nums(self.viewLoadWaitMap)
    self:TriggerLoadingEvent()
end

function City:ViewLoadPartial()
    self.viewStatus = LoadState.PartialLoading
    self.viewLoadWaitList = {}
    self.viewLoadWaitMap = {}
    self.viewPartialMap = {}
    for _, manager in ipairs(self.orderedManagers) do
        if manager:NeedLoadView() and not manager:IsViewReady() then
            self.viewPartialMap[manager] = true
            table.insert(self.viewLoadWaitList, manager)
            self.viewLoadWaitMap[manager] = true
            manager:OnViewLoadStart()
        end
    end

    for _, manager in ipairs(self.viewLoadWaitList) do
        manager:TryDoViewLoad()
    end

    if next(self.viewLoadWaitMap) then
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.ViewLoadPartialTick))
    end
end

---@private
function City:ViewLoadTick()
    for _, manager in ipairs(self.viewLoadWaitList) do
        if manager.viewStatus == LoadState.NotStart then
            if manager:TryDoViewLoad() ~= LoadState.Loaded then
                self.loadDescription = manager:GetLoadDescription()
            end
        end
    end

    if next(self.viewLoadWaitMap) == nil then
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.ViewLoadTick))
    end

    self.hasLoadedViewCount = self.needLoadViewCount - table.nums(self.viewLoadWaitMap)
    self:TriggerLoadingEvent()
end

function City:ViewLoadPartialTick()
    for _, manager in ipairs(self.viewLoadWaitList) do
        if manager.viewStatus == LoadState.NotStart then
            manager:TryDoViewLoad()
        end
    end

    if next(self.viewLoadWaitMap) == nil then
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.ViewLoadPartialTick))
    end
end

---@private
---@param manager CityManagerBase
function City:OnViewManagerLoadFinish(manager)
    self.viewLoadWaitMap[manager] = nil

    if next(self.viewLoadWaitMap) == nil then
        self:ViewLoadFinish()
    end
end

---@private
function City:ViewLoadFinish()
    for name, manager in pairs(self.managers) do
        if self.viewStatus == LoadState.PartialLoading then
            if self.viewPartialMap[manager] then
                manager:OnViewLoadFinish()
            end
        else
            manager:OnViewLoadFinish()
        end
    end
    self.viewPartialMap = nil
    self.viewStatus = LoadState.Loaded
    g_Game.EventManager:TriggerEvent(EventConst.CITY_VIEW_LOADED, self)

    if self.inRestarting then
        if self.showed then
            self:OnCityActiveForManagers()
        end
        self.inRestarting = false
        self.mediator:SetEnableGesture(true)
    end

    if self.showAfterLoaded then
        self.showed = true
        self.showAfterLoaded = false
        self:OnEnable()
    end
end

function City:TriggerLoadingEvent()
    if not self:IsMyCity() then return end
    local total = self.needLoadBasicResCount + self.needLoadDataCount
    local loaded = self.hasLoadedBasicResCount + self.hasLoadedDataCount
    g_Game.EventManager:TriggerEvent(EventConst.LOADING_PROGRESS_UPDATE, math.clamp01(loaded / total), self.loadDescription)
end

---@private
function City:ViewUnloadStart()
    ---@type table<CityManagerBase, boolean>
    local viewUnloadWaitList = {}
    for name, manager in pairs(self.managers) do
        if manager:NeedLoadView() and manager.viewStatus == LoadState.Loaded then
            viewUnloadWaitList[manager] = true
        end
        manager:OnViewUnloadStart()
    end

    --- 卸载默认当帧完成
    for manager, _ in pairs(viewUnloadWaitList) do
        manager:DoViewUnload()
        manager.viewStatus = LoadState.NotStart
    end

    for name, manager in pairs(self.managers) do
        manager:OnViewUnloadFinish()
    end
    self.viewStatus = LoadState.NotStart
end

---@private
function City:DataUnloadStart()
    self:RemoveDataChangedListener()
    self:RemoveServerPushListener()
    ---@type table<CityManagerBase, boolean>
    local dataUnloadWaitList = {}
    for name, manager in pairs(self.managers) do
        if manager:NeedLoadData() and manager.dataStatus == LoadState.Loaded then
            dataUnloadWaitList[manager] = true
        end
        manager:OnDataUnloadStart()
    end

    --- 卸载默认当帧完成
    for manager, _ in pairs(dataUnloadWaitList) do
        manager:DoDataUnload()
        manager.dataStatus = LoadState.NotStart
    end

    for name, manager in pairs(self.managers) do
        manager:OnDataUnloadFinish()
    end
    self.dataStatus = LoadState.NotStart
end

---@private
function City:BasicResourceUnloadStart()
    ---@type table<CityManagerBase, boolean>
    local resUnloadWaitList = {}
    for name, manager in pairs(self.managers) do
        if manager:NeedLoadBasicAsset() and manager.basicResourceStatus == LoadState.Loaded then
            resUnloadWaitList[manager] = true
        end
        manager:OnBasicResourceUnloadStart()
    end

    --- 卸载默认当帧完成
    for manager, _ in pairs(resUnloadWaitList) do
        manager:DoBasicResourceUnload()
        manager.basicResourceStatus = LoadState.NotStart
    end

    for name, manager in pairs(self.managers) do
        manager:OnBasicResourceUnloadFinish()
    end
    self.resStatus = LoadState.NotStart
end

---@private
---@param camera BasicCamera
function City:OnCameraLoadedForManagers(camera)
    for name, manager in pairs(self.managers) do
        manager:OnCameraLoaded(camera)
    end
end

function City:OnCameraUnloadForManagers()
    for name, manager in pairs(self.managers) do
        manager:OnCameraUnload()
    end
end

---@generic T : CityManagerBase
---@param manager T
function City:OnBasicResourceLoadFailed(manager)
    Error("City:OnBasicResourceLoadFailed() called, manager: %s", manager:GetName())
    self:UnloadBasicResource()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BASIC_RESOURCE_LOAD_FAILED, self)
end

---@generic T : CityManagerBase
---@param manager T
function City:OnDataManagerLoadFailed(manager)
    Error("City:OnDataManagerLoadFailed() called, manager: %s", manager:GetName())
    self:UnloadData()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_DATA_LOAD_FAILED, self)
end

---@generic T : CityManagerBase
---@param manager T
function City:OnViewManagerLoadFailed(manager)
    Error("City:OnViewManagerLoadFailed() called, manager: %s", manager:GetName())
    self:UnloadView()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_VIEW_LOAD_FAILED, self)
end

function City:IsCloseToPolluted(x, y)
    return (self.gridConfig:IsLocationValid(x, y) and self.creepManager:IsAffect(x, y))
        or (self.gridConfig:IsLocationValid(x-1, y) and self.creepManager:IsAffect(x-1, y))
        or (self.gridConfig:IsLocationValid(x+1, y) and self.creepManager:IsAffect(x+1, y))
        or (self.gridConfig:IsLocationValid(x, y-1) and self.creepManager:IsAffect(x, y-1))
        or (self.gridConfig:IsLocationValid(x, y+1) and self.creepManager:IsAffect(x, y+1))
end

function City:IsRectCloseToPolluted(x, y, sizeX, sizeY)
    for i = x - 1, x + sizeX do
        for j = y - 1, y + sizeY do
            if self.gridConfig:IsLocationValid(i, j) and self.creepManager:IsAffect(i, j) then
                return true
            end
        end
    end
    return false
end

function City:HasAbility(abilityId)
    local abilityCfg = ConfigRefer.CityAbility:Find(abilityId)
    if abilityCfg == nil then
        return false
    end

    local castle = self:GetCastle()
    if castle and castle.CastleAbility then
        local level = castle.CastleAbility[abilityCfg:Type()]
        if level == nil then
            return false
        end

        return level >= abilityCfg:Level()
    end

    return false
end

---@param abilityIds number[]
function City:HasAbilities(abilityIds)
    if abilityIds == nil then return false end
    for i, v in ipairs(abilityIds) do
        if not self:HasAbility(v) then
            return false
        end
    end
    return true
end

function City:OnLvUpConfirm(isSuccess, reply, rpc)
    if not isSuccess then return end
    if not self:IsMyCity() then return end

    ---@type wrpc.CastleFurnitureLvUpConfirmRequest
    local request = rpc.request
    local castle = self:GetCastle()
    if not castle then return end
    if not castle.CastleFurniture then return end

    local furnitureId = request.FurnitureId
    local castleFurniture = castle.CastleFurniture[furnitureId]
    if not castleFurniture then return end

    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    if lvCfg:Type() == CityFurnitureTypeNames.radartable then
        g_Game.UIManager:CloseByName(UIMediatorNames.CityWorkFurnitureUpgradeUIMediator)
        ModuleRefer.RadarModule:SetRadarState(true)
        local camera = self:GetCamera()
        local param = {isInCity = true, stack = camera and camera:RecordCurrentCameraStatus()}
        g_Game.UIManager:Open(UIMediatorNames.RadarMediator, param)
    end

    self:PopupLevelUpAttrChange(lvCfg)
end

function City:GetLegoBuildingBaseOffset(x, y)
    if self.legoManager.dataStatus ~= LoadState.Loaded then
        return Vector3.zero
    end

    local legoBuilding = self.legoManager:GetLegoBuildingAt(math.floor(x), math.floor(y))
    if legoBuilding == nil then
        return Vector3.zero
    end

    return legoBuilding:GetBaseOffset()
end

City.TempList = CS.System.Collections.Generic.List(typeof(CS.UnityEngine.Component))()
City.ILightDecalShell = typeof(CS.RenderExtension.ILightDecalShell)

---@param go CS.UnityEngine.GameObject
function City:ModifyDecalShellBaseScale(go, scale)
    City.TempList:Clear()
    go:GetComponentsInChildrenOfType(City.ILightDecalShell, City.TempList, true)
    local count = City.TempList.Count
    for i = 0, count - 1 do
        local c = City.TempList[i]--cast(CityTileAssetFurniture.TempList[i], CityTileAssetFurniture.ILightDecalShell)
        c:SetBaseScale(scale * self.scale)
    end
    City.TempList:Clear()
end

function City:DisableCameraBorderCheck()
    if self.camera then
        self.camera:DisableBorderCheck()
    end
end

---@param point CityInteractPoint_Impl
function City:CityInteractPointGetPos(point)
    if not point.worldPos then
        point.worldPos = self:GetWorldPositionFromCoord(point.gridPosX, point.gridPosY)
        if point.parentY then
            point.worldPos.y = point.parentY
        end
    end
    return point.worldPos
end

function City:OnLowMemory()
    if not self.showed then
        self:UnloadView()
        self:UnloadBasicResource()
    end
end

function City:GetWorkTimeSyncGap(benchmark)
    local now = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local lastTime = self:GetCastle().LastWorkUpdateTime.ServerSecond
    if benchmark ~= nil and benchmark > lastTime then
        return 0
    end
    return math.max(0, now - lastTime)
end

function City:IsResAutoGenStock(itemId)
    ---TODO:是否有自动生成的资源可收取
    return false
end

function City:ClaimTargetResAutoGenStock(itemId)
    ---TODO:一键收取目标类型的资源
end

function City:PopupOfflineUIMediator()
    if not self.furnitureManager:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:StockRoomFurniture())
        or not self.furnitureManager:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:HotSpringFurniture()) then
        return
    end

    local furniture = self.furnitureManager:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:StockRoomFurniture())
    local castleFurniture = furniture:GetCastleFurniture()
    if castleFurniture.StockRoomInfo.Benefits:Count() == 0 then
        return
    end

    if self.lastOfflineIncomeTime and (self.lastOfflineIncomeTime + 3600) > g_Game.ServerTime:GetServerTimestampInSeconds() then
        return
    end

    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastOfflineIncomeTime = self:GetCastle().GlobalData.OfflineData.LastGetOfflineBenefitTime.ServerSecond
    local stockTime = math.max(0, now - lastOfflineIncomeTime)
    local maxTime = ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.MaxOfflineBenefitTime)
    if stockTime < maxTime then
        return
    end

    self.lastOfflineIncomeTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local UIAsyncDataProvider = require("UIAsyncDataProvider")
    local CityOfflineIncomeUIParameter = require("CityOfflineIncomeUIParameter")
    local provider = UIAsyncDataProvider.new()
    local name = UIMediatorNames.CityOfflineIncomeUIMediator
    local timing = UIAsyncDataProvider.PopupTimings.AnyTime
    local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
    local checkFailedStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
    provider:Init(name, timing, check, checkFailedStrategy, false, CityOfflineIncomeUIParameter.new(self))
    provider:SetOtherMediatorCheckType(0)
    g_Game.UIAsyncManager:AddAsyncMediator(provider)
end

---@param typCfgId number
---@param duration number
---@param callback function
---@param selectFurniture boolean @是否在完成后打开环形菜单
function City:LookAtTargetFurnitureByTypeCfgId(typCfgId, duration, callback, selectFurniture)
    local scene = g_Game.SceneManager.current
    if not scene:IsInCity() then
        local returnCityCallback = function()
            self:LookAtTargetFurnitureByTypeCfgId(typCfgId, duration, callback, selectFurniture)
        end
        scene:ReturnMyCity(returnCityCallback)
        return
    end

    local furniture = self.furnitureManager:GetFurnitureByTypeCfgId(typCfgId)
    if furniture == nil then
        return false
    end

    local worldPos = furniture:CenterPos()
    if not selectFurniture then
        self.camera:LookAt(worldPos, duration, callback)
        return true
    end

    local callbackWrap = function()
        self:ForceSelectFurniture(furniture.singleId)
        if callback then
            callback()
        end
    end

    self.camera:LookAt(worldPos, duration, callbackWrap)
    return true
end

---@param lvCfg CityFurnitureLevelConfigCell
function City:EnterBuildFurniture(lvCfg)
    local storageMap = self.furnitureManager:GetStorageFurnitureMap()
    local lvCfgId = lvCfg:Id()
    if storageMap == nil or storageMap[lvCfgId] == nil then
        return
    end

    if storageMap[lvCfgId] <= 0 then
        return
    end

    local data = CityFurniturePlaceUINodeDatum.new(self)
    data:SetStorage(lvCfg, 1, false, false)
    self.stateMachine:WriteBlackboard("data", data:CreateCityStateData())
    self.stateMachine:ChangeState(CityConst.STATE_BUILDING)
end

---@param wrpc wrpc.PushAutoPlaceFurnitureRequest
function City:OnServerPushPlaceFurnitureAndLook(isSuccess, wrpc)
    ---成功时直接看向这个家具，失败时进入摆放这个家具的模式
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
    if wrpc.Success then
        self.camera:LookAt(self:GetWorldPositionFromCoord(wrpc.X, wrpc.Y), 0.5)
    else
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(wrpc.FurnitureId)
        self:EnterBuildFurniture(lvCfg)
    end
end

---@param lvCfg CityFurnitureLevelConfigCell
function City:PopupLevelUpAttrChange(lvCfg)
    local prevLvCfg = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(lvCfg:Type(), lvCfg:Level() - 1)
    if prevLvCfg == nil then
        return
    end
    
    local CityLegoBuffDifferData = require("CityLegoBuffDifferData")
    local TimerUtility = require("TimerUtility")
    ---@type CityLegoBuffDifferData[]
    local oldDataList = {}
    local propertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(prevLvCfg:Attr())
    if propertyList then
        for i, v in ipairs(propertyList) do
            local data = CityLegoBuffDifferData.new(v.type, v.originValue)
            table.insert(oldDataList, data)
        end
    end

    for i = 1, prevLvCfg:BattleAttrGroupsLength() do
        local battleGroup = prevLvCfg:BattleAttrGroups(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(oldDataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(oldDataList, data)
                    end
                end
            end
        end
    end

    for i = 1, prevLvCfg:TroopBattleAttrLength() do
        local battleGroup = prevLvCfg:TroopBattleAttr(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(oldDataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(oldDataList, data)
                    end
                end
            end
        end
    end

    ---@type CityLegoBuffDifferData[]
    local newDataList = {}
    local newPropertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(lvCfg:Attr())
    if newPropertyList then
        for i, v in ipairs(newPropertyList) do
            local data = CityLegoBuffDifferData.new(v.type, v.originValue)
            table.insert(newDataList, data)
        end
    end

    for i = 1, lvCfg:BattleAttrGroupsLength() do
        local battleGroup = lvCfg:BattleAttrGroups(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(newDataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(newDataList, data)
                    end
                end
            end
        end
    end

    for i = 1, lvCfg:TroopBattleAttrLength() do
        local battleGroup = lvCfg:TroopBattleAttr(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(newDataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(newDataList, data)
                    end
                end
            end
        end
    end

    ---@type table<string, CityLegoBuffDifferData>
    local propertyMap = {}
    for i, v in ipairs(oldDataList) do
        propertyMap[v:GetUniqueName()] = v
    end

    local toShowList = {}
    for i, newProp in ipairs(newDataList) do
        local oldProp = propertyMap[newProp:GetUniqueName()]
        --- 数值变化的词条
        if oldProp ~= nil then
            if newProp.oldValue ~= oldProp.oldValue then
                local data = CityLegoBuffDifferData.new(newProp.elementId, oldProp.oldValue, newProp.oldValue, oldProp.prefix)
                table.insert(toShowList, data)
            end
            propertyMap[newProp:GetUniqueName()] = nil
        --- 新增的词条
        else
            local data = CityLegoBuffDifferData.new(newProp.elementId, 0, newProp.oldValue, newProp.prefix)
            table.insert(toShowList, data)
        end
    end

    --- 删除的词条
    for _, oldProp in pairs(propertyMap) do
        local data = CityLegoBuffDifferData.new(oldProp.elementId, oldProp.oldValue, 0, oldProp.prefix)
        table.insert(toShowList, data)
    end

    for i, data in ipairs(toShowList) do
        local content = ("%s:%s"):format(data:GetName(), data:GetDiffValueText())
        TimerUtility.DelayExecute(function()
            ModuleRefer.ToastModule:AddJumpToast(content)
        end, i * 0.5)
    end
end

function City:AdjustFrameCountWhenCloseBorder()
    local camera = self:GetCamera()
    if not camera then return end

    local bMinX, bMinY, bMaxX, bMaxY = self:GetCityConfigDefaultBorder()
    local minX, minY, maxX, maxY = camera:GetLookAtPlaneAABB()
    local x1, y1 = self:GetCoordFromPosition(CS.UnityEngine.Vector3(minX, 0, minY))
    local x2, y2 = self:GetCoordFromPosition(CS.UnityEngine.Vector3(maxX, 0, maxY))
    local buffer = 3
    local isCloseBorder = false
    if math.abs(x1 - bMinX) < buffer or math.abs(x2 - bMaxX) < buffer or math.abs(y1 - bMinY) < buffer or math.abs(y2 - bMaxY) < buffer then
        isCloseBorder = true
    end

    if self.isCloseToBorder ~= isCloseBorder then
        self.isCloseToBorder = isCloseBorder
        if isCloseBorder then
            g_Game.EventManager:TriggerEvent(EventConst.RENDER_FRAME_RATE_OVERRIDE, 30)
        else
            g_Game.EventManager:TriggerEvent(EventConst.RENDER_FRAME_RATE_OVERRIDE)
        end
    end
end

return City