local CanUnlockFogMarker = require("CanUnlockFogMarker")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CityZoneStatus = require("CityZoneStatus")


---@class CanUnlockFogMarkerGroup:IMarkerGroup
---@field new fun(camera:BasicCamera):MyCityMarkerGroup
---@field marker CanUnlockFogMarker
---@field camera BasicCamera
---@field city City
local CanUnlockFogMarkerGroup = class("CanUnlockFogMarkerGroup")

---@param city City
---@param camera BasicCamera
function CanUnlockFogMarkerGroup:ctor(city, camera)
    self.city = city
    self.camera = camera
    self.marker = CanUnlockFogMarker.new(self.camera)
end

---@param uiMediator UnitMarkerHudUIMediator
function CanUnlockFogMarkerGroup:SetupUIMediator(uiMediator)
    self.mediator = uiMediator
    self:RefreshCanExploreZone()
end

function CanUnlockFogMarkerGroup:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_BUBBLE_STATUS_CHANGE, Delegate.GetOrCreate(self, self.RefreshCanExploreZone))
end

function CanUnlockFogMarkerGroup:RemoveEventListener()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_BUBBLE_STATUS_CHANGE, Delegate.GetOrCreate(self, self.RefreshCanExploreZone))
end

---@param city City
function CanUnlockFogMarkerGroup:OnZoneStatusChanged(city, zoneID, oldStatus, newStatus)
    self:RefreshCanExploreZone()
end

function CanUnlockFogMarkerGroup:GetMarkers()
    return {self.marker}
end

function CanUnlockFogMarkerGroup:RefreshCanExploreZone()
    local zone = self.city.zoneManager:GetCanExploreZone()
    if zone then
        local centerPosition = zone:PopBubblePosition()
        self.marker:SetWorldPosition(centerPosition)
    else
        self.marker:SetWorldPosition(nil)
    end
end

return CanUnlockFogMarkerGroup