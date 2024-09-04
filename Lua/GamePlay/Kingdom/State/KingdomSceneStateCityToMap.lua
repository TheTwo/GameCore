local KingdomSceneState = require("KingdomSceneState")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local CloudUtils = require("CloudUtils")

local MapUtils = CS.Grid.MapUtils

---@class KingdomSceneStateCityToMap:KingdomSceneState
---@field new fun():KingdomSceneStateCityToMap
---@field city City
local KingdomSceneStateCityToMap = class("KingdomSceneStateCityToMap", KingdomSceneState)
KingdomSceneStateCityToMap.Name = "KingdomSceneStateCityToMap"

local CityConst = require("CityConst")
local KingdomSceneStateMap = require("KingdomSceneStateMap")
local Delegate = require("Delegate")

function KingdomSceneStateCityToMap:Enter()
    KingdomSceneState.Enter(self)

    self.city = g_Game.StateMachine:ReadBlackboard("City")
    self.camera = self.kingdomScene.basicCamera
    self.camera:ForceGiveUpTween()
    self.city.stateMachine:ChangeState(CityConst.STATE_NORMAL)

    local bundles
    local assetNames = ModuleRefer.MapPreloadModule:GetRequiredAssets()
    g_Game.AssetManager:EnsureSyncLoadAssets(assetNames, false, nil)
    
    if g_Game.AssetManager:IsBundleMode() and not ModuleRefer.MapPreloadModule.hasChecked then
        bundles = ModuleRefer.MapPreloadModule:GetRequiredFiles(assetNames)
    end
    
    ModuleRefer.KingdomTransitionModule:ZoomOutCity(self.camera, self.city)
    CloudUtils.Cover(false, Delegate.GetOrCreate(self, self.OnCloudReadyImmediately), bundles)
end

function KingdomSceneStateCityToMap:OnCloudReadyImmediately()
    self.city:SetActive(false)
    self.camera:ZoomTo(KingdomMapUtils.GetCameraLodData().mapCameraEnterSize + 10)
    self.camera:MoveCameraOffset(-self.city:WorldOffset())

    if self.city:NeedUnloadViewWhenDisable() then
        self.city:UnloadView()
    end
    if self.city:NeedUnloadDataWhenDisable() then
        self.city:UnloadData()
    end
    if self.city:NeedUnloadBasicResource() then
        self.city:UnloadBasicResource()
    end
    self.city = nil
    self.stateMachine:ChangeState(KingdomSceneStateMap.Name)
end

function KingdomSceneStateCityToMap:Exit()
    self.camera = nil

    KingdomSceneState.Exit(self)
end

function KingdomSceneStateCityToMap:IsLoaded()
    return true
end

return KingdomSceneStateCityToMap
