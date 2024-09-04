local TroopEditSlot = require("TroopEditSlot")
local TroopEditHeroUnit = require("TroopEditHeroUnit")
local UITroopConst = require("UITroopConst")
---@class TroopEditHeroSlot : TroopEditSlot
local TroopEditHeroSlot = class('TroopEditHeroSlot', TroopEditSlot)

function TroopEditHeroSlot:AddUnit(id)
    if self.unit then
        self.unit:Release()
    end
    self.unit = TroopEditHeroUnit.new(id)
end

function TroopEditHeroSlot:GetType()
    return UITroopConst.TroopSlotType.Hero
end

return TroopEditHeroSlot