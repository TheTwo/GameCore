local MapBuildingProvider = require("MapBuildingProvider")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local PlayerModule = require("PlayerModule")
local I18N = require("I18N")

---@class MapBuildingProviderCreepTumor : MapBuildingProvider
local MapBuildingProviderCreepTumor = class("MapBuildingProviderCreepTumor", MapBuildingProvider)

---@param entity wds.PlayerMapCreep
function MapBuildingProviderCreepTumor.GetName(entity)
    local config = ConfigRefer.SlgCreepTumor:Find(entity.CfgId)
    return I18N.Get(config:CenterName())
end

---@param entity wds.PlayerMapCreep
function MapBuildingProviderCreepTumor.GetLevel(entity)
    local config = ConfigRefer.SlgCreepTumor:Find(entity.CfgId)
    return config:Level()
end

return MapBuildingProviderCreepTumor