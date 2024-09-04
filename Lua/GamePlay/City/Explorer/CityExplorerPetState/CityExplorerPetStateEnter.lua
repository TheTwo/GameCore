
local CityExplorerPetState = require("CityExplorerPetState")

---@class CityExplorerPetStateEnter:CityExplorerPetState
---@field new fun(pet:CityUnitExplorerPet):CityExplorerPetStateEnter
---@field super CityExplorerPetState
local CityExplorerPetStateEnter = class("CityExplorerPetStateEnter", CityExplorerPetState)

function CityExplorerPetStateEnter:Enter()
    self._pet:ChangeAnimatorState("idle")
    CityExplorerPetStateEnter.super.Enter(self)
end

function CityExplorerPetStateEnter:Tick(dt)
    if self:CheckTransState() then
        return
    end
end

function CityExplorerPetStateEnter:CheckTransState()
    if self._pet._needInBattleHide then
        self.stateMachine:ChangeState("CityExplorerPetStateHideInBattle")
        return true
    elseif self._pet._needFollow then
        self.stateMachine:ChangeState("CityExplorerPetStateFollow")
        return true
    end
    return false
end

return CityExplorerPetStateEnter