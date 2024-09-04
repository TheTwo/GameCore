
---@class CitySafeAreaWallBattleObject
---@field new fun(id:number):CitySafeAreaWallBattleObject
local CitySafeAreaWallBattleObject = sealedClass('CitySafeAreaWallBattleObject')

function CitySafeAreaWallBattleObject:ctor(id)
    self.id = id
    self.battleState = false
    self.hp = nil
    self._changeNotify = nil
    self.hpMax = nil
end

function CitySafeAreaWallBattleObject:SetBattleState(inBattle)
    if inBattle == self.battleState then
        return
    end
    self.battleState = inBattle
    self:Notify()
end

function CitySafeAreaWallBattleObject:SetAttackingState(inAttack, trans)
    --do nothing
end

---@param hp number
---@param hpMax NewChapterUIMediator
function CitySafeAreaWallBattleObject:UpdateHP(hp, hpMax)
    if hp == self.hp and self.hpMax == hpMax then
        return
    end
    self.hp = hp
    self.hpMax = hpMax
    self:Notify()
end

function CitySafeAreaWallBattleObject:RegChangeNotify(notify)
    self._changeNotify = notify
end

function CitySafeAreaWallBattleObject:ClearChangeNotify()
    self._changeNotify = nil
end

function CitySafeAreaWallBattleObject:Notify()
    if self._changeNotify then
        self._changeNotify()
    end
end

return CitySafeAreaWallBattleObject