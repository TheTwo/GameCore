local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local CityConst = require("CityConst")
local KingdomSceneStateInCity = require("KingdomSceneStateInCity")
local ConfigRefer = require("ConfigRefer")
local KingdomSceneState = require("KingdomSceneState")
local Delegate = require("Delegate")

---@class KingdomSceneStateEntryToCity:KingdomSceneState
---@field new fun(kingdomScene:KingdomScene):KingdomSceneStateEntryToCity
---@field super KingdomSceneState
---@field city MyCity
local KingdomSceneStateEntryToCity = class('KingdomSceneStateEntryToCity', KingdomSceneState)
KingdomSceneStateEntryToCity.Name = "KingdomSceneStateEntryToCity"

function KingdomSceneStateEntryToCity:Enter()
    KingdomSceneState.Enter(self)
    g_Logger.Log('KingdomSceneStateEntryToCity:Enter for SCENE_LOADED')

    self.city = self.stateMachine:ReadBlackboard("City")
    g_Game.EventManager:AddListener(EventConst.CITY_DATA_LOADED, Delegate.GetOrCreate(self, self.OnCityResDataLoaded))
    g_Game.EventManager:AddListener(EventConst.CITY_RES_LOADED, Delegate.GetOrCreate(self, self.OnCityResDataLoaded))
    g_Game.EventManager:AddListener(EventConst.REQUEST_LOADING_PROGRESS, Delegate.GetOrCreate(self, self.OnRequestLoadingProgress))

    self.city:LoadBasicResource()
    self.city:LoadData()
    self.city:LoadView()
    self.camera = self.kingdomScene.basicCamera
    self.camera:ForceGiveUpTween()
    self.camera.enableDragging = false
    self.camera.enablePinch = false

    self:OnCityResDataLoaded(self.city)
end

function KingdomSceneStateEntryToCity:Exit()
    g_Logger.Log('KingdomSceneStateEntryToCity:Exit trigger SCENE_LOADED')
    g_Game.EventManager:TriggerEvent(EventConst.SCENE_LOADED)

    self.camera.enableDragging = true
    self.camera.enablePinch = true
    ModuleRefer.KingdomTransitionModule:ZoomInCity(self.camera, self.city, self.zoomManualSize)
    self.camera = nil
    self.city = nil
    self.zoomManualSize = nil

    g_Game.EventManager:RemoveListener(EventConst.CITY_DATA_LOADED, Delegate.GetOrCreate(self, self.OnCityResDataLoaded))
    g_Game.EventManager:RemoveListener(EventConst.CITY_RES_LOADED, Delegate.GetOrCreate(self, self.OnCityResDataLoaded))
    g_Game.EventManager:RemoveListener(EventConst.REQUEST_LOADING_PROGRESS, Delegate.GetOrCreate(self, self.OnRequestLoadingProgress))

    KingdomSceneState.Exit(self)
end

function KingdomSceneStateEntryToCity:OnCityResDataLoaded(city)
    if self.city == nil then return end
    if self.city ~= city then return end

    if self.city:LoadFinished() and self.city:DataFinished() then
        self.kingdomScene.mediator.cameraSizeRule:SetBlock(true)
        self.camera:ZoomTo(CityConst.CITY_NEAR_CAMERA_SIZE)

        local position = self.city.zoneManager:SuggestEnterCityCameraLookAtPos() --self.city.zoneManager:GetZoneById(1):WorldCenter()
        local manualPos = self.stateMachine:ReadBlackboard("City_ManualCoord")
        if manualPos and ((manualPos.x and manualPos.x > 0) or (manualPos.y and manualPos.y > 0)) then
            position = self.city:GetWorldPositionFromCoord(manualPos.x, manualPos.y)
            self.zoomManualSize = ConfigRefer.CityConfig:SEBackToCityCameraSize()
        end
        self.camera:LookAt(position)
        self.stateMachine:WriteBlackboard("City", self.city)
        self.stateMachine:WriteBlackboard("SkipMoveCamera", true)
        self.stateMachine:ChangeState(KingdomSceneStateInCity.Name)
    end
end

function KingdomSceneStateEntryToCity:IsLoaded()
    return self.city ~= nil and self.city:LoadFinished() and self.city:DataFinished()
end

function KingdomSceneStateEntryToCity:OnRequestLoadingProgress()
    if self.city then self.city:TriggerLoadingEvent() end
end

return KingdomSceneStateEntryToCity

