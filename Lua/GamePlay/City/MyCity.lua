local City = require("City")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local DBEntityType = require("DBEntityType")
---@class MyCity:City
---@field super City
---@field new fun(id:number, x:number, y:number, kingdomMapData:CS.Grid.StaticMapData):MyCity
local MyCity = class("MyCity", City)
local CityPathFinding = require("CityPathFinding")
local CityEnvironmentalIndicatorManager = require("CityEnvironmentalIndicatorManager")
local CityInteractPointManager = require("CityInteractPointManager")
local CityExplorerManager = require("CityExplorerManager")
local CityCitizenManager = require("CityCitizenManager")
local CitySeManager = require("CitySeManager")
local CityUtils = require("CityUtils")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityRandomVoice = require("CityRandomVoice")
local UIAsyncDataProvider = require('UIAsyncDataProvider')
local UIManager = require("UIManager")

local StateMachine = require("StateMachine")
local CityConst = require("CityConst")
local CityStateEntry = require("CityStateEntry")
local CityStateExit = require("CityStateExit")
local CityStateNormal = require("CityStateNormal")
local CityStateEditIdle = require("CityStateEditIdle")
local CityStateBuilding = require("CityStateBuilding")
local CityStatePlaceRoomDoor = require("CityStatePlaceRoomDoor")
local CityStatePlaceRoomFurniture = require("CityStatePlaceRoomFurniture")
local CityStateChangeFloor = require("CityStateChangeFloor")
local CityStateBuildingSelect = require("CityStateBuildingSelect")
local CityStateMovingBuilding = require("CityStateMovingBuilding")
local CityStateFurnitureSelect = require("CityStateFurnitureSelect")
local CityStateMovingFurniture = require("CityStateMovingFurniture")
local CityStateAirView = require("CityStateAirView")
local CityStateUpgradeBuildingPreview = require("CityStateUpgradeBuildingPreview")
local CityStateCitizenManageUI = require("CityStateCitizenManageUI")
local CityStateCreepNodeSelect = require("CityStateCreepNodeSelect")
local CityStateClearCreep = require("CityStateClearCreep")
local CityStateExplorerTeamSelect = require("CityStateExplorerTeamSelect")
local CityStateRepairBlock = require("CityStateRepairBlock")
local CityStateSafeAreaWallSelect = require("CityStateSafeAreaWallSelect")
local CityStateFarmlandSelect = require("CityStateFarmlandSelect")
local CityEmptyGraphV2 = require("CityEmptyGraphV2")
local UIMediatorNames = require("UIMediatorNames")
local CityStateEnterRadar = require("CityStateEnterRadar")
local CityStateLockedNpcSelected = require("CityStateLockedNpcSelected")
local CityStateMovingLego = require("CityStateMovingLego")
local CityStateLockedLegoSelected = require("CityStateLockedLegoSelected")
local ManualResourceConst = require("ManualResourceConst")
local CityStateMainBaseUpgrade = require("CityStateMainBaseUpgrade")
local CityStateSeBattle = require("CityStateSeBattle")
local CityStateSeExplorerFocus = require("CityStateSeExplorerFocus")
local CityStatePlayZoneRecoverEffect = require("CityStatePlayZoneRecoverEffect")
local CityStateExplorerTeamOperateMenu = require("CityStateExplorerTeamOperateMenu")
local SEUnitHudLodCompSharedController = require("SEUnitHudLodCompSharedController")
local ArtResourceUtils = require("ArtResourceUtils")
local TimerUtility = require("TimerUtility")
local I18N = require("I18N")
local Utils = require("Utils")
local CastleBuildingStatus = wds.enum.CastleBuildingStatus
local CityElementResourceVfxPlayManager = require("CityElementResourceVfxPlayManager")
local Ease = CS.DG.Tweening.Ease

function MyCity:ctor(...)
    City.ctor(self, ...)
    self.stateMachine.enableLog = true
    self.releaseViewWhenHide = false
    self.seHudHideSize = nil
end

