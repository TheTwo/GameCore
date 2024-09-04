local MapBuildingProvider = require("MapBuildingProvider")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local PlayerModule = require("PlayerModule")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")

---@class MapBuildingProviderResourceField : MapBuildingProvider
local MapBuildingProviderResourceField = class("MapBuildingProviderResourceField", MapBuildingProvider)

---@param entity wds.ResourceField
function MapBuildingProviderResourceField.GetName(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
    return I18N.Get(config:Name())
end

---@param entity wds.ResourceField
function MapBuildingProviderResourceField.GetLevel(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
    return config:Level()
end

---@param entity wds.ResourceField
function MapBuildingProviderResourceField.GetBuildingImage(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
    return config and config:Image() or string.Empty
end

---@param entity wds.ResourceField
function MapBuildingProviderResourceField.GetIcon(entity, lod)
    local cfg = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
    local owner = entity.Owner
    local iconWrap = ModuleRefer.MapResourceFieldModule:GetLod2IconGroup(cfg:OutputType())
    local icon
    if iconWrap ~= nil then
        if ModuleRefer.PlayerModule:IsEmpty(owner) then
            icon = ArtResourceUtils.GetUIItem(iconWrap:IconEmpty())
        elseif ModuleRefer.PlayerModule:IsMine(owner) then
            icon = ArtResourceUtils.GetUIItem(iconWrap:IconMine())
        elseif ModuleRefer.PlayerModule:IsFriendly(owner) then
            icon = ArtResourceUtils.GetUIItem(iconWrap:IconAlly())
        else
            icon = ArtResourceUtils.GetUIItem(iconWrap:IconEnemy())
        end
    else
        icon = "sp_icon_missing_2"
    end
    return icon
end

return MapBuildingProviderResourceField