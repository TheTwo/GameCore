local CityManagerBase = require("CityManagerBase")
---@class CityFogManager:CityManagerBase 城内雾效数据源
---@field new fun(city):CityFogManager
local CityFogManager = class("CityFogManager", CityManagerBase)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ManualResourceConst = require("ManualResourceConst")

---@param zone CityZone
---@return number @byte
function CityFogManager.GetFogBit(zone)
    if zone then
        if zone:IsHideFogForExploring() then
            return 255
        end
    end
    return 0
end

---@param city City
---@param gridConfig CityGridConfig
function CityFogManager:DoDataLoad()
    self.gridConfig = self.city.gridConfig
    
    self.zoneStatusMap = {}
    for _, configCell in ConfigRefer.CityZone:pairs() do
        local id = configCell:Id()
        local zone = self.city.zoneManager:GetZoneById(id)
        self.zoneStatusMap[id] = CityFogManager.GetFogBit(zone)
    end

    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged));
    return self:DataLoadFinish()
end

function CityFogManager:DoDataUnload()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged));

    g_Game.VisualEffectManager.manager:Clear("CityFogManager")

    self.zoneStatusMap = nil
end

function CityFogManager:OnBasicResourceLoadFinish()
    self.fogController = self.city.fogController
end

function CityFogManager:OnBasicResourceUnloadStart()
    self.fogController = nil
end

function CityFogManager:OnViewLoadStart()
    local reciprocal = 1 / (self.gridConfig.cellsX * self.gridConfig.unitsPerCellX * self.city.scale)
    self.fogController:Init(self.gridConfig.cellsX, self.gridConfig.cellsY,
            self.city.zeroPoint.x, self.city.zeroPoint.z,
            reciprocal, nil)
    local dataProviderUsage = self.city:GetZoneSliceDataUsage()
    self.fogController:LoadFromBinData(dataProviderUsage)
end

function CityFogManager:OnZoneStatusChanged(city, changedMap)
    if city ~= self.city then return end

    local noAni = true
    local canUseAniHide = {}
    local canUseAniShow = {}
    for id, _ in pairs(changedMap) do
        local zone = self.city.zoneManager:GetZoneById(id)
        local fogBit = CityFogManager.GetFogBit(zone)
        if self.zoneStatusMap[id] ~= fogBit then
            if not self.zoneStatusMap[id] or self.zoneStatusMap[id] < 255 then
                table.insert(canUseAniHide, {id, fogBit})
            else
                table.insert(canUseAniShow, {id, fogBit})
            end
        end
        self.zoneStatusMap[id] = fogBit
    end
    if #canUseAniShow > 0 then
        for _, changePair in ipairs(canUseAniShow) do
            self.city.fogController:HideZoneFogWithAni(changePair[1], changePair[2])
        end
        noAni = false
    end
    if #canUseAniHide > 0 then
        for _, changePair in ipairs(canUseAniHide) do
            self.city.fogController:HideZoneFogWithAni(changePair[1], changePair[2])
            local zone = self.city.zoneManager:GetZoneById(changePair[1])
            if changePair[2] >= 255 then
                local handle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
                handle:Create(ManualResourceConst.fx_city_cloud_clear, "CityFogManager", self.city.CityRoot.transform, function(flag, obj, tHandle)
                    if not flag then return end
                    tHandle.Effect.transform.position = zone:WorldCenter()
                    g_Game.SoundManager:Play("sfx_se_world_cleanup_mist", tHandle.Effect.gameObject)
                end)
            end
        end
        g_Game.EventManager:TriggerEvent(EventConst.CITY_FOG_UNLOCK_CHANGED, self.city)
        --- 雾消失时给新手引导模块发消息通知
        g_Game.EventManager:TriggerEvent(EventConst.ON_UNLOCK_CITY_FOG)
        noAni = false
    end
    if noAni then
        self.city:UpdateFog()
    end
    self.city:UpdateMapGridView()
end

function CityFogManager:GetZoneStatusMap()
    return self.zoneStatusMap
end

function CityFogManager:SelectZone(id)
    local zone = self.city.zoneManager:GetZoneById(id)
    if zone and not zone:IsHideFogForExploring() then
        local changeZoneSelected = {}
        changeZoneSelected[id] = true
        self.city.fogController:ChangeSelectFogStatus(changeZoneSelected)
    end
end

function CityFogManager:UnSelectZone(id)
    local zone = self.city.zoneManager:GetZoneById(id)
    if zone then
        local changeZoneSelected = {}
        changeZoneSelected[id] = false
        self.city.fogController:ChangeSelectFogStatus(changeZoneSelected)
    end
end

function CityFogManager:IsValid()
    return self.zoneStatusMap ~= nil
end

function CityFogManager:NeedLoadData()
    return true
end

return CityFogManager