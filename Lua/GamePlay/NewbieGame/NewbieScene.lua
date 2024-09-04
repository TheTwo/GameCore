local Scene = require("Scene")
local ConfigRefer = require("ConfigRefer")
local NewbieTileViewFactory = require("NewbieTileViewFactory")
local NewbieRequestService = require("NewbieRequestService")
local Delegate = require("Delegate")
local ModuleRefer = require('ModuleRefer')
local MapFoundation = require('MapFoundation')
local SlgCameraSettingsSetter = require('SlgCameraSettingsSetter')
local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility
local LuaTileViewFactory = CS.Grid.LuaTileViewFactory
local LuaRequestService = CS.Grid.LuaRequestService
local LuaKingdomViewFactory = CS.Grid.LuaKingdomViewFactory
local KingdomViewFactory = require("KingdomViewFactory")
local CameraUtils = require("CameraUtils")
local URPRendererList = require("URPRendererList")
local KingdomMediator = require("KingdomMediator")
local DBEntityType = require("DBEntityType")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local Utils = require("Utils")
local ProtocolId = require('ProtocolId')
local SEClientCmdType = require('SEClientCmdType')

---@class NewbieScene:Scene
local NewbieScene = class("NewbieScene", Scene)

NewbieScene.Name = "NewbieScene"

function NewbieScene:ctor()
    self.mapFoundation = MapFoundation.new()
end

function NewbieScene:EnterScene(param)
    Scene.EnterScene(self, param)

    self:LoadScene()

    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))
end

function NewbieScene:ExitScene(param)
    self:UnloadScene()

    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))

    Utils.FullGC()
end

--加载场景
function NewbieScene:LoadScene()
    local tid = g_Game.StateMachine:ReadBlackboard("BIT_PLANE_TID")
    local id = g_Game.StateMachine:ReadBlackboard("BIT_PLANE_ID")
    local mapInstanceConfigCell = ConfigRefer.MapInstance:Find(tid)
    local sceneId = mapInstanceConfigCell:SceneId()
    local mapSceneConfigCell = ConfigRefer.MapScene:Find(sceneId)

    self.scenePath = mapSceneConfigCell:ResPath()
    SceneLoadUtility.LoadSceneAsync(self.scenePath, nil, function()
        local go = SceneLoadUtility.GetRoot('grid_map_system')
        if Utils.IsNull(go) then
            return
        end

        ---@type wds.Scene
        local sceneData = g_Game.DatabaseManager:GetEntity(id, DBEntityType.Scene)
        self.bitplane = sceneData.SceneBase.BitPlaneInfos[1]

        local factory = LuaTileViewFactory(NewbieTileViewFactory.new())
        local kingdomViewFactory = LuaKingdomViewFactory(KingdomViewFactory.new())
        local requestService = LuaRequestService(NewbieRequestService.new(self.bitplane.OffsetX, self.bitplane.OffsetY))

        local globalOffset = CS.UnityEngine.Vector2(-self.bitplane.OffsetX, -self.bitplane.OffsetY)
        local levelBias = g_Game.PerformanceLevelManager.qualityLevelConfig:MapSliceLevelBias()
        self.mapFoundation:Setup(MapFoundation.MapName, go, factory,kingdomViewFactory, requestService, globalOffset, levelBias)
        self.root = go
        self.basicCamera = self.mapFoundation.basicCamera
        self.camera = self.mapFoundation.camera
        self.camera:GetUniversalAdditionalCameraData():SetRenderer(URPRendererList.Map)
        self.cameraLodData = self.mapFoundation.cameraLodData
        self.cameraPlaneData = self.mapFoundation.cameraPlaneData
        self.mapSystem = self.mapFoundation.mapSystem
        self.mapSystem:SetTimerRunning(true)
        self.staticMapData = self.mapFoundation.staticMapData
        self.mapMarkCamera = self.mapFoundation.mapMarkCamera

        SlgCameraSettingsSetter.Set(self.basicCamera.settings, self.basicCamera, self.cameraLodData, self.cameraPlaneData)

        self.mediator = KingdomMediator.new()
        self.mapSystem:AddTerrainLoadedObserver(self.mediator:GetTerrainLoadedCallback())

        self.mediator:Initialize()
        self.mediator.cameraSizeRule:SetBlock(false)
        self.mediator:LoadEnvironmentSettings(self.staticMapData, function()
            ModuleRefer.MapCreepModule:Setup(self.basicCamera, self.staticMapData)
            ModuleRefer.MapFogModule:Setup()
        end)

        ModuleRefer.SlgModule:Init()
        ModuleRefer.SlgInterfaceModule:SetSlgModule(ModuleRefer.SlgModule)
        ModuleRefer.SlgModule:StartRunning()
        ModuleRefer.SlgModule:EnableTouch(true)
        ModuleRefer.KingdomInteractionModule:Setup()

        ModuleRefer.TerritoryModule:SetupView()

        g_Game.UIManager:Open(UIMediatorNames.HUDMediator,{troopListMode = 1})

        local toPos = self.bitplane.FakeCastlePosition
        local worldPos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(toPos.X, toPos.Y, self.mapSystem)
		self.basicCamera:LookAt(worldPos)

	    g_Game.EventManager:TriggerEvent(EventConst.SCENE_LOADED)
        self.sceneLoaded = true
    end)

    g_Game.EventManager:AddListener(EventConst.HUD_GOTO_MY_CITY, Delegate.GetOrCreate(self, self.ReturnMyCity))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.BroadcastCmd, Delegate.GetOrCreate(self, self.BroadcastCmd))
end

--todo 抽空搞个和se统一的broadcast
function NewbieScene:BroadcastCmd(isSucceed, msg)
    if (msg.CmdType == wrpc.CmdType.CmdTypeStartClientCmd) then
        local cmdId = msg.Params[1]
        local cmdConf = ConfigRefer.ClientCmdSe:Find(cmdId)
        if (cmdConf) then
            if (cmdConf:SeCmdType() == SEClientCmdType.GuideStart) then
                if cmdConf:StringParamsLength() > 0 then
                    local strId = cmdConf:StringParams(1)
                    local id = tonumber(strId)
                    if id and id > 0 then
                        ModuleRefer.GuideModule:CallGuide(id, function()
                            self:EndClientCommand(cmdConf)
                        end)
                    end
                end
            end
        end
    end
end

function NewbieScene:EndClientCommand(cmd)
    if (not cmd) then
        return
    end
    local msg = require("NotifyCmdParameter").new()
    msg.args.CmdType = wrpc.CmdType.CmdTypeStopClientCmd
    msg.args.Params:Add(cmd:Id())
    msg:Send()
end

--卸载场景
function NewbieScene:UnloadScene()
    self.mapSystem:SetTimerRunning(false)
    self.mapSystem:RemoveTerrainLoadedObserver(self.mediator:GetTerrainLoadedCallback())

    self.mapFoundation:ShutDown()
    self.basicCamera = nil
    self.camera = nil
    self.cameraLodData = nil
    self.cameraPlaneData = nil
    self.mapSystem = nil
    self.staticMapData = nil
    self.mapMarkCamera = nil

    if self.mediator then
        self.mediator:UnloadEnvironmentSettings()
        self.mediator.cameraSizeRule:SetBlock(true)
        self.mediator:Release()
        self.mediator = nil
    end

    ModuleRefer.SlgInterfaceModule:SetSlgModule(nil)
    g_Game.ModuleManager:RemoveModule("SlgModule")
    ModuleRefer.KingdomInteractionModule:ShutDown()

    ModuleRefer.MapCreepModule:ShutDown()
    ModuleRefer.TerritoryModule:ReleaseView()
    ModuleRefer.MapFogModule:ShutDown()

    g_Game.UIManager:CloseByName(UIMediatorNames.HUDMediator)

    SceneLoadUtility.UnloadSceneAsync(self.scenePath)

    g_Game.EventManager:RemoveListener(EventConst.HUD_GOTO_MY_CITY, Delegate.GetOrCreate(self, self.ReturnMyCity))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.BroadcastCmd, Delegate.GetOrCreate(self, self.BroadcastCmd))
    self.sceneLoaded = false
end

function NewbieScene:Border()
    if self.bitplane == nil or self.basicCamera == nil or self.staticMapData == nil then
        return
    end

    local sizeX, sizeZ = self.bitplane.Width * self.staticMapData.UnitsPerTileX, self.bitplane.Height * self.staticMapData.UnitsPerTileZ
    local centerX, centerZ = 0.5 * sizeX, 0.5 * sizeZ
    CameraUtils.ClampToBorder(self.basicCamera, centerX, centerZ, sizeX, sizeZ)
end

function NewbieScene:Tick(dt)
    if Utils.IsNull(self.root) then
        return
    end
    self.mapFoundation:Tick(dt)
end

function NewbieScene:OnLateUpdate()
    self:Border()
end

function NewbieScene:GetLod()
    if self.cameraLodData then
        return self.cameraLodData:GetLod()
    else
        return 0
    end
end

function NewbieScene:GetCamSize()
    if self.cameraLodData then
        return self.cameraLodData:GetSize()
    else
        return 1000
    end
end

function NewbieScene:AddLodChangeListener(listener)
    if self.cameraLodData and listener then
        self.cameraLodData:AddLodChangeListener(listener)
    end
end
---@param listener fun(oldLod:number,newLod:number)
function NewbieScene:RemoveLodChangeListener(listener)
    if self.cameraLodData and listener then
        self.cameraLodData:RemoveLodChangeListener(listener)
    end
end

---@param listener fun(oldSize:number,newSize:number)
function NewbieScene:AddSizeChangeListener(listener)
    if self.cameraLodData and listener then
        self.cameraLodData:AddSizeChangeListener(listener)
    end
end
---@param listener fun(oldSize:number,newSize:number)
function NewbieScene:RemoveSizeChangeListener(listener)
    if self.cameraLodData and listener then
        self.cameraLodData:RemoveSizeChangeListener(listener)
    end
end

function NewbieScene:InCityLod()
    return false
end

function NewbieScene:ReturnMyCity()
    -- GotoUtils.GotoSceneCity()
end

function NewbieScene:IsLoaded()
    return self.sceneLoaded
end

return NewbieScene