function MyCity:AddAllCityManager()
    City.AddAllCityManager(self)
    self.cityPathFinding = self:AddCityManager(CityPathFinding.new(self))
    self.cityEnvironmentalIndicatorManager = self:AddCityManager(CityEnvironmentalIndicatorManager.new(self))
    self.cityInteractPointManager = self:AddCityManager(CityInteractPointManager.new(self, self.furnitureManager, self.elementManager))
    self.cityCitizenManager = self:AddCityManager(CityCitizenManager.new(self, self.cityWorkManager, self.cityEnvironmentalIndicatorManager, self.cityInteractPointManager))
    self.elementResourceVfxPlayManager = self:AddCityManager(CityElementResourceVfxPlayManager.new(self))
    self.emptyGraph = self:AddCityManager(CityEmptyGraphV2.new(self, self.zoneManager, self.gridLayer, self.safeAreaWallMgr))
    self.cityRandomVoice = self:AddCityManager(CityRandomVoice.new(self))
    self.citySeManger = self:AddCityManager(CitySeManager.new(self, self.zoneManager, self.gridLayer, self.safeAreaWallMgr, self.elementManager))
    self.cityExplorerManager = self:AddCityManager(CityExplorerManager.new(self, self.citySeManger))
end

function MyCity:InitStateMachine()
    self.stateMachine = StateMachine.new(true)
    self.stateMachine.allowReEnter = true
    self.stateMachine:AddState(CityConst.STATE_ENTRY, CityStateEntry.new(self))
    self.stateMachine:AddState(CityConst.STATE_EXIT, CityStateExit.new(self))
    self.stateMachine:AddState(CityConst.STATE_NORMAL, CityStateNormal.new(self))
    self.stateMachine:AddState(CityConst.STATE_EDIT_IDLE, CityStateEditIdle.new(self))
    self.stateMachine:AddState(CityConst.STATE_BUILDING, CityStateBuilding.new(self))
    self.stateMachine:AddState(CityConst.STATE_PLACE_ROOM_DOOR, CityStatePlaceRoomDoor.new(self))
    self.stateMachine:AddState(CityConst.STATE_PLACE_ROOM_FURNITURE, CityStatePlaceRoomFurniture.new(self))
    self.stateMachine:AddState(CityConst.STATE_CHANGE_FLOOR, CityStateChangeFloor.new(self))
    self.stateMachine:AddState(CityConst.STATE_BUILDING_SELECT, CityStateBuildingSelect.new(self))
    self.stateMachine:AddState(CityConst.STATE_BUILDING_MOVING, CityStateMovingBuilding.new(self))
    self.stateMachine:AddState(CityConst.STATE_FURNITURE_SELECT, CityStateFurnitureSelect.new(self))
    self.stateMachine:AddState(CityConst.STATE_FURNITURE_MOVING, CityStateMovingFurniture.new(self))
    self.stateMachine:AddState(CityConst.STATE_AIR_VIEW, CityStateAirView.new(self))
    self.stateMachine:AddState(CityConst.STATE_UPGRADE_BUILDING_PREVIEW, CityStateUpgradeBuildingPreview.new(self))
    self.stateMachine:AddState(CityConst.STATE_CITIZEN_MANAGE_UI, CityStateCitizenManageUI.new(self))
    self.stateMachine:AddState(CityConst.STATE_CREEP_NODE_SELECT, CityStateCreepNodeSelect.new(self))
    self.stateMachine:AddState(CityConst.STATE_CLEAR_CREEP, CityStateClearCreep.new(self))
    self.stateMachine:AddState(CityConst.STATE_EXPLORER_TEAM_SELECT, CityStateExplorerTeamSelect.new(self))
    self.stateMachine:AddState(CityConst.STATE_REPAIR_BLOCK, CityStateRepairBlock.new(self))
    self.stateMachine:AddState(CityConst.STATE_SAFE_AREA_WALL_SELECT, CityStateSafeAreaWallSelect.new(self))
    self.stateMachine:AddState(CityConst.STATE_FURNITURE_FARMLAND_SELECT, CityStateFarmlandSelect.new(self))
    self.stateMachine:AddState(CityConst.STATE_ENTER_RADAR, CityStateEnterRadar.new(self))
    self.stateMachine:AddState(CityConst.STATE_LOCKED_NONE_SHOWN_SERVICE_NPC_SELECT, CityStateLockedNpcSelected.new(self))
    self.stateMachine:AddState(CityConst.STATE_MOVING_LEGO_BUILDING, CityStateMovingLego.new(self))
    self.stateMachine:AddState(CityConst.STATE_LOCKED_BUILDING_SELECT, CityStateLockedLegoSelected.new(self))
    self.stateMachine:AddState(CityConst.STATE_MAIN_BASE_UPGRADE, CityStateMainBaseUpgrade.new(self))
    self.stateMachine:AddState(CityConst.STATE_CITY_SE_BATTLE_FOCUS, CityStateSeBattle.new(self))
    self.stateMachine:AddState(CityConst.STATE_CITY_SE_EXPLORER_FOCUS, CityStateSeExplorerFocus.new(self))
    self.stateMachine:AddState(CityConst.STATE_CITY_ZONE_RECOVER_EFFECT, CityStatePlayZoneRecoverEffect.new(self))
    self.stateMachine:AddState(CityConst.STATE_EXPLORER_TEAM_OPERATE_MENU, CityStateExplorerTeamOperateMenu.new(self))
    self.stateMachine:AddStateChangedListener(Delegate.GetOrCreate(self, self.OnMyCityStateChanged))
end

function MyCity:IsMyCity()
    return true
end

function MyCity:OnEnable()
    City.OnEnable(self)
    --self.unitMoveGridEventProvider:Clear()
    -- self.creepDecorationController:Sample()
    self:OnMapGridDefault()
    self:ResetCreepMatTransDefault()

    g_Game.EventManager:AddListener(EventConst.CITY_MAP_GRID_DEFAULT, Delegate.GetOrCreate(self, self.OnMapGridDefault))
    g_Game.EventManager:AddListener(EventConst.CITY_MAP_GRID_ONLY_SHOW_IN_BUILDING, Delegate.GetOrCreate(self, self.OnMapGridShowOnlyInBuilding))
    g_Game.EventManager:AddListener(EventConst.CITY_CAMERA_TWEEN_TO_TOP_VIEWPORT, Delegate.GetOrCreate(self, self.TweenToBuildViewport))
    g_Game.EventManager:AddListener(EventConst.CITY_CAMERA_TWEEN_TO_DEFAULT_VIEWPORT, Delegate.GetOrCreate(self, self.TweenToDefaultViewport))
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_MAP_CACHE_REBUILT, Delegate.GetOrCreate(self, self.OnSafeAreaRebuilt))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureLvUpInfoChanged))
    self.unitPositionQuadTree:AddEvents()
    if self.camera then
        if not self.seHudHideSize then
            self.seHudHideSize = ConfigRefer.CityConfig:CitySeUnitHudHideCameraSize()
        end
        local oldSize = self.cameraSize or 0
        local newSize = self.camera:GetSize()
        SEUnitHudLodCompSharedController.OnCameraSizeChanged(oldSize, newSize, self.seHudHideSize <= newSize)
    end
end

function MyCity:OnDisable()
    self.unitPositionQuadTree:RemoveEvents()
    self.unitMoveGridEventProvider:Clear()

    g_Game.EventManager:RemoveListener(EventConst.CITY_MAP_GRID_DEFAULT, Delegate.GetOrCreate(self, self.OnMapGridDefault))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MAP_GRID_ONLY_SHOW_IN_BUILDING, Delegate.GetOrCreate(self, self.OnMapGridShowOnlyInBuilding))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CAMERA_TWEEN_TO_TOP_VIEWPORT, Delegate.GetOrCreate(self, self.TweenToBuildViewport))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CAMERA_TWEEN_TO_DEFAULT_VIEWPORT, Delegate.GetOrCreate(self, self.TweenToDefaultViewport))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_MAP_CACHE_REBUILT, Delegate.GetOrCreate(self, self.OnSafeAreaRebuilt))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureLvUpInfoChanged))

    City.OnDisable(self)
    self.flashMatController:StopAll();
    SEUnitHudLodCompSharedController.OnCameraSizeChanged(nil, nil, false)
end

function MyCity:Tick(deltaTime)
    MyCity.super.Tick(self, deltaTime)
    self.elementManager:Tick(deltaTime)
    self.cityExplorerManager:Tick(deltaTime)
    self.cityCitizenManager:Tick(deltaTime)
    self.citySeManger:Tick(deltaTime)
end

function MyCity:OnCameraLoaded(camera)
    local oldSize = self.cameraSize or 0
    MyCity.super.OnCameraLoaded(self, camera)
    if not self.seHudHideSize then
        self.seHudHideSize = ConfigRefer.CityConfig:CitySeUnitHudHideCameraSize()
    end
    local newSize = self.cameraSize or 0
    SEUnitHudLodCompSharedController.OnCameraSizeChanged(oldSize, newSize, self.seHudHideSize <= newSize)
end

function MyCity:OnCameraSizeChanged(oldSize, newSize)
    MyCity.super.OnCameraSizeChanged(self, oldSize, newSize)
    if not self.seHudHideSize then
        self.seHudHideSize = ConfigRefer.CityConfig:CitySeUnitHudHideCameraSize()
    end
    SEUnitHudLodCompSharedController.OnCameraSizeChanged(oldSize, newSize, self.seHudHideSize <= newSize)
    if not self.showed then return end
    self.cityExplorerManager:OnCameraSizeChanged(oldSize, newSize)
    self.cityCitizenManager:OnCameraSizeChanged(oldSize, newSize)
end

function MyCity:OnCameraUnload()
    self.seHudHideSize = nil
    SEUnitHudLodCompSharedController.OnCameraSizeChanged(nil, nil, false)
    MyCity.super.OnCameraUnload(self)
end

---@param buildingInfo wds.CastleBuildingInfo
function MyCity:OnStorageBuilding(tileId, buildingInfo)
    City.OnStorageBuilding(self, tileId, buildingInfo)
end

---@param buildingInfo wds.CastleBuildingInfo
function MyCity:OnAddBuilding(tileId, buildingInfo)
    City.OnAddBuilding(self, tileId, buildingInfo)
    ModuleRefer.CityConstructionModule:TryShowNewRedDots()
    if CityUtils.IsStatusCreateWaitWorker(buildingInfo.Status) then
        self:TryFindFreeWorkerToBuild(tileId)
    end
end

---@param oldInfo wds.CastleBuildingInfo
---@param newInfo wds.CastleBuildingInfo
function MyCity:OnUpdateBuilding(tileId, oldInfo, newInfo)
    City.OnUpdateBuilding(self, tileId, oldInfo, newInfo)
end

function MyCity:IsLocationValidForConstruction(x, y)
    return self:GetMapData():IsLocationValid(x, y) and self:IsLocationValid(x, y) and not self.creepManager:IsAffect(x, y)
end

function MyCity:EnterClearCreepMode(itemId, x, y)
    --self.stateMachine:WriteBlackboard("itemId", itemId)
    --self.stateMachine:WriteBlackboard("x", x)
    --self.stateMachine:WriteBlackboard("y", y)
    --self.stateMachine:ChangeState(CityConst.STATE_CLEAR_CREEP)
end

function MyCity:EnterSweepCreepMode(x, y)
    self.stateMachine:WriteBlackboard("x", x)
    self.stateMachine:WriteBlackboard("y", y)
    self.stateMachine:WriteBlackboard("sweeper", true)
    self.stateMachine:ChangeState(CityConst.STATE_CLEAR_CREEP)
end

function MyCity:EnterUpgradePreviewMode(cellTile, workerData)
    self.stateMachine:WriteBlackboard("cellTile", cellTile)
    self.stateMachine:WriteBlackboard("workerData", workerData)
    self.stateMachine:WriteBlackboard("RelativeFurniture", self:GetRelativeFurnitureTile(cellTile))
    self.stateMachine:ChangeState(CityConst.STATE_UPGRADE_BUILDING_PREVIEW)
end

---@param cellTile CityCellTile
---@param cfg BuildingBlockConfigCell
function MyCity:EnterRepairBlockBaseState(cellTile, cfg)
    self.stateMachine:WriteBlackboard("cellTile", cellTile)
    self.stateMachine:WriteBlackboard("cfg", cfg)
    self.stateMachine:WriteBlackboard("wallIdx", -1)
    self.stateMachine:ChangeState(CityConst.STATE_REPAIR_BLOCK)
end

---@param cellTile CityCellTile
---@param cfg BuildingBlockConfigCell
---@param wallIdx number
function MyCity:EnterRepairBlockWallState(cellTile, cfg, wallIdx)
    self.stateMachine:WriteBlackboard("cellTile", cellTile)
    self.stateMachine:WriteBlackboard("cfg", cfg)
    self.stateMachine:WriteBlackboard("wallIdx", wallIdx)
    self.stateMachine:ChangeState(CityConst.STATE_REPAIR_BLOCK)
end

---@param x number
---@param y number
function MyCity:EnterRepairSafeAreaWallOrDoorState(x, y)
    self.stateMachine:WriteBlackboard("x", x)
    self.stateMachine:WriteBlackboard("y", y)
    self.stateMachine:ChangeState(CityConst.STATE_SAFE_AREA_WALL_SELECT)
end

function MyCity:AppendTileDatasToSaver()
    if not UNITY_EDITOR then return end
    if require("Utils").IsNull(self.lookDevComp) then return end

    local ConfigRefer = require("ConfigRefer")
    local ArtResourceUtils = require("ArtResourceUtils")
    for cell, v in pairs(self.grid.hashMap) do
        if cell:IsBuilding() then
            local lvCell = ConfigRefer.BuildingLevel:Find(cell.configId)
            local prefabName = ArtResourceUtils.GetItem(lvCell:ModelArtRes())
            self.lookDevComp:AppendUnit(cell.x, cell.y, prefabName)
        elseif cell:IsResource() then
            local eleCfg = ConfigRefer.CityElementData:Find(cell.configId)
            local resCfg = ConfigRefer.CityElementResource:Find(eleCfg:ElementId())
            local prefabName = ArtResourceUtils.GetItem(resCfg:Model())
            self.lookDevComp:AppendUnit(cell.x, cell.y, prefabName)
        elseif cell:IsNpc() then
            local eleCfg = ConfigRefer.CityElementData:Find(cell.configId)
            local resCfg = ConfigRefer.CityElementNpc:Find(eleCfg:ElementId())
            local prefabName = ArtResourceUtils.GetItem(resCfg:Model())
            self.lookDevComp:AppendUnit(cell.x, cell.y, prefabName)
        elseif cell:IsCreepNode() then
            local eleCfg = ConfigRefer.CityElementData:Find(cell.configId)
            local resCfg = ConfigRefer.CityElementCreep:Find(eleCfg:ElementId())
            local prefabName = ArtResourceUtils.GetItem(resCfg:Model())
            self.lookDevComp:AppendUnit(cell.x, cell.y, prefabName)
        end
    end

    for id, cell in pairs(self.furnitureManager.hashMap) do
        local lvCell = ConfigRefer.CityFurnitureLevel:Find(cell.configId)
        local prefabName = ArtResourceUtils.GetItem(lvCell:Model())
        self.lookDevComp:AppendUnit(cell.x, cell.y, prefabName)
    end
end

function MyCity:CanPlaceWallAtWorldCoord(x, y, isHorizontal)
    local cell = self.grid:GetCell(x, y)
    if not cell or not cell:IsBuilding() then
        return false
    end

    local building = self.buildingManager:GetBuilding(cell.tileId)
    if not building then
        return false
    end

    local lx, ly = x - cell.x, y - cell.y
    if not building:PlaceWallLocalAtInConfig(lx, ly) then
        return false
    end

    if isHorizontal then
        return not building:HasInnerHWallOrDoor(ly, lx)
    else
        return not building:HasInnerVWallOrDoor(lx, ly)
    end
end

function MyCity:PlaceWallAtWorldCoord(x, y, cfgId, isHorizontal)
    local cell = self.grid:GetCell(x, y)
    local localX = x - cell.x
    local localY = y - cell.y
    self.buildingManager:RequestAddWall(cell.tileId, localX, localY, cfgId, isHorizontal)
end

function MyCity:TweenToBuildViewport()
    
end

function MyCity:TweenToDefaultViewport()
    
end

function MyCity:OnAzimuthTweenComplete()
    self.azimuthTween = nil
end

function MyCity:OnAltitudeTweenComplete()
    self.altitudeTween = nil
end

function MyCity:OnMapGridDefault()
    self.mapGridView:DoUpdateMask(true)
    self.mapGridViewRoot.transform.position = self.zeroPoint + CS.UnityEngine.Vector3(0, 0.02, 0)
    self.mapGridView:SetSafeAreaMask(self.safeAreaWallController)
    self.mapGridInBuilding = false
end

function MyCity:OnMapGridShowOnlyInBuilding()
    if self.editBuilding == nil then return end

    local gridConfig = self.gridConfig
    local maskByteArray = self:GenerateTargetLegoBuildingGridMask(self.editBuilding)
    local pointer, size = maskByteArray:topointer()
    self.mapGridView:SetCustomMask(gridConfig.cellsX, gridConfig.cellsY, pointer, size)
    self.mapGridViewRoot.transform.position = self.zeroPoint + self.editBuilding.baseOffset + CS.UnityEngine.Vector3(0, 0.02, 0)
    self.mapGridInBuilding = true
end

function MyCity:GenerateTargetLegoBuildingGridMask()
    local gridConfig = self.gridConfig
    local ret = bytearray.new(gridConfig.cellsX * gridConfig.cellsY)
    for x, y, floor in self.editBuilding.floorPosMap:pairs() do
        local idx = y * gridConfig.cellsX + x + 1
        ret[idx] = 255
    end
    return ret
end

function MyCity:OnSafeAreaRebuilt()
    if not self.showed then return end
    if not self.mapGridInBuilding then
        self:OnMapGridDefault()
    end
end

---@param building CityBuilding
function MyCity:OnBuildingStatusToNormal(building)
    local typCell = ConfigRefer.BuildingTypes:Find(building.info.BuildingType)
    if not typCell:HideUpgradeUI() then
        local lvCell = ModuleRefer.CityConstructionModule:GetBuildingLevelConfigCellByTypeId(building.info.BuildingType, building.info.Level)
        g_Game.UIManager:Open(UIMediatorNames.CityBuildUpgradeSuccUIMediator, lvCell:Id())
    end
    ---@type CityCellTile
    local tile = self.gridView.cellTiles:Get(building.x, building.y)
    self:PlayRibbonCuttingVfx(tile)
end

---@param tile CityTileBase
function MyCity:PlayRibbonCuttingVfx(tile)
    if not tile then return end

    local furniture = tile:GetCell()
    local lvCell = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(furniture.furType, furniture.level - 1)
    if lvCell == nil then
        lvCell = furniture.furnitureCell
    end

    local prefabName, scale = ArtResourceUtils.GetItemAndScale(lvCell:PostRibbonCuttingModel())
    if string.IsNullOrEmpty(prefabName) then return end

    local handle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    handle:Create(prefabName, "city_ribbon_cutting_vfx", self:GetRoot().transform, Delegate.GetOrCreate(self, self.OnVfxCreated), {
        position = tile:GetWorldCenter(),
        scale = scale
    })
    TimerUtility.DelayExecute(function()
        handle:Delete()
    end, 5)
end

---@param furniture CityFurniture
function MyCity:PlayMainBaseUpgradeTimeline(furniture)
    self.stateMachine:WriteBlackboard("furniture", furniture)
    self.stateMachine:ChangeState(CityConst.STATE_MAIN_BASE_UPGRADE)
end

---@param furniture CityFurniture
function MyCity:PlayPetFurLevelUpToast(furniture)
    g_Game.UIManager:Open(UIMediatorNames.CityPetFurLevelUpToastUIMediator, furniture)
end

function MyCity:OnVfxCreated(isSuccess, userdata, handle)
    if not isSuccess then return end

    local position = userdata.position
    local scale = userdata.scale
    local gameObject = handle.Effect.gameObject
    gameObject:SetLayerRecursively("City")
    local transform = gameObject.transform
    transform.localScale = CS.UnityEngine.Vector3.one * scale
    transform:SetPositionAndRotation(position, CS.UnityEngine.Quaternion.identity)
end

function MyCity:OnApplicationFocus(focus)
    City.OnApplicationFocus(self, focus)
    if focus then
        if self.mapGridInBuilding then
            self:OnMapGridShowOnlyInBuilding()
        else
            self:OnMapGridDefault()
        end
    end
end

function MyCity:ResetCreepMatTransDefault()
    if Utils.IsNotNull(self.creepDissolveControoler) then
        CS.CityMatTransitionController.SetDefaultController(self.creepDissolveControoler)
    end
end

function MyCity:ViewUnloadStart()
    self:ClearCreepMatTransCache()
    City.ViewUnloadStart(self)
end

function MyCity:ClearCreepMatTransCache()
    if Utils.IsNotNull(self.creepDissolveControoler) then
        CS.CityMatTransitionController.ClearAll()
    end
end

function MyCity:TryFindFreeWorkerToBuild(tileId)
    local unit = self.cityCitizenManager:GetFreeWorkableCitizen()
    if unit == nil then
        unit = self.cityCitizenManager:GetFreeHomelessCitizen()
    end
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("citizen_toast_nofree"))
end

---@param param {Event:string, Change:table<number, boolean>}
function MyCity:OnFurnitureLvUpInfoChanged(city, param)
    if city ~= self then return end
    if not self.showed then return end

    for id, _ in pairs(param.Change) do
        local furniture = self.furnitureManager:GetFurnitureById(id)
        if furniture == nil then goto continue end
        local furnitureTile = self.gridView:GetFurnitureTile(furniture.x, furniture.y)
        if furnitureTile == nil then goto continue end
        local castleFurniture = furnitureTile:GetCastleFurniture()
        if not castleFurniture.LevelUpInfo.Working then
            self:PlayRibbonCuttingVfx(furnitureTile)
            if furniture:IsMainBase() then
                self:PlayMainBaseUpgradeTimeline(furniture)
            else
                g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_LEVEL_UP_FOR_GUIDE)
                if furniture:IsPetFur() then
                    self:PlayPetFurLevelUpToast(furniture)
                end
            end
            self:TryOpenUnlockMediator(furniture.furType,furniture.level)
            g_Game.SoundManager:Play("sfx_ui_upgrade_indoor")
        end
        ::continue::
    end
end

function MyCity:TryOpenUnlockMediator(id,level)
    local levelCfg = ConfigRefer.CityFurnitureLevel:Find(tonumber(id) + level - 1)
    if levelCfg and levelCfg:UnlockPreviewLength()>0 then
        local data = {furnitureId = id, level = level}
        local provider = UIAsyncDataProvider.new()
        local checkTypes = UIAsyncDataProvider.CheckTypes.DoNotShowInSE | UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
        data.provider = provider
        provider:SetOtherMediatorCheckType(UIManager.UIMediatorType.Dialog | UIManager.UIMediatorType.Popup)
        provider:AddOtherMediatorWhiteList(UIMediatorNames.CityWorkFurnitureUpgradeUIMediator)
        data.uiMediatorName = UIMediatorNames.CityFurnitureUnlockMediator
        provider:Init(UIMediatorNames.CityFurnitureUnlockMediator, nil, checkTypes, nil, nil, data)
        g_Game.UIAsyncManager:AddAsyncMediator(provider)
    end
end

function MyCity:PreDisposeSeEnvironment()
    if self.citySeManger then
        self.citySeManger:CleanupSeEnvironment()
    end
end

function MyCity:IsInSeBattleMode()
    return self.stateMachine:GetCurrentStateName() == CityConst.STATE_CITY_SE_BATTLE_FOCUS
end

function MyCity:IsInSingleSeExplorerMode()
    return self.stateMachine:GetCurrentStateName() == CityConst.STATE_CITY_SE_EXPLORER_FOCUS
end

function MyCity:IsInRecoverZoneEffectMode()
    return self.stateMachine:GetCurrentStateName() == CityConst.STATE_CITY_ZONE_RECOVER_EFFECT
end

---@return number, number
function MyCity:GetCameraMaxSize()
    if self:IsInSingleSeExplorerMode() or self:IsInSeBattleMode() then
        ---@type CityStateSeExplorerFocus|CityStateSeBattle
        local state = self.stateMachine:GetCurrentState()
        local min, max = state:GetCameraMaxSize()
        if min and max then
            return min,max
        end
    end
    return MyCity.super.GetCameraMaxSize(self)
end

function MyCity:Dispose()
    self.stateMachine:RemoveStateChangedListener(Delegate.GetOrCreate(self, self.OnMyCityStateChanged))
    MyCity.super.Dispose(self)
end

---@param oldState CityState
---@param newState CityState
function MyCity:OnMyCityStateChanged(oldState, newState)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_STATEMACHINE_STATE_CHANGED, self, oldState, newState)
end

return MyCity