local ConfigRefer = require("ConfigRefer")

local CitySeExplorerPetsLogicDefine = require("CitySeExplorerPetsLogicDefine")

---@class CitySeExplorerPetsLogic
---@field new fun(mgr:CitySeManager, preset:number):CitySeExplorerPetsLogic
local CitySeExplorerPetsLogic = sealedClass("CitySeExplorerPetsLogic")

---@param mgr CitySeManager
function CitySeExplorerPetsLogic:ctor(mgr, preset)
    self._mgr = mgr
    ---@type table<CityUnitExplorerPet, CityUnitExplorerPet>
    self._units = {}
    ---@type table<CityUnitExplorerPet, number>
    self._workMap = {}
    self._unitCount = 0
    self._presetIndex = preset
    self._enterCollectDistance = ConfigRefer.CityConfig:CitySePetCollectTriggerDistance()
    self._exitCollectDistance = ConfigRefer.CityConfig:CitySePetCollectMaxDistance()
end

---@param unit CityUnitExplorerPet
function CitySeExplorerPetsLogic:AddPet(unit)
    if not unit or self._units[unit] then return end
    self._units[unit] = unit
    self._unitCount = self._unitCount + 1
    unit:SetGroupLogic(self)
end

---@param unit CityUnitExplorerPet
---@return boolean @true for emepty after remove
function CitySeExplorerPetsLogic:RemovePet(unit)
    if not unit or not self._units[unit] then return self._unitCount == 0 end
    unit:SetGroupLogic(nil)
    self._units[unit] = nil
    self._unitCount = self._unitCount - 1
    self._workMap[unit] = nil
    return self._unitCount == 0
end

function CitySeExplorerPetsLogic:GetSeExplorerCollectResource()
    if self._unitCount <= 0 then return false, 0 end
    for _, targetId in pairs(self._workMap) do
        if targetId ~= 0 then
            return true, targetId
        end
    end
    return false, 0
end

function CitySeExplorerPetsLogic:HasNoWorkPet()
    if self._unitCount <= 0 then return false end
    for _, targetId in pairs(self._workMap) do
        if targetId == 0 then
            return true
        end
    end
    return true
end

---@return CitySeExplorerPetsLogicDefine.SetWorkResult, number|nil
function CitySeExplorerPetsLogic:SetSeExplorerCollectResource(tileId)
    if self._unitCount <= 0 then return false end
    for _, targetId in pairs(self._workMap) do
        if targetId == tileId then
            return CitySeExplorerPetsLogicDefine.SetWorkResult.SuccessAlreadySet
        end
    end
    local petMgr = self._mgr.city.petManager
    local hasMatchTypeWorker = false
    ---@type table<CityUnitExplorerPet, number>
    local workTypeMatchUnit = {}
    for _, unit in pairs(self._units) do
        if not unit:IsInBattleState() and not unit:InCollectActionCD() and petMgr:IsResourceCanClaimByPet(unit.petId, tileId) then
            hasMatchTypeWorker = true
            workTypeMatchUnit[unit] = self._workMap[unit] or 0
        end
    end
    if not hasMatchTypeWorker then
        return CitySeExplorerPetsLogicDefine.SetWorkResult.NoWorkTypeWorker
    end
    local firstNotFreePetId = nil
    for unit, targetId in pairs(workTypeMatchUnit) do
        if targetId == 0 then
            unit._stateMachine:WriteBlackboard("CollectResource", tileId)
            unit._stateMachine:ChangeState("CityExplorerPetStateCollect")
            return CitySeExplorerPetsLogicDefine.SetWorkResult.Success
        elseif not firstNotFreePetId then
            firstNotFreePetId = unit.petId
        end
    end
    return CitySeExplorerPetsLogicDefine.SetWorkResult.NoFreeWorkTypeWorer, firstNotFreePetId
end

function CitySeExplorerPetsLogic:UnitAssignWork(unit, tileId)
    self._workMap[unit] = tileId
end

---@param unit CityUnitExplorerPet
function CitySeExplorerPetsLogic:ClearUnitWork(unit)
    self._workMap[unit] = nil
end

function CitySeExplorerPetsLogic:Tick(dt, nowTime)
    if self._unitCount <= 0 then return end
    local team = self._mgr.city.cityExplorerManager:GetTeamByPresetIndex(self._presetIndex)
    if not team then return end
    local teamPos = team:GetPosition()
    if not teamPos then return end
    local isInExplore = team:InExplore()
    if not isInExplore then return end
    local inBattle = team:IsInBattle()
    if inBattle then return end
    if not self:HasNoWorkPet() then return end
    local workTargetToSelect = self._mgr.city.elementManager:FindResInRangeByCenter(teamPos, self._enterCollectDistance, self._exitCollectDistance)
    if #workTargetToSelect <= 0 then return end
    for _, value in ipairs(workTargetToSelect) do
        self:SetSeExplorerCollectResource(value.tileId)
        if not self:HasNoWorkPet() then break end
    end
end

return CitySeExplorerPetsLogic