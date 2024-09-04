local TroopEditSlot = require("TroopEditSlot")
local TroopEditPetUnit = require("TroopEditPetUnit")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UITroopConst = require("UITroopConst")
local ConfigRefer = require("ConfigRefer")
---@class TroopEditPetSlot : TroopEditSlot
local TroopEditPetSlot = class('TroopEditPetSlot', TroopEditSlot)

local PresetIndex2FlagType = {
    1001301,
    1001701,
    1002101
}

function TroopEditPetSlot:AddUnit(id)
    if self.unit then
        self.unit:Release()
    end
    self.unit = TroopEditPetUnit.new(id)
end

function TroopEditPetSlot:IsLocked()
    return self.index > ModuleRefer.TroopModule:GetTroopPetSlotCount(self.presetIndex)
end

function TroopEditPetSlot:GetUnlockCondStr()
    local city = ModuleRefer.CityModule:GetMyCity()
    local flagType = PresetIndex2FlagType[self.presetIndex]
    ---@type CityFurniture
    local furniture = city.furnitureManager:GetFurnitureByTypeCfgId(flagType)
    return I18N.GetWithParams("toast_unlock_team_animal_slot", furniture:GetName(), ConfigRefer.CityConfig:TroopPetSlotUnlockFlagLevel())
end

function TroopEditPetSlot:GetType()
    return UITroopConst.TroopSlotType.Pet
end

return TroopEditPetSlot