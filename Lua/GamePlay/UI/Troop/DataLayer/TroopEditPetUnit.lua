local TroopEditUnit = require("TroopEditUnit")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
---@class TroopEditPetUnit : TroopEditUnit
local TroopEditPetUnit = class('TroopEditPetUnit', TroopEditUnit)

function TroopEditPetUnit:ctor(id)
    TroopEditUnit.ctor(self, id)
    self.petData = ModuleRefer.PetModule:GetPetByID(id)

    self.hp = ModuleRefer.TroopModule:GetTroopPetHp(id)
    self.hpMax = ModuleRefer.TroopModule:GetTroopPetHpMax(id, 0)
end

function TroopEditPetUnit:GetCfgId()
    return self.petData.ConfigId
end

function TroopEditPetUnit:GetLevel()
    return self.petData.Level
end

function TroopEditPetUnit:GetStars()
    ---@type PetStarLevelComponentParam
    local data = {}
    data.petId = self.id
    return data
end

function TroopEditPetUnit:GetAssociatedTagId()
    local petCfg = ConfigRefer.Pet:Find(self.petData.ConfigId)
    return petCfg:AssociatedTagInfo()
end

function TroopEditPetUnit:GetBattleStyleId()
    local petCfg = ConfigRefer.Pet:Find(self.petData.ConfigId)
    local petType = ConfigRefer.PetType:Find(petCfg:Type())
    return petType:BattleLabel()
end

function TroopEditPetUnit:GetPower()
    return ModuleRefer.PetModule:GetPetPower(self.id)
end

return TroopEditPetUnit