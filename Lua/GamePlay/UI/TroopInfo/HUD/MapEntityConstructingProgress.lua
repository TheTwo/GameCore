local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local Delegate = require("Delegate")
local MapHudTransformControl = require("MapHudTransformControl")

local one = CS.UnityEngine.Vector3.one

---@class MapEntityConstructingProgress
---@field construction wds.BuildingConstruction
---@field behavior CityProgressBar
local MapEntityConstructingProgress = class("MapEntityConstructingProgress")

---@param go CS.UnityEngine.GameObject
function MapEntityConstructingProgress:Setup(go)
    self.behavior = go:GetLuaBehaviour("CityProgressBar").Instance
    self.behavior:ResetToNormal()
    self.behavior:UpdateIcon("sp_city_icon_hammer_1")

    local cameraZoomBehavior = self.behavior.root:GetLuaBehaviour("CityAssetCameraZoom")
    if cameraZoomBehavior then
        ---@type CityAssetCameraZoom
        local cameraZoom = cameraZoomBehavior.Instance
        cameraZoom:ClearCamera()
    end
    self.behavior:SetOrthographicScale(0.0006)

    local basicCamera = KingdomMapUtils.GetBasicCamera()
    basicCamera:AddSizeChangeListener(Delegate.GetOrCreate(self, self.RefreshScale))
    self:RefreshScale()
end

function MapEntityConstructingProgress:ShutDown()
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    basicCamera:RemoveSizeChangeListener(Delegate.GetOrCreate(self, self.RefreshScale))
end

function MapEntityConstructingProgress:RefreshScale()
    self:SetScale(one * MapHudTransformControl.scale)
end

function MapEntityConstructingProgress:SetPosition(offset)
    self.behavior:UpdateLocalOffset(offset)
end

function MapEntityConstructingProgress:SetOffset(offset)
    self.behavior:UpdateLocalOffset(offset)
end

function MapEntityConstructingProgress:SetRotation(rotation)
    self.behavior:UpdateLocalRotation(rotation)
end

function MapEntityConstructingProgress:SetScale(scale)
    self.behavior:UpdateLocalScale(scale)
end

---@param entity wds.MobileFortress|wds.DefenceTower|wds.EnergyTower
---@return boolean, number, string
function MapEntityConstructingProgress.IsFinished(entity)
    local progress,timeStr
    ---@type wds.BuildingConstruction
    local construction = entity.Construction
    if not construction then
        return true,progress,timeStr
    end

    if ModuleRefer.KingdomConstructionModule:IsBuildingConstructing(entity) then
        local maxBuildValue
        local buildSpeedInterval
        if construction.ConfigId ~= 0 then
            local buildConfig = ConfigRefer.MapBuildingConstruction:Find(construction.ConfigId)
            if buildConfig then
                maxBuildValue = buildConfig:DurabilityValue()
                buildSpeedInterval = buildConfig:DurabilitySettleInterval()
            end
        else
            local mapBasic = entity.MapBasics
            if mapBasic and mapBasic.ConfID then
                local buildConfig = ConfigRefer.FlexibleMapBuilding:Find(mapBasic.ConfID)
                if buildConfig then
                    maxBuildValue = buildConfig:BuildValue()
                    buildSpeedInterval = buildConfig:BuildSpeedTime()
                end
            end
        end
        if not buildSpeedInterval or not maxBuildValue or buildSpeedInterval <= 0 then
            return true,progress,timeStr
        end
        local increment = 0
        local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        if construction.LastSettleTime.ServerSecond > 0 then
            increment = math.max(0, serverTime - construction.LastSettleTime.ServerSecond) / buildSpeedInterval * construction.BuildSpeed
        end
        local nowValue = increment + construction.BuildingValue
        progress = math.inverseLerp(0, maxBuildValue, nowValue)
        if construction.BuildSpeed > 0 then
            local remainingTime = math.max(0, maxBuildValue - nowValue) / construction.BuildSpeed * buildSpeedInterval
            timeStr = TimeFormatter.SimpleFormatTime(remainingTime)
        end
        return false,progress,timeStr
    end
    return true,progress,timeStr
end

---@param entity wds.MobileFortress|wds.DefenceTower|wds.EnergyTower
---@return boolean
function MapEntityConstructingProgress:UpdateProgress(entity)
    local isFinished, progress, timeStr = MapEntityConstructingProgress.IsFinished(entity)
    if isFinished then
        self.behavior:ShowProgress(false)
        self.behavior:ShowTime(false)
    else
        self.behavior:ShowProgress(true)
        self.behavior:ShowTime(true)
        self.behavior:UpdateProgress(progress)
        self.behavior:UpdateTime(timeStr)
    end
end

return MapEntityConstructingProgress