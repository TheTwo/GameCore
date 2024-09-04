local CityManagerBase = require("CityManagerBase")
---@class CityBasicAssetManager:CityManagerBase
---@field new fun():CityBasicAssetManager
local CityBasicAssetManager = class("CityBasicAssetManager", CityManagerBase)
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local Delegate = require("Delegate")
local Utils = require("Utils")
local CityLoadStep = require("CityLoadStep")
local EventConst = require("EventConst")
local ManualResourceConst = require("ManualResourceConst")
local Vector3 = CS.UnityEngine.Vector3

function CityBasicAssetManager:DoBasicResourceLoad()
    self.basicResourceStatus = CityManagerBase.LoadState.Loading
    self.loadProcessing = CityLoadStep.NONE
    self:LoadCityRoot()
    self:LoadMapGridView()
    self:LoadCityFogRoot()
    self:LoadCityCreepRoot()
    self:LoadCitySafeAreaWallRoot()
    self:EnsureSyncSliceDataBinaryFile()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.LoadStartTick))
    return self.basicResourceStatus
end

function CityBasicAssetManager:LoadStartTick()
    if self.loadProcessing == CityLoadStep.ALL then
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.LoadStartTick))
        self:BasicResourceLoadFinish()
    elseif self.loadProcessing < CityLoadStep.NONE then
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.LoadStartTick))
        self:BasicResourceLoadFailed()
    end
end

function CityBasicAssetManager:LoadCityRoot()
    local prefabName = ArtResourceUtils.GetItem(ArtResourceConsts.city_root)
    self.rootHandler = self.city.createHelper:Create(prefabName, nil, Delegate.GetOrCreate(self, self.OnCityRootLoaded), nil, 0, true)
end

function CityBasicAssetManager:OnCityRootLoaded(go, userdata)
    if Utils.IsNull(go) then
        self.loadProcessing = -CityLoadStep.ROOT
        return
    end

    local transform = go.transform
    transform.position = self.city.zeroPoint
    transform.localScale = {self.city.scale, self.city.scale, self.city.scale}

    self.city.CityRoot = go
    self.city:PostLayerProcess(go.transform)
    local rootTrans = self.city.CityRoot.transform
    rootTrans.position = self.city:GetCenter()
    rootTrans.localScale = CS.UnityEngine.Vector3.one * self.city.scale
    local bulidingRoot = rootTrans:Find("building")
    bulidingRoot.position = self.city.zeroPoint
    local decorationRoot = rootTrans:Find("decoration")
    decorationRoot.position = self.city.zeroPoint
    local resourceRoot = rootTrans:Find("resource")
    resourceRoot.position = self.city.zeroPoint
    local npcRoot = rootTrans:Find("npc")
    npcRoot.position = self.city.zeroPoint
    local creepTilingRoot = rootTrans:Find("creep_tiling")
    creepTilingRoot.position = self.city.zeroPoint
    self.city.CityRoot:SetActive(self.city.showed)
    local LowPoly = rootTrans:Find("CIty_Lowpoly_Root_01")
    LowPoly.position = self.city.zeroPoint
    local vfxRoot = rootTrans:Find("vfx")
    vfxRoot.position = self.city.zeroPoint
    self.city.CityVfxRoot = vfxRoot
    local TDRoot = rootTrans:Find("TD")
    TDRoot.position = self.city.zeroPoint
    self.city.CityTDRoot = TDRoot
    local explorerRoot = rootTrans:Find("explorer")
    explorerRoot.position = self.city.zeroPoint
    self.city.CityExploreRoot = explorerRoot
    local workerRoot = rootTrans:Find("worker")
    workerRoot.position = self.city.zeroPoint
    self.city.CityWorkerRoot = workerRoot
    local seMapRoot = rootTrans:Find("se")
    seMapRoot.position = self.city.zeroPoint
    self.city.seMapRoot = seMapRoot.gameObject:GetComponent(typeof(CS.SEForCityMapInfo))
    self.city.seFloatingTextMgr = seMapRoot.gameObject:GetComponent(typeof(CS.SEFloatingTextManager))

    local navRoot = rootTrans:Find("CIty_Lowpoly_Root_01/NavmeshMarkers")
    if Utils.IsNotNull(navRoot) then
        self.city.cityGroundMarkers = navRoot.gameObject:GetComponentsInChildren(typeof(CS.CityGroundNavMarker), false)
    else
        g_Logger.Error("CIty_Lowpoly_Root_01/NavmeshMarkers not found, search NavMarker from root")
        self.city.cityGroundMarkers = go:GetComponentsInChildren(typeof(CS.CityGroundNavMarker), false)
    end

    self.city.outlineController = go:GetLuaBehaviour("CityOutlineController").Instance
    ---@type CS.CityConstructionFlashMatController
    self.city.flashMatController = self.city.CityRoot:GetComponent(typeof(CS.CityConstructionFlashMatController))
    if UNITY_EDITOR then
        self.city.lookDevComp = self.city.CityRoot:GetComponent(typeof(CS.CityTileDataCreator))
        if require("Utils").IsNull(self.city.lookDevComp) then
            self.city.lookDevComp = self.city.CityRoot:AddComponent(typeof(CS.CityTileDataCreator))
        end
        self.city.lookDevComp:InitSaver(self.city.gridConfig.cellsX, self.city.gridConfig.cellsY, self.city.gridConfig.unitsPerCellX, self.city.gridConfig.unitsPerCellY)
        self.city.lookDevComp.CreateFunc = Delegate.GetOrCreate(self.city, self.city.AppendTileDatasToSaver)
    end

    self.levelLoader = go:GetComponentInChildren(typeof(CS.QualityLevelLoaderGroup))
    if self.levelLoader then
        self.levelLoader:StartLoad(Delegate.GetOrCreate(self, self.OnQualityLevelLoaded))
    end

    -- if self.levelLoader == nil then
        self.loadProcessing = self.loadProcessing | CityLoadStep.ROOT
    -- end

    self.rootTrans = transform
end

function CityBasicAssetManager:OnQualityLevelLoaded()
    -- self.loadProcessing = self.loadProcessing | CityLoadStep.ROOT
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOT_ALL_LOADER_FINISHED)
end

function CityBasicAssetManager:LoadMapGridView()
    local prefabName = ArtResourceUtils.GetItem(ArtResourceConsts.city_map_grid)
    self.mapGridViewHandler = self.city.createHelper:Create(prefabName, nil, Delegate.GetOrCreate(self, self.OnMapGridViewLoaded), nil, 0, true)
end

function CityBasicAssetManager:OnMapGridViewLoaded(go, userdata)
    if Utils.IsNull(go) then
        self.loadProcessing = -CityLoadStep.MAP_GRID_VIEW
        return
    end

    go.transform.position = self.city.zeroPoint + Vector3(0, 0.01, 0)
    go:SetActive(false)
    self.city.mapGridView = go:GetComponentInChildren(typeof(CS.GridMapViewTiling))
    self.city.mapGridViewRoot = go
    self.loadProcessing = self.loadProcessing | CityLoadStep.MAP_GRID_VIEW
    self.mapGridTrans = go.transform
end

function CityBasicAssetManager:LoadCityFogRoot()
    local prefabName = ArtResourceUtils.GetItem(ArtResourceConsts.city_fog_root)
    self.fogRootHandler = self.city.createHelper:Create(prefabName, nil, Delegate.GetOrCreate(self, self.OnCityFogRootLoaded), nil, 0, true)
end

function CityBasicAssetManager:OnCityFogRootLoaded(go, userdata)
    if Utils.IsNull(go) then
        self.loadProcessing = -CityLoadStep.FOG
        return
    end

    self.city.fogController = go:GetComponent(typeof(CS.CityFogController))
    self.city:SetupFogRenderFeature(self.city.fogFeature)
    self.loadProcessing = self.loadProcessing | CityLoadStep.FOG
    self.fogRootTrans = go.transform
end

function CityBasicAssetManager:LoadCityCreepRoot()
    local prefabName = ArtResourceUtils.GetItem(ArtResourceConsts.city_creep_root)
    self.creepRootHandler = self.city.createHelper:Create(prefabName, nil, Delegate.GetOrCreate(self, self.OnCityCreepRootLoaded), nil, 0, true)
end

function CityBasicAssetManager:OnCityCreepRootLoaded(go, userdata)
    if Utils.IsNull(go) then
        self.loadProcessing = -CityLoadStep.CREEP
        return
    end 

    self.city.creepController = go:GetComponent(typeof(CS.CityCreepController))
    self.city.creepDecorationController = go:GetComponent(typeof(CS.CityCreepDecorationController))
    self.city.creepVfxInstancingDrawer = go:GetComponent(typeof(CS.CityCreepVfxInstancingDrawer))
    self.city.creepVfxInstancingDrawer.scale = self.city.scale
    self.city.creepDissolveControoler = go:GetComponent(typeof(CS.CityCreepDissolveController))
    self.city.creepController.MaskMultiChangeCallLua = Delegate.GetOrCreate(self.city.creepManager, self.city.creepManager.ApplyBuffer)
    self.city.creepInstancingController = go:GetComponent(typeof(CS.CityCreepInstancingController))
    self.loadProcessing = self.loadProcessing | CityLoadStep.CREEP
    self.creepRootTrans = go.transform
end

function CityBasicAssetManager:LoadCitySafeAreaWallRoot()
    local prefabName = ArtResourceUtils.GetItem(ArtResourceConsts.city_safe_area_wall_root)
    self.safeAreaWallRootHandler = self.city.createHelper:Create(prefabName, nil, Delegate.GetOrCreate(self, self.OnCitySafeAreaWallRootLoaded), nil, 0, true)
end

function CityBasicAssetManager:OnCitySafeAreaWallRootLoaded(go, userdata)
    if Utils.IsNull(go) then
        self.loadProcessing = -CityLoadStep.SAFE_AREA
        return
    end

    self.city.safeAreaWallController = go:GetComponent(typeof(CS.DragonReborn.City.CitySafeAreaWallController))
    self.loadProcessing = self.loadProcessing | CityLoadStep.SAFE_AREA
    self.safeAreaWallRootTrans = go.transform
end

function CityBasicAssetManager:EnsureSyncSliceDataBinaryFile()
    local HashSetString = CS.System.Collections.Generic.HashSet(typeof(CS.System.String))
    local hashSet = HashSetString()
    hashSet:Add(ManualResourceConst.cityZoneSlice)
    hashSet:Add(ManualResourceConst.citySafeAreaSlice)
    hashSet:Add(ManualResourceConst.cityWallSlice)
    hashSet:Add(ManualResourceConst.citySafeAreaEdge)
    g_Game.AssetManager:EnsureSyncLoadAssets(hashSet, true, Delegate.GetOrCreate(self, self.OnSliceLoaded))
end

function CityBasicAssetManager:OnSliceLoaded(flag)
    if not flag then
        self.loadProcessing = -CityLoadStep.SLICE_BIN
        return
    end

    self.loadProcessing = self.loadProcessing | CityLoadStep.SLICE_BIN
end

function CityBasicAssetManager:OnBasicResourceLoadFinish()
    self.mapGridTrans:SetParent(self.rootTrans)
    self.mapGridTrans.localScale = Vector3.one
    self.fogRootTrans:SetParent(self.rootTrans)
    self.fogRootTrans.localScale = Vector3.one
    self.creepRootTrans:SetParent(self.rootTrans)
    self.creepRootTrans.localScale = Vector3.one
    self.safeAreaWallRootTrans:SetParent(self.rootTrans)
    self.safeAreaWallRootTrans.localScale = Vector3.one
end

function CityBasicAssetManager:DoBasicResourceUnload()
    if self.levelLoader and Utils.IsNotNull(self.levelLoader) then
        self.levelLoader:Unload()
    end
    self.levelLoader = nil

    self.city.createHelper:Delete(self.rootHandler)
    self.rootHandler = nil
    self.city.createHelper:Delete(self.mapGridViewHandler)
    self.mapGridViewHandler = nil
    self.city.createHelper:Delete(self.fogRootHandler)
    self.fogRootHandler = nil
    self.city.createHelper:Delete(self.creepRootHandler)
    self.creepRootHandler = nil
    self.city.createHelper:Delete(self.safeAreaWallRootHandler)
    self.safeAreaWallRootHandler = nil

    self.loadProcessing = CityLoadStep.NONE

    self.rootTrans = nil
    self.mapGridTrans = nil
    self.fogRootTrans = nil
    self.creepRootTrans = nil
    self.safeAreaWallRootTrans = nil

    self.flashMatController = nil
    if UNITY_EDITOR then
        if Utils.IsNotNull(self.lookDevComp) then
            self.lookDevComp.CreateFunc = nil
        end
        self.lookDevComp = nil
    end

    self.city.CityRoot = nil
    self.city.CityVfxRoot = nil
    self.city.CityTDRoot = nil
    self.city.CityExploreRoot = nil
    self.city.CityWorkerRoot = nil
    self.city.cityGroundMarkers = nil
    self.city.cityGroundMarkers = nil
    self.city.mapGridView = nil
    self.city.mapGridViewRoot = nil
    self.city.fogController = nil
    if self.city.creepController then
        self.city.creepController.MaskMultiChangeCallLua = nil
    end
    self.city.flashMatController = nil
    self.city.creepController = nil
    self.city.creepDecorationController = nil
    self.city.creepVfxInstancingDrawer = nil
    self.city.creepDissolveControoler = nil
    self.city.safeAreaWallController = nil
end

function CityBasicAssetManager:NeedLoadBasicAsset()
    return true
end

function CityBasicAssetManager:OnCameraLoaded(camera)
    self.camera = camera
    if self.city.outlineController then
        self.city.outlineController:SetMainCamera(self.camera:GetUnityCamera())
    end
    if self.city.flashMatController then
        self.city.flashMatController:SwitchTransparentOutline(false, self.camera.mainCamera)
    end
end

function CityBasicAssetManager:OnCameraUnload()
    self.camera = nil
    if self.city.outlineController then
        self.city.outlineController:SetMainCamera(nil)
    end
    if self.city.flashMatController then
        self.city.flashMatController:SwitchTransparentOutline(false, nil)
    end
end

function CityBasicAssetManager:OnViewLoadFinish()
    self.city:UpdateMapGridView()
end

return CityBasicAssetManager