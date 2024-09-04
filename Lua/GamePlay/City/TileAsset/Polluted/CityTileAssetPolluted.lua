local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetPolluted:CityTileAsset
---@field new fun():CityTileAssetPolluted
local CityTileAssetPolluted = class("CityTileAssetPolluted", CityTileAsset)
local Utils = require("Utils")
local TimerUtility = require("TimerUtility")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityConst = require("CityConst")

function CityTileAssetPolluted:OnTileViewInit()
    self._presetDelay = nil
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_RECOVERED_PRESET_EFFECT_DELAY, Delegate.GetOrCreate(self, self.OnPresetDealy))
    self:CheckInPreSetDelay()
end

function CityTileAssetPolluted:OnTileViewRelease()
    self._presetDelay = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_RECOVERED_PRESET_EFFECT_DELAY, Delegate.GetOrCreate(self, self.OnPresetDealy))
end

function CityTileAssetPolluted:CheckInPreSetDelay()
   if self._presetDelay then return end
   local tileView = self.tileView
    if not tileView or not tileView.tile then return end
    local cell = tileView.tile:GetCell()
    if not cell then return end
    if not cell.IsElement or not cell:IsElement() then return end
    local city = self:GetCity()
    if not city then return end
    if city.stateMachine:GetCurrentStateName() ~= CityConst.STATE_CITY_ZONE_RECOVER_EFFECT then return end
    ---@type CityStatePlayZoneRecoverEffect
    local state = city.stateMachine:GetCurrentState()
    if not state or not state.preSetDelayEle or not state.delay or state.delay <= 0 then return end
    local id = cell:UniqueId()
    if not state.preSetDelayEle[id] then return end
    self._presetDelay = state.delay
end

function CityTileAssetPolluted:OnPresetDealy(city, zoneId, delay, elementIds)
    if not elementIds or not city:IsMyCity() then return end
    local tileView = self.tileView
    if not tileView or not tileView.tile then return end
    local cell = tileView.tile:GetCell()
    if not cell then return end
    if not cell.IsElement or not cell:IsElement() then return end
    local id = cell:UniqueId()
    if not elementIds[id] then return end
    self._presetDelay = math.max(0, delay)
end

function CityTileAssetPolluted:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end
    self.go = go
    if (self._presetDelay and self._presetDelay > 0) or self:IsPolluted() then
        CS.CityMatTransitionController.KeepPolluted(go)
    end
    if self._presetDelay and self._presetDelay <= 0 then
        self._presetDelay = nil
        TimerUtility.DelayExecuteInFrame(function()
            if Utils.IsNull(self.go) then return end
            CS.CityMatTransitionController.PlayTransitionOut(self.go, 3)
        end, 1)
    end
end

function CityTileAssetPolluted:OnAssetUnload(go, fade)
    CS.CityMatTransitionController.Clear(self.go)
    self.go = nil
end

function CityTileAssetPolluted:IsPolluted()
    ---override this
    return false
end

function CityTileAssetPolluted:IsMine(...)
    ---override this
    return false
end

function CityTileAssetPolluted:OnPollutedEnter(...)
    if not self:IsMine(...) then return end
    if Utils.IsNull(self.go) then return end

    TimerUtility.DelayExecuteInFrame(function()
        if Utils.IsNull(self.go) then return end
        CS.CityMatTransitionController.PlayTransitionIn(self.go, 3)
    end, 1)
end

function CityTileAssetPolluted:OnPollutedExit(...)
    if not self:IsMine(...) then return end
    if Utils.IsNull(self.go) then return end

    if self._presetDelay then
        local d = self._presetDelay
        self._presetDelay = nil
        TimerUtility.DelayExecute(function()
            if Utils.IsNull(self.go) then return end
            CS.CityMatTransitionController.PlayTransitionOut(self.go, 3)
            self:OnOnPollutedExitEnd(3)
        end, d)
    else
        TimerUtility.DelayExecuteInFrame(function()
            if Utils.IsNull(self.go) then return end
            CS.CityMatTransitionController.PlayTransitionOut(self.go, 3)
            self:OnOnPollutedExitEnd(3)
        end, 1)
    end
end

function CityTileAssetPolluted:OnOnPollutedExitEnd(fadeDuration)
    
end

return CityTileAssetPolluted