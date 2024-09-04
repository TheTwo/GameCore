local ConfigRefer = require("ConfigRefer")

local CityElement = require("CityElement")
---@class CityElementSpawner:CityElement
---@field new fun(mgr:CityElementManager, configCell:CityElementDataConfigCell):CityElementSpawner
local CityElementSpawner = class("CityElementSpawner", CityElement)

---@param mgr CityElementManager
---@param configCell CityElementDataConfigCell
function CityElementSpawner:ctor(mgr, configCell)
    CityElement.ctor(self, mgr)
    self:FromElementDataCfg(configCell)
    self.configSpawnerId = configCell:ElementId()
    self.hasRangeCircle = false
    local spawnerConfig = ConfigRefer.CityElementSpawner:Find(self.configSpawnerId)
    if spawnerConfig and spawnerConfig:RangeCircleAsset() ~= 0 then
        self.hasRangeCircle = true
    end
end

function CityElementSpawner:IsSpawner()
    return true
end

function CityElementSpawner:CanShowBubble()
    local city = self.mgr.city
    if city:IsInSeBattleMode() or city:IsInSingleSeExplorerMode() or city:IsInRecoverZoneEffectMode() then return false end
    if not self.mgr:IsSpawnerActived(self.id) or not self.mgr:IsSpawnerLinkExpeditionInfoCreated(self.id) then return false end
    if self.mgr:IsSpawnerLinkExpeditionInBattle(self.id) then return false end
    local zone = self.mgr.city.zoneManager:GetZone(self.x, self.y)
    if zone and zone:SingleSeExplorerOnly() then return false end
    if zone and not zone:IsHideFog() then return false end
    return true
end

function CityElementSpawner:CanShowRangeCircle()
    if not self.hasRangeCircle then return false end
    if not self.mgr:IsSpawnerActived(self.id) or not self.mgr:IsSpawnerLinkExpeditionInfoCreated(self.id) then return false end
    local zone = self.mgr.city.zoneManager:GetZone(self.x, self.y)
    if zone and not zone:IsHideFog() then return false end
    return self.mgr:IsSpawnerLinkExpeditionInBattle(self.id)
end

return CityElementSpawner