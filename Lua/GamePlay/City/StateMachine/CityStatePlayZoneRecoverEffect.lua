local CityConst = require("CityConst")
local ManualResourceConst = require("ManualResourceConst")
local Utils = require("Utils")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ProtocolId = require("ProtocolId")

local CityState = require("CityState")

local ControlHudPart = (HUDMediatorPartDefine.everyThing & ~HUDMediatorPartDefine.bossInfo)

---@class CityStatePlayZoneRecoverEffect:CityState
---@field super CityState
local CityStatePlayZoneRecoverEffect = class("CityStatePlayZoneRecoverEffect", CityState)

function CityStatePlayZoneRecoverEffect:Enter()
    self.preSetDelayEle = {}
    self.needDismissTeam = self.stateMachine:ReadBlackboard("needDismissTeam")
    self.duration = self.stateMachine:ReadBlackboard("duration")
    self.delay = self.stateMachine:ReadBlackboard("delay")
    self.zoneId = self.stateMachine:ReadBlackboard("zoneId")
    self.elementIds = self.stateMachine:ReadBlackboard("elementIds") or {}
    self.fromExplore = self.stateMachine:ReadBlackboard("fromExplore") or false
    ---@type CS.DragonReborn.SoundPlayingHandle
    self.audioHandle = nil
    local hudHidePart = self.stateMachine:ReadBlackboard("hudHidePart")
    local camera = self.city:GetCamera()
    camera:ForceGiveUpTween()
    camera.enableDragging = false
    camera.enablePinch = false
    local _, maxSize = self.city:GetCameraMaxSize()
    camera:ZoomTo(maxSize, 0.2)
    local cameraRoot = camera:GetUnityCamera().transform
    self._vfx = self.city.createHelper:Create(ManualResourceConst.vfx_w_city_clean_lz, cameraRoot, function(go, data, handle)
        ---@type CS.UnityEngine.GameObject
        local effect = go
        if Utils.IsNull(effect) then return end
        local trans = effect.transform
        trans.localPosition = CS.UnityEngine.Vector3(0,0,5)
        trans.localScale = CS.UnityEngine.Vector3.one
        trans.localEulerAngles = CS.UnityEngine.Vector3.zero
        effect:SetLayerRecursively("City", false)
    end)
    if hudHidePart then
        self._lastChangedHud = hudHidePart
    else
        self._lastChangedHud = nil
        ---@type HUDMediator
        local hud = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
        if hud then
            self._lastChangedHud = hud:ShowHidePartChanged(ControlHudPart, false)
        else
            g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, ControlHudPart, false)
        end
    end

    for _, value in pairs(self.elementIds) do
        self.preSetDelayEle[value] = true
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ZONE_RECOVERED_PRESET_EFFECT_DELAY, self.city, self.zoneId, self.delay, self.preSetDelayEle)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CitySafeAreaPlaceTipMediator)
    self.city.cityExplorerManager:SetAllowTeamTroopTriggerOn(false)
    local zone = self.city.zoneManager:GetZoneById(self.zoneId)
    if zone then
        local playAudioId = zone.config:RecoverAudio()
        if playAudioId ~= 0 then
            self.audioHandle = g_Game.SoundManager:PlayAudio(playAudioId)
        end
    end
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.RecallHomeSeTroop, Delegate.GetOrCreate(self, self.OnTeamDismiss))
end

function CityStatePlayZoneRecoverEffect:Exit()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.RecallHomeSeTroop, Delegate.GetOrCreate(self, self.OnTeamDismiss))
    if self.audioHandle and self.audioHandle:IsValid() then
        g_Game.SoundManager:Stop(self.audioHandle)
    end
    self.audioHandle = nil
    self.preSetDelayEle = {}
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CitySafeAreaPlaceTipMediator)
    local camera = self.city:GetCamera()
    if camera then
        camera:ForceGiveUpTween()
        camera.enableDragging = true
        camera.enablePinch = true
    end
    local changed = self._lastChangedHud
    self._lastChangedHud = nil
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, ControlHudPart, true, changed)
    if self._vfx then
        self._vfx:Delete()
    end
    self._vfx = nil
    self.city.cityExplorerManager:SetAllowTeamTroopTriggerOn(true)
    local willTransTo = self.stateMachine.willTransToStateName
    if (willTransTo ~= CityConst.STATE_CITY_SE_EXPLORER_FOCUS
            and willTransTo ~= CityConst.STATE_CITY_SE_BATTLE_FOCUS
            and willTransTo ~= CityConst.STATE_CITY_ZONE_RECOVER_EFFECT
    )
    then
        self.PostProcessStateChange = Delegate.GetOrCreate(self, self.OnPostProcessStateChange)
    else
        self.PostProcessStateChange = nil
    end
end

function CityStatePlayZoneRecoverEffect:OnPostProcessStateChange()
    if not self.city or not self.city.citySeManger then return end
    local currentState = self.stateMachine:GetCurrentState()
    local currentStateName = currentState:GetName()
    if currentStateName == "CityStateSeExplorerFocus" then return end
    if currentStateName == "CityStateSeBattle" then return end
    if currentStateName == "CityStatePlayZoneRecoverEffect" then return end
    self.city.citySeManger:ExitExplorerFocus()
end

function CityStatePlayZoneRecoverEffect:Tick(dt)
    if not self.duration then
        return
    end
    if self.delay then
        self.delay = self.delay - dt
        if self.delay <= 0 then
            ---@type CitySafeAreaPlaceTipMediatorParameter
            local param = {}
            param.zoneTitle = "ZONE"
            param.zoneContent = I18N.Get("day1_3_tab_name")
            local zone = self.city.zoneManager:GetZoneById(self.zoneId)
            if zone then
                param.playAudioId = zone.config:BannerShowAudio()
            end
            g_Game.UIManager:Open(UIMediatorNames.CitySafeAreaPlaceTipMediator, param)
            self.delay = nil
        end
    end
    self.duration = self.duration - dt
    if self.duration <= 0 then
        self.duration = nil
        self:ExitToOther()
    end
end

function CityStatePlayZoneRecoverEffect:ExitToOther()
    local camera = self.city:GetCamera()
    if self.needDismissTeam then
        local team = self.city.cityExplorerManager:GetTeamByPresetIndex(self.needDismissTeam)
        if team then
            self.city.cityExplorerManager:SendDismissTeam(team)
            return
        end
    end
    camera:ForceGiveUpTween()
    self:RefreshCameraSizeLimit()
    camera:ZoomTo(CityConst.CITY_RECOMMEND_CAMERA_SIZE, 0.2, Delegate.GetOrCreate(self, self.ExitToIdleState))
end

function CityStatePlayZoneRecoverEffect:OnTeamDismiss(isSuccess, _)
    if not isSuccess or not self.needDismissTeam then return end
    local camera = self.city:GetCamera()
    local zone = self.city.zoneManager:GetZoneById(self.zoneId)
    if zone and zone.config and zone.config.ExitExploreModeJumpToCityConfigExplorSeExitToZone then
        if zone.config:ExitExploreModeJumpToCityConfigExplorSeExitToZone() then
            local targetZone = self.city.zoneManager:GetZoneById(ConfigRefer.CityConfig:ExplorSeExitToZone())
            if targetZone then
                local centerPos = targetZone:WorldCenter()
                camera:ForceGiveUpTween()
                self:RefreshCameraSizeLimit()
                camera:ZoomToWithFocus(CityConst.CITY_RECOMMEND_CAMERA_SIZE, CS.UnityEngine.Vector3(0.5, 0.5, 0) ,centerPos, 0.2, Delegate.GetOrCreate(self, self.ExitToIdleState))
                return
            end
        end
    end
    camera:ForceGiveUpTween()
    self:RefreshCameraSizeLimit()
    camera:ZoomTo(CityConst.CITY_RECOMMEND_CAMERA_SIZE, 0.2, Delegate.GetOrCreate(self, self.ExitToIdleState))
end

function CityStatePlayZoneRecoverEffect:RefreshCameraSizeLimit()
    ---@type KingdomScene
    local kingdomScene = g_Game.SceneManager.current
    if kingdomScene then
        ---@type KingdomSceneStateInCity
        local state = kingdomScene.stateMachine:GetCurrentState()
        if state and state.SetCameraSize then
            state:SetCameraSize()
        end
    end
end

return CityStatePlayZoneRecoverEffect