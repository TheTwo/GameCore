---@class ZoneNonCreepSpringUpController
---@field new fun():ZoneNonCreepSpringUpController
---@field zoneId number
---@field curveHolder CS.AnimationCurveHolder
---@field curveName string
local ZoneNonCreepSpringUpController = class("ZoneNonCreepSpringUpController")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityZoneStatus = require("CityZoneStatus")
local Utils = require("Utils")

function ZoneNonCreepSpringUpController:Start()
    local city = ModuleRefer.CityModule:GetMyCity()
    if not city then
        return
    end

    if city.zoneManager:IsZoneRecoveredById(self.zoneId) then
        return
    end
    ---@type CS.CityTransformTweenScaleController
    self.controller = self.behaviour.gameObject:GetComponent(typeof(CS.CityTransformTweenScaleController))
    if Utils.IsNull(self.controller) then
        self.controller = self.behaviour.gameObject:AddComponent(typeof(CS.CityTransformTweenScaleController))
    end
    self.controller:Initialize(CS.UnityEngine.Vector3(1, 0, 1))
    self._presetDelay = nil
end

function ZoneNonCreepSpringUpController:OnEnable()
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_RECOVERED_PRESET_EFFECT_DELAY, Delegate.GetOrCreate(self, self.OnPresetDelay))
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnStatusChanged))
end

function ZoneNonCreepSpringUpController:OnDisable()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_RECOVERED_PRESET_EFFECT_DELAY, Delegate.GetOrCreate(self, self.OnPresetDelay))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnStatusChanged))
end

---@param city City
---@param zoneId number
---@param oldStatus CityZoneStatus
---@param newStatus CityZoneStatus
function ZoneNonCreepSpringUpController:OnStatusChanged(city, zoneId, oldStatus, newStatus)
    if not city:IsMyCity() then return end
    if zoneId ~= self.zoneId then return end
    if self._presetDelay and (oldStatus == newStatus or newStatus < CityZoneStatus.Recovered) then
        return
    end
    if newStatus == CityZoneStatus.Recovered then
        self:OnZoneRecovered(city, zoneId)
    end
end

function ZoneNonCreepSpringUpController:OnZoneRecovered()
    if not self.controller then return end

    local to = CS.UnityEngine.Vector3.one
    local duration, delay = 1, 0.5
    delay = delay + (self._presetDelay or 0)

    local curve = nil
    if Utils.IsNotNull(self.curveHolder) then
        curve = self.curveHolder:GetCurve(self.curveName)
    end
    if curve then
        self.controller:DOTweenScale(to, duration, delay, nil, curve)
    else
        self.controller:DOTweenScale(to, duration, delay)
    end
end

function ZoneNonCreepSpringUpController:OnPresetDelay(city, zoneId, delay, elementIds)
    if not city:IsMyCity() then return end
    if zoneId ~= self.zoneId then return end
    self._presetDelay = delay
end

return ZoneNonCreepSpringUpController