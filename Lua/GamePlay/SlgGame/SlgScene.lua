local Scene = require("Scene")
local ConfigRefer = require("ConfigRefer")
local SlgTileViewFactory = require("SlgTileViewFactory")
local SlgRequestService = require("SlgRequestService")
local UIMediatorNames = require("UIMediatorNames")
local Delegate = require("Delegate")
local ModuleRefer = require('ModuleRefer')
local MapFoundation = require('MapFoundation')
local CameraConst = require('CameraConst')
local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility
local URPRendererList = require("URPRendererList")
local LuaTileViewFactory = CS.Grid.LuaTileViewFactory
local LuaRequestService = CS.Grid.LuaRequestService
local ShadowDistanceControl = require('ShadowDistanceControl')
local KingdomMapUtils = require("KingdomMapUtils")
local LuaKingdomViewFactory = CS.Grid.LuaKingdomViewFactory
local KingdomViewFactory = require("KingdomViewFactory")
local EventConst = require('EventConst')
local SlgCameraSettingsSetter = require("SlgCameraSettingsSetter")
local Utils = require("Utils")

local cityBorderLeft = 1200
local cityBorderRight = 1200
local cityBorderTop = 1630
local cityBorderBottom = 560

---@class SlgScene:Scene
---@field tid number
---@field id number
---@field mapSystem CS.Grid.MapSystem
---@field staticMapData CS.Grid.StaticMapData
---@field basicCamera BasicCamera
---@field mapMarkCamera MapMarkCamera
---@field cameraLodData CameraLodData
---@field cameraPlaneData CameraPlaneData
---@field mapFoundation MapFoundation
local SlgScene = class("SlgScene", Scene)
SlgScene.Name = "SlgScene"

function SlgScene:ctor()
end

function SlgScene:GetTagName()
    return string.format('gve_%s', self.tid)
end

function SlgScene:EnterScene(param)
    self.mapFoundation = MapFoundation.new()
    Scene.EnterScene(self, param)

    self.tid = g_Game.StateMachine:ReadBlackboard("SLG_TID")
    self.id = g_Game.StateMachine:ReadBlackboard("SLG_ID")
    self:LoadScene()

    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))

    ModuleRefer.PerformanceModule:AddTag(self:GetTagName())
end

function SlgScene:ExitScene(param)
    self.mapSystem:RemoveTerrainLoadedObserver(Delegate.GetOrCreate(self,self.OnTerrainLoaded))
    
    self:UnloadScene()
    
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))   
    ModuleRefer.PerformanceModule:RemoveTag(self:GetTagName())

    Utils.FullGC()
end

function SlgScene:Tick(dt)
    self.mapFoundation:Tick(dt)
end

function SlgScene:OnLateUpdate()
    local camera = self.mapFoundation.basicCamera
    if camera ~= nil and self.mapFoundation.staticMapData ~= nil then
        self:Border()
    end
end

function SlgScene:LoadScene()
    local mapInstanceConfigCell = ConfigRefer.MapInstance:Find(self.tid)
    local sceneId = mapInstanceConfigCell:SceneId()
    local mapSceneConfigCell = ConfigRefer.MapScene:Find(sceneId)

    self.scenePath = mapSceneConfigCell:ResPath()

    local ObsEnhanceId = mapInstanceConfigCell:ObserverEn()
    if ObsEnhanceId < 1 then
        ObsEnhanceId = 1
    end
    local ObsEnhanceCfg = ConfigRefer.ObserverEnhance:Find(ObsEnhanceId)
    self:SetupObserverEnhanceData(ObsEnhanceCfg)

	SceneLoadUtility.LoadSceneAsync(self.scenePath, nil, function()
        local mapSystemGo = SceneLoadUtility.GetRoot('grid_map_system_gve')
        if not mapSystemGo then
            g_Logger.Error('Can not Find Map System GameObject!')
            return
        end

        local factory = LuaTileViewFactory(SlgTileViewFactory.new())
        local kingdomViewFactory = LuaKingdomViewFactory(KingdomViewFactory.new())
        local requestService = LuaRequestService(SlgRequestService.new())
        self.mapFoundation:Setup("gve_boss_1", mapSystemGo, factory,kingdomViewFactory, requestService, nil, 0)
        self.basicCamera = self.mapFoundation.basicCamera
        self.camera = self.mapFoundation.camera
        self.camera:GetUniversalAdditionalCameraData():SetRenderer(URPRendererList.Gve)
        self.cameraLodData = self.mapFoundation.cameraLodData
        self.cameraPlaneData = self.mapFoundation.cameraPlaneData
        self.mapSystem = self.mapFoundation.mapSystem
        self.staticMapData = self.mapFoundation.staticMapData
        self.mapMarkCamera = self.mapFoundation.mapMarkCamera
        self.mapSystem:SetTimerRunning(true)
        self.mapSystem:SetSplatMap()
        
        local terrain = CS.Grid.MapUtils.GetActiveTerrain()
        self.mapSystem:SetTerrainData(terrain.terrainData, 0, 0)

        SlgCameraSettingsSetter.Set(self.basicCamera.settings, self.basicCamera, self.cameraLodData, self.cameraPlaneData)
        
        ModuleRefer.SlgModule:Init()
        ModuleRefer.SlgInterfaceModule:SetSlgModule(ModuleRefer.SlgModule)
        ModuleRefer.SlgModule:StartRunning()
        ModuleRefer.GveModule:Init()
        ModuleRefer.KingdomInteractionModule:Setup()

        require("PvPRequestService").InvalidateMapAOI()

        ModuleRefer.SlgModule:OnLodChanged(0,1)
        ModuleRefer.SlgModule:EnableTouch(true)
        local cameraSize = self.basicCamera:GetSize()
        ShadowDistanceControl.ChangeShadowCascades(CameraConst.MapShadowCascades)
        local lodData = KingdomMapUtils.GetCameraLodData()
        local sizeList = lodData.mapCameraSizeList
        local shadowDistanceList = lodData.mapShadowDistanceList
        ShadowDistanceControl.SetEnable(true)
        ShadowDistanceControl.RefreshShadow(self.basicCamera.mainCamera, cameraSize, sizeList, shadowDistanceList, CameraConst.MapShadowCascadeSizeThreshold)
        self.mapSystem:AddTerrainLoadedObserver(Delegate.GetOrCreate(self,self.OnTerrainLoaded))
        g_Game.UIManager:CloseByName(UIMediatorNames.LoadingPageMediator)
        self.sceneLoaded = true
    end)
end

---@param cfg ObserverEnhanceConfigCell
function SlgScene:SetupObserverEnhanceData(cfg)
    if not cfg then return end
    self.ObsEnhanceData = {}
    self.ObsEnhanceData.attrList = {}
    local count = cfg:CountLength()
    if count ~= cfg:EnhanceAttrLength() then
        g_Logger.Error("ObserverEnhanceConfigCell:CountLength() ~= ObserverEnhanceConfigCell:EnhanceAttrLength()")
        return
    end
    
    for i = 1, count do        
        local obsCount = cfg:Count(i)
        local enhanceCfgId = cfg:EnhanceAttr(i)
        local attrGroup = ConfigRefer.AttrGroup:Find(enhanceCfgId)
        if not attrGroup or attrGroup:AttrListLength() < 0 then
            goto continue
        end

        local firstAtt = attrGroup:AttrList(1)
        local element = ConfigRefer.AttrElement:Find(firstAtt:TypeId())
       
        local attrName = element:Name()
        local attrValue = firstAtt:Value()
        table.insert(self.ObsEnhanceData.attrList, {
            obsCount = obsCount,
            nameKey = attrName,
            value = attrValue,            
        })
        ::continue::
    end

    table.sort(self.ObsEnhanceData.attrList, function(a, b)
        return a.obsCount < b.obsCount
    end)
    if #self.ObsEnhanceData.attrList > 0 then        
        self.ObsEnhanceData.minCount = self.ObsEnhanceData.attrList[1].obsCount
        self.ObsEnhanceData.maxCount = self.ObsEnhanceData.attrList[#self.ObsEnhanceData.attrList].obsCount
    else
        self.ObsEnhanceData.minCount = 0
        self.ObsEnhanceData.maxCount = 0
    end

end

function SlgScene:GetObserverEnhanceData()
    return self.ObsEnhanceData
end

function SlgScene:OnTerrainLoaded(x, z, terrainData)
    g_Game.EventManager:TriggerEvent(EventConst.MAP_TERRAIN_LOADED, x, z)
end

function SlgScene:UnloadScene()
    g_Game.ModuleManager:RemoveModule('GveModule')
    ModuleRefer.SlgInterfaceModule:SetSlgModule(nil)
    g_Game.ModuleManager:RemoveModule("SlgModule")
    ModuleRefer.KingdomInteractionModule:ShutDown()
    self.mapSystem:SetTimerRunning(false)

    if self.mapFoundation then
        self.mapFoundation:ShutDown()
        self.mapFoundation = nil
    end

    self.basicCamera = nil
    self.camera = nil
    self.cameraLodData = nil
    self.cameraPlaneData = nil
    self.mapSystem = nil
    self.staticMapData = nil
    self.mapMarkCamera = nil
    self.sceneLoaded = false

    SceneLoadUtility.UnloadSceneAsync(self.scenePath)
end

---@param camera BasicCamera
function SlgScene:Border()
    KingdomMapUtils.Border(self.basicCamera, self.staticMapData, cityBorderLeft, cityBorderRight, cityBorderBottom, cityBorderTop)
end

function SlgScene:GetLod()
    -- if self.cameraLodData then
    --     return self.cameraLodData:GetLod()
    -- else
    --     return 0
    -- end
    return 1
end

function SlgScene:GetCamSize()
    if self.mapFoundation.cameraLodData then
        return self.mapFoundation.cameraLodData:GetSize()
    else
        return 1000
    end
end

function SlgScene:AddLodChangeListener(listener)
    -- if self.mapFoundation.cameraLodData and listener then
    --     self.mapFoundation.cameraLodData:AddLodChangeListener(listener)
    -- end
end
---@param listener fun(oldLod:number,newLod:number)
function SlgScene:RemoveLodChangeListener(listener)
    -- if self.mapFoundation.cameraLodData and listener then
    --     self.mapFoundation.cameraLodData:RemoveLodChangeListener(listener)
    -- end
end

---@param listener fun(oldSize:number,newSize:number)
function SlgScene:AddSizeChangeListener(listener)
    if self.mapFoundation.cameraLodData and listener then
        self.mapFoundation.cameraLodData:AddSizeChangeListener(listener)
    end
end
---@param listener fun(oldSize:number,newSize:number)
function SlgScene:RemoveSizeChangeListener(listener)
    if self.mapFoundation.cameraLodData and listener then
        self.mapFoundation.cameraLodData:RemoveSizeChangeListener(listener)
    end
end

function SlgScene:IsLoaded()
    return self.sceneLoaded
end

return SlgScene
