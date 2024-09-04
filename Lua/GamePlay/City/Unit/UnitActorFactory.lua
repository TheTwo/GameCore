local UnitActorType = require("UnitActorType")
local CityUnitExplorer = require("CityUnitExplorer")
local CityUnitCitizen = require("CityUnitCitizen")
local CityUnitPet = require("CityUnitPet")
local CityUnitExplorerPet = require("CityUnitExplorerPet")

---@class UnitActorFactory
---@field new fun():UnitActorFactory
local UnitActorFactory = {}
UnitActorFactory._unitIndex = 1

---@return UnitActor
function UnitActorFactory.CreateOne(unitActorType)
    if unitActorType == UnitActorType.CITY_EXPLORER then
        local unitId = UnitActorFactory._unitIndex
        UnitActorFactory._unitIndex = UnitActorFactory._unitIndex + 1
        return CityUnitExplorer.new(unitId, unitActorType)
    elseif unitActorType == UnitActorType.CITY_CITIZEN then
        local unitId = UnitActorFactory._unitIndex
        UnitActorFactory._unitIndex = UnitActorFactory._unitIndex + 1
        return CityUnitCitizen.new(unitId, unitActorType)
    elseif unitActorType == UnitActorType.CITY_PET then
        local unitId = UnitActorFactory._unitIndex
        UnitActorFactory._unitIndex = UnitActorFactory._unitIndex + 1
        return CityUnitPet.new(unitId, unitActorType)
    elseif unitActorType == UnitActorType.CITY_SE_FOLLOW_HERO_PET then
        local unitId = UnitActorFactory._unitIndex
        UnitActorFactory._unitIndex = UnitActorFactory._unitIndex + 1
        return CityUnitExplorerPet.new(unitId, unitActorType)
    end
    return nil
end

return UnitActorFactory
