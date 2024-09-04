local ModuleRefer = require("ModuleRefer")
---@class TroopEditUnit
local TroopEditUnit = class ('TroopEditUnit')

function TroopEditUnit:ctor(id)
    self.id = id

    self.hp = 0
    self.hpMax = 0

    self.buffedHpMax = 0

    self.uiGo = nil

    self.initBuff = 0
    self.curBuff = 0
end

function TroopEditUnit:Release()
end

---@return number
function TroopEditUnit:GetId()
    return self.id
end

function TroopEditUnit:GetCfgId()
    return 0
end

---@return number
function TroopEditUnit:GetLevel()
    return 0
end

function TroopEditUnit:GetStars()
    return {}
end

function TroopEditUnit:GetAssociatedTagId()
    return 0
end

function TroopEditUnit:GetBattleStyleId()
    return 0
end

function TroopEditUnit:GetHp()
    local initHp = self.hp / (1 + self.initBuff)
    return initHp * (1 + self.curBuff)
end

function TroopEditUnit:GetMaxHp()
    local initHpMax = self.hpMax
    return initHpMax * (1 + self.curBuff)
end

function TroopEditUnit:GetHpPercent()
    return math.clamp01(self:GetHp() / self:GetMaxHp())
end

function TroopEditUnit:ApplyBuff(bonusPercent)
    self.curBuff = bonusPercent
end

function TroopEditUnit:SetInitBuff(value)
    self.initBuff = value
end

---@return number
function TroopEditUnit:GetPower()
    return 0
end

---@return boolean
function TroopEditUnit:IsInjured()
    return self:GetHp() <= (self:GetMaxHp() * ModuleRefer.SlgModule.battleMinHpPct)
end

function TroopEditUnit:SetUIGameObject(go)
    self.go = go
end

---@return CS.UnityEngine.GameObject
function TroopEditUnit:GetUIGameObject()
    return self.go
end

return TroopEditUnit