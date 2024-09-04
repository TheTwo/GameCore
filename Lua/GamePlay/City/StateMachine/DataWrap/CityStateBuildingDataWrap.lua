---@class CityStateBuildingDataWrap
---@field new fun():CityStateBuildingDataWrap
---@field city City
local CityStateBuildingDataWrap = class("CityStateBuildingDataWrap")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

---@param cfg CityFurnitureLevelConfigCell
function CityStateBuildingDataWrap.FromFurnitureLevelCfg(city, cfg)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(cfg:Type())
    local inst = CityStateBuildingDataWrap.new(city)
    local name = I18N.Get(typCfg:Name())
    inst.isFurniture = true
    inst.lvCfg = cfg
    inst.cfgId = cfg:Id()
    inst.typCfg = typCfg
    inst.name = name
    return inst
end

---@param cfg BuildingLevelConfigCell
function CityStateBuildingDataWrap.FromBuildingLevelCfg(city, cfg)
    local typCfg = ConfigRefer.BuildingTypes:Find(cfg:Type())
    local inst = CityStateBuildingDataWrap.new(city)
    local name = I18N.Get(typCfg:Name())
    inst.isFurniture = false
    inst.lvCfg = cfg
    inst.cfgId = cfg:Id()
    inst.typCfg = typCfg
    inst.name = name
    return inst
end

function CityStateBuildingDataWrap:ctor(city)
    self.city = city
    self.isFurniture = false
    self.lvCfg = nil
    self.typCfg = nil
    self.name = nil
end

function CityStateBuildingDataWrap:RequestServer(x, y, direction, lockable)
    if self.isFurniture then
        self.city.furnitureManager:RequestPlaceFurniture(self.cfgId, x, y, direction, lockable)
    end
end

return CityStateBuildingDataWrap