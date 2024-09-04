
local SEUnitType = require("SEUnitType")
local DBEntityType = require("DBEntityType")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")
local ConfigRefer = require("ConfigRefer")
local CityExplorerTeamDefine = require("CityExplorerTeamDefine")

local CityExplorerPetStateBase = require("CityExplorerPetStateBase")

---@class CityExplorerPetStateRecoverFromSeBattle:CityExplorerPetStateBase
---@field new fun(pet:CityUnitExplorerPet):CityExplorerPetStateRecoverFromSeBattle
---@field super CityExplorerPetStateBase
local CityExplorerPetStateRecoverFromSeBattle = class("CityExplorerPetStateRecoverFromSeBattle", CityExplorerPetStateBase)

function CityExplorerPetStateRecoverFromSeBattle:ctor(pet)
    CityExplorerPetStateRecoverFromSeBattle.super.ctor(self, pet)
    self._waitToDestoryCount = 0
    ---@type table<number, boolean>
    self._needAllSamePetToDestroyed = {}
    self._reShowPos = nil
    self._reShowForward = nil
    self._tickWaitInEffect = nil
end

function CityExplorerPetStateRecoverFromSeBattle:Enter()
    self._tickWaitInEffect = nil
    self._reShowPos = nil
    self._waitToDestoryCount = 0
    local env = self._pet._seMgr._seEnvironment
    if not env then
        self:ExitToIdleWithOutEffect()
        return
    end
    local unitMgr = env:GetUnitManager()
    if not unitMgr then
        self:ExitToIdleWithOutEffect()
        return
    end
    local seNpcConfigId = self._pet._seNpcConfigId
    local linkHeroId = self._pet._linkHeroId
    ---@type wds.Hero
    local heroEntity = g_Game.DatabaseManager:GetEntity(linkHeroId, DBEntityType.Hero)
    if not heroEntity then
        self:ExitToIdleWithOutEffect()
        return
    end
    table.clear(self._needAllSamePetToDestroyed)
    ---@type table<number, SEPet>
    local allPets = unitMgr:GetUnitTypes(SEUnitType.Pet) or {}
    for _, value in pairs(allPets) do
        local petEntity = value:GetEntity()
        if petEntity.Owner.PlayerID == heroEntity.Owner.PlayerID then
            if petEntity.BasicInfo.SeNpcId == seNpcConfigId then
                self._needAllSamePetToDestroyed[value:GetID()] = true
                self._waitToDestoryCount = self._waitToDestoryCount + 1
            end
        end
    end
    if self._waitToDestoryCount <= 0 then
        self:ExitToIdleWithOutEffect()
        return
    end
    g_Game.EventManager:AddListener(EventConst.SE_UNIT_PET_DESTORY, Delegate.GetOrCreate(self, self.OnUnitPetDestroy))
end

function CityExplorerPetStateRecoverFromSeBattle:Tick(dt)
    if not self._tickWaitInEffect then return end
    self._tickWaitInEffect = self._tickWaitInEffect - dt
    if self._tickWaitInEffect > 0 then return end
    self._tickWaitInEffect = nil
    self:ExitToIdle()
end

function CityExplorerPetStateRecoverFromSeBattle:Exit()
    self._tickWaitInEffect = nil
    g_Game.EventManager:RemoveListener(EventConst.SE_UNIT_PET_DESTORY, Delegate.GetOrCreate(self, self.OnUnitPetDestroy))
    if self._reShowPos then
        local dir = self._reShowForward and CS.UnityEngine.Quaternion.LookRotation(self._reShowForward)
        self._pet:StopMove(self._reShowPos, dir)
        self._pet:Tick(0)
    end
    self._pet:SetIsHide(false)
    self._pet:RemoveEffect(ManualResourceConst.vfx_w_jing_ling_qiu_out)
    self._pet:ClearUpOldAttachMaterial()
    self._pet:PlayBornEffect()
end

function CityExplorerPetStateRecoverFromSeBattle:ExitToIdleWithOutEffect()
    self._tickWaitInEffect = 1
    self._pet:SetIsHide(true)
    self._pet:PlayEffect(ManualResourceConst.vfx_w_jing_ling_qiu_out, self._tickWaitInEffect, true)
    self:CheckNeedChangePos()
    if self._reShowPos then
        local dir = self._reShowForward and CS.UnityEngine.Quaternion.LookRotation(self._reShowForward)
        self._pet:StopMove(self._reShowPos, dir)
        self._pet:Tick(0)
    else
        self._pet:StopMove()
        self._pet:Tick(0)
    end
end

---@param actorPos CS.UnityEngine.Vector3
---@param forward CS.UnityEngine.Vector3
function CityExplorerPetStateRecoverFromSeBattle:OnUnitPetDestroy(unitId, actorPos, forward)
    if not self._needAllSamePetToDestroyed[unitId] then return end
    self._needAllSamePetToDestroyed[unitId] = nil
    self._waitToDestoryCount = self._waitToDestoryCount - 1
    if self._waitToDestoryCount == 0 then
        self._reShowPos = actorPos
        self._reShowForward = forward
        if not self._tickWaitInEffect then
            self:ExitToIdle()
        end
    end
end

function CityExplorerPetStateRecoverFromSeBattle:CheckNeedChangePos()
    local env = self._pet._seMgr._seEnvironment
    if not env then return end
    local unitMgr = env:GetUnitManager()
    if not unitMgr then return end
    ---@type SEHero
    local hero = unitMgr:GetUnit(self._pet._linkHeroId)
    if not hero then
        return
    end
    local selfAgent= self._pet._moveAgent
    local pos = selfAgent._currentPosition
    ---hero go 异步创建 可能有一帧取不到位置 取不到就不计算
    local heroPos = hero:GetActor():GetPosition()
    if not heroPos then return end
    local allowDistance = ConfigRefer.CityConfig:CitySePetFollowDistance()
    local needChangePos = false
    if not pos then
        needChangePos = true
    else
        local offset = heroPos - pos
        local distance = offset.magnitude
        if distance > allowDistance then
            needChangePos = true
        end
    end
    if not needChangePos then return end
    local cityPathfinding = self._pet._seMgr.city.cityPathFinding
    local locomotion = hero:GetLocomotion()
    local forward = locomotion:GetForward()
    local dir = CS.UnityEngine.Quaternion.LookRotation(forward)
    local targetPos = CityExplorerTeamDefine.CalculatePetFollowUnitPosition(heroPos, dir, ConfigRefer.CityConfig.CitySePetFollowDistance and ConfigRefer.CityConfig:CitySePetFollowDistance())
    targetPos = cityPathfinding:NearestWalkableOnGraph(targetPos, cityPathfinding.AreaMask.CityGround)
    self._reShowPos = targetPos
    self._reShowForward = forward
end

return CityExplorerPetStateRecoverFromSeBattle