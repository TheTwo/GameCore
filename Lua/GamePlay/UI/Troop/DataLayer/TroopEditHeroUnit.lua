local TroopEditUnit = require("TroopEditUnit")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
---@class TroopEditHeroUnit : TroopEditUnit
local TroopEditHeroUnit = class('TroopEditHeroUnit', TroopEditUnit)

function TroopEditHeroUnit:ctor(id)
    TroopEditUnit.ctor(self, id)
    self.heroData = ModuleRefer.HeroModule:GetHeroByCfgId(id)

    self.hp = ModuleRefer.TroopModule:GetTroopHeroHp(id)
    self.hpMax = ModuleRefer.TroopModule:GetTroopHeroHPMax(id, 0)
end

function TroopEditHeroUnit:GetCfgId()
    return self.id
end

function TroopEditHeroUnit:GetLevel()
    return self.heroData.dbData.Level
end

---@return number
function TroopEditHeroUnit:GetStars()
    return self.heroData.dbData.StarLevel
end

function TroopEditHeroUnit:GetAssociatedTagId()
    local tagId = self.heroData.configCell:AssociatedTagInfo()
    return tagId
end

function TroopEditHeroUnit:GetBattleStyleId()
    return self.heroData.configCell:BattleType()
end

function TroopEditHeroUnit:GetPower()
    return ModuleRefer.HeroModule:CalcHeroPower(self.id)
end

return TroopEditHeroUnit
