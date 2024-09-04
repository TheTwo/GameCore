local ManulaResourceConst = require("ManualResourceConst")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")

local CityExplorerPetState = require("CityExplorerPetState")

---@class CityExplorerPetStateHideInBattle:CityExplorerPetState
---@field new fun(pet:CityUnitExplorerPet):CityExplorerPetStateHideInBattle
---@field super CityExplorerPetState
local CityExplorerPetStateHideInBattle = class("CityExplorerPetStateHideInBattle", CityExplorerPetState)

function CityExplorerPetStateHideInBattle:ctor(pet)
    CityExplorerPetStateHideInBattle.super.ctor(self, pet)
    self._normalExit = false
end

function CityExplorerPetStateHideInBattle:Enter()
    self._normalExit = false
    self._pet:ChangeAnimatorState("idle")
    self._delayHide = 1
    self._playerId = ModuleRefer.PlayerModule:GetPlayerId()
    self._seNpcConfigId = self._pet._seNpcConfigId
    self._pet:PlayEffect(ManulaResourceConst.vfx_w_jing_ling_qiu_catch2, self._delayHide)
    CityExplorerPetStateHideInBattle.super.Enter(self)
    g_Game.EventManager:AddListener(EventConst.SE_UNIT_PET_CREATE, Delegate.GetOrCreate(self, self.OnSePetCreate))
end

function CityExplorerPetStateHideInBattle:Exit()
    if not self._normalExit then
        self._pet:RemoveEffect(ManulaResourceConst.vfx_w_jing_ling_qiu_catch2)
        self._pet:SetIsHide(false)
    end
    g_Game.EventManager:RemoveListener(EventConst.SE_UNIT_PET_CREATE, Delegate.GetOrCreate(self, self.OnSePetCreate))
    self._pet:RemoveEffect(ManulaResourceConst.vfx_w_jing_ling_qiu_catch2)
    CityExplorerPetStateHideInBattle.super.Exit(self)
end

function CityExplorerPetStateHideInBattle:Tick(dt)
    if self:CheckTransState() then
        return
    end
    self:TickHideFadeIn(dt)
end

function CityExplorerPetStateHideInBattle:CheckTransState()
    if self._pet._needInBattleHide then
        return false
    end
    self._normalExit = true
    self.stateMachine:ChangeState("CityExplorerPetStateRecoverFromSeBattle")
    return true
end

function CityExplorerPetStateHideInBattle:TickHideFadeIn(dt)
    if not self._delayHide then return end
    self._delayHide = self._delayHide - dt
    if self._delayHide <= 0 then
        self._delayHide = nil
        self._pet:RemoveEffect(ManulaResourceConst.vfx_w_jing_ling_qiu_catch2)
        self._pet:SetIsHide(true)
    end
end

---@param unit SEPet
function CityExplorerPetStateHideInBattle:OnSePetCreate(unit)
    if not self._delayHide then return end
    if not unit then return end
    ---@type wds.SePet
    local entity = unit:GetEntity()
    if not entity then return end
    if entity.Owner.PlayerID ~=  self._playerId then return end
    if entity.BasicInfo.SeNpcId ~= self._seNpcConfigId then return end
    self._delayHide = 0
    self._pet:RemoveEffect(ManulaResourceConst.vfx_w_jing_ling_qiu_catch2)
    self:TickHideFadeIn(0)
end

return CityExplorerPetStateHideInBattle