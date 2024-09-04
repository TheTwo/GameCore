local KingdomSceneState = require("KingdomSceneState")
local CityConst = require("CityConst")
local KingdomSceneStateInCity = require("KingdomSceneStateInCity")
local KingdomSceneStateMap = require("KingdomSceneStateMap")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local CloudUtils = require("CloudUtils")
local CameraConst = require("CameraConst")
local ModuleRefer = require("ModuleRefer")

local MapUtils = CS.Grid.MapUtils

---@class KingdomSceneStateMapToCity:KingdomSceneState
---@field new fun():KingdomSceneStateMapToCity
---@field city City
local KingdomSceneStateMapToCity = class("KingdomSceneStateMapToCity", KingdomSceneState)
KingdomSceneStateMapToCity.Name = "KingdomSceneStateMapToCity"

function KingdomSceneStateMapToCity:Enter()
    KingdomSceneState.Enter(self)

    self.city = self.stateMachine:ReadBlackboard("City")
    self.callback = self.stateMachine:ReadBlackboard("EnterCityCallback")
    self.anchoredPosition = self.city:GetKingdomMapPosition()
    
    self.camera = self.kingdomScene.basicCamera
    self.camera:ForceGiveUpTween()

    ModuleRefer.KingdomTransitionModule:ZoomInMap(self.camera)
    CloudUtils.Cover(true, Delegate.GetOrCreate(self, self.OnCloudReadyImmediately))
end

function KingdomSceneStateMapToCity:ReEnter()
    local city = self.stateMachine:ReadBlackboard("City")
    if city ~= nil and city ~= self.city then
        self:Exit()
        self.stateMachine:WriteBlackboard("City", city)
        self:Enter()
    end
end

function KingdomSceneStateMapToCity:OnCloudReadyImmediately()
    self.kingdomScene.mediator.cameraSizeRule:SetBlock(true)

    self.city:LoadBasicResource()
    self.city:LoadData()
    self.city:LoadView()
    if self.city:LoadFinished() and self.city:DataFinished() then
        self:SetCamereIntoCity()
    else
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTickWaitFinished))
    end
end

function KingdomSceneStateMapToCity:SetCamereIntoCity()
    -- self.anchoredPosition = self.city.zoneManager:GetZoneById(1):WorldCenter() - self.city:WorldOffset()
    self.anchoredPosition = self.city.zoneManager:SuggestEnterCityCameraLookAtPos() - self.city:WorldOffset()
    self.camera:LookAt(self.anchoredPosition)
    self.camera:ZoomTo(CityConst.CITY_NEAR_CAMERA_SIZE)
    ModuleRefer.KingdomTransitionModule:ZoomInCity(self.camera, self.city)
    self:EnterCityState()
end

function KingdomSceneStateMapToCity:OnTickWaitFinished(deltaTime)
    if self.city:LoadFinished() and self.city:DataFinished() then
        self:SetCamereIntoCity()
    end
end

function KingdomSceneStateMapToCity:Exit()
    KingdomSceneStateMap.PostEndMap()
    
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTickWaitFinished))

    self.camera = nil
    self.city = nil

    self.kingdomScene.mediator:UnloadEnvironmentSettings()
    if self.callback then
        self.callback()
        self.callback = nil
    end
    
    KingdomSceneState.Exit(self)
end

function KingdomSceneStateMapToCity:EnterCityState()
    self.stateMachine:WriteBlackboard("City", self.city)
    local manualPos = self.stateMachine:ReadBlackboard("City_ManualCoord")
    if manualPos and (manualPos.x > 0 or manualPos.y > 0) then
        local position = self.city:GetWorldPositionFromCoord(manualPos.x, manualPos.y)
        self.camera:LookAt(position)
    end
    self.stateMachine:ChangeState(KingdomSceneStateInCity.Name)
end

function KingdomSceneStateMapToCity:IsLoaded()
    return true
end

return KingdomSceneStateMapToCity