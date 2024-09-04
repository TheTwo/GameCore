---@class ZoneCreepDecorationController
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field new fun():ZoneCreepDecorationController
---@field zoneId number
local ZoneCreepDecorationController = class("ZoneCreepDecorationController")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityZoneStatus = require("CityZoneStatus")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")

function ZoneCreepDecorationController:Start()
    self.city = nil
    local city = ModuleRefer.CityModule:GetMyCity()
    if not city then
        return self:DestroySelf()
    end

    if city.zoneManager:IsZoneRecoveredById(self.zoneId) then
        return self:DestroySelf()
    end
    self.city = city
    self._presetDelay = nil
end

function ZoneCreepDecorationController:OnEnable()
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_RECOVERED_PRESET_EFFECT_DELAY, Delegate.GetOrCreate(self, self.OnPresetDelay))
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnStatusChanged))
end

function ZoneCreepDecorationController:OnDisable()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_RECOVERED_PRESET_EFFECT_DELAY, Delegate.GetOrCreate(self, self.OnPresetDelay))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnStatusChanged))
end

function ZoneCreepDecorationController:OnPresetDelay(city, zoneId, delay, elementIds)
    if not city:IsMyCity() then return end
    if zoneId ~= self.zoneId then return end
    self._presetDelay = delay
end

---@param city City
function ZoneCreepDecorationController:OnStatusChanged(city, zoneId, oldStatus, newStatus)
    if not city:IsMyCity() then return end
    if zoneId ~= self.zoneId then return end
    if self._presetDelay and (oldStatus == newStatus or newStatus < CityZoneStatus.Recovered) then
        return
    end
    if newStatus == CityZoneStatus.Recovered then
        self:OnZoneRecovered(city, zoneId)
    end
end

function ZoneCreepDecorationController:OnZoneRecovered()
    if Utils.IsNull(self.behaviour) then return end
    if not self.city then return end
    local go, duration, from, to, delay, callback = self.behaviour.gameObject, 3, 0, 1, self._presetDelay or 0, Delegate.GetOrCreate(self, self.DestroySelf)
    self.city.matDissolveManager:AddToTweenDissolve(go, -1, 0, duration, from, to, delay, callback)
end

function ZoneCreepDecorationController:DestroySelf()
    if not Utils.IsNull(self.behaviour) then
        ---@type CS.QualityLevelLoader[]
        local loaders = self.behaviour.gameObject:GetComponentsInChildren(typeof(CS.QualityLevelLoader), true)
        if loaders then
            for i = 0, loaders.Length -1 do
                loaders[i]:Unload(true)
            end
        end
        CS.UnityEngine.Object.Destroy(self.behaviour.gameObject)
    end
end

return ZoneCreepDecorationController