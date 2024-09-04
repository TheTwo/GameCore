---@class MapResourceFieldDatum
---@field new fun():MapResourceFieldDatum
local MapResourceFieldDatum = class("MapResourceFieldDatum")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local OutputResourceType = require("OutputResourceType")
local KingdomMapUtils = require("KingdomMapUtils")

---@param entity wds.ObservableInfo
function MapResourceFieldDatum:ctor(entity)
    self.entity = entity
end

function MapResourceFieldDatum:GetName()
    local cfg = self:GetConfigCell()
    if cfg == nil then return "#未知资源" end

    return I18N.Get(cfg:Name())
end

function MapResourceFieldDatum:GetLevelText()
    local cfg = self:GetConfigCell()
    if cfg == nil then return "Lv.0" end

    return ("Lv.%d"):format(cfg:Level())
end

function MapResourceFieldDatum:IconPath()
    local cfg = self:GetConfigCell()
    if cfg == nil then return 0 end

    return cfg:Image()
end

function MapResourceFieldDatum:GetPositionText()
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(self.entity.Basic.Pos)
    return ("X:%d Y:%d"):format(tileX, tileZ)
end

function MapResourceFieldDatum:IsTransforming()
    return self.entity.Resource.State == wds.ResourceFieldState.ResourceStateBuilding
end

function MapResourceFieldDatum:IsRebuilt()
    return self.entity.Basic.ConfigId ~= self.entity.Resource.OriginConfId
end

function MapResourceFieldDatum:TransformProgress()
    if not self:IsTransforming() then return 0 end

    local startTime = self.entity.Resource.StartBuildTime.ServerSecond
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local cfg = ConfigRefer.FixedMapBuilding:Find(self.entity.Resource.RebuildConfId)
    local endTime = startTime + cfg:BuildTime()

    if endTime - startTime <= 0 then return 0 end
    return (now - startTime) / (endTime - startTime)
end

function MapResourceFieldDatum:TransformRemainTime()
    if not self:IsTransforming() then return 0 end

    local startTime = self.entity.Resource.StartBuildTime.ServerSecond
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local cfg = ConfigRefer.FixedMapBuilding:Find(self.entity.Resource.RebuildConfId)
    local endTime = startTime + cfg:BuildTime()
    return endTime - now
end

function MapResourceFieldDatum:IsGivingUp()
    return self.entity.Resource.State == wds.ResourceFieldState.ResourceStateGivingUp
end

function MapResourceFieldDatum:GiveUpEndTime()
    if not self:IsGivingUp() then return 0 end

    local cfg = self:GetConfigCell()
    if cfg == nil then return 0 end

    local startTime = self.entity.Resource.StartGiveUpTime.ServerSecond
    return startTime + cfg:BuildTime()
end

function MapResourceFieldDatum:GiveUpSliderValue()
    if not self:IsGivingUp() then return 0 end

    local cfg = self:GetConfigCell()
    if cfg == nil then return 0 end

    local startTime = self.entity.Resource.StartGiveUpTime.ServerSecond
    local endTime = startTime + cfg:BuildTime()
    local curTime = math.clamp(g_Game.ServerTime:GetServerTimestampInSeconds(), startTime, endTime)
    return math.clamp01((curTime - startTime) / math.max(1, endTime - startTime))
end

function MapResourceFieldDatum:GetConfigCell()
    return ConfigRefer.FixedMapBuilding:Find(self.entity.Basic.ConfigId)
end

function MapResourceFieldDatum:IsWoods()
    local cfg = self:GetConfigCell()
    if cfg == nil then return false end

    return cfg:OutputType() == OutputResourceType.LoggingCamp
end

function MapResourceFieldDatum:IsStones()
    local cfg = self:GetConfigCell()
    if cfg == nil then return false end

    return cfg:OutputType() == OutputResourceType.StoneCamp
end

function MapResourceFieldDatum:IsFood()
    local cfg = self:GetConfigCell()
    if cfg == nil then return false end

    return cfg:OutputType() == OutputResourceType.Farm
end

function MapResourceFieldDatum:GetEntityId()
    return self.entity.Basic.EntityId
end

return MapResourceFieldDatum