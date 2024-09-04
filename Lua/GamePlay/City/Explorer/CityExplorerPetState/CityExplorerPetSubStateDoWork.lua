local CastleStartWorkParameter = require("CastleStartWorkParameter")
local CastleStopCollectParameter = require("CastleStopCollectParameter")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

local CityExplorerPetStateBase = require("CityExplorerPetStateBase")

---@class CityExplorerPetSubStateDoWork:CityExplorerPetStateBase
---@field new fun(pet:CityUnitExplorerPet, host:CityExplorerPetStateCollect):CityExplorerPetSubStateDoWork
---@field super CityExplorerPetStateBase
local CityExplorerPetSubStateDoWork = class("CityExplorerPetSubStateDoWork", CityExplorerPetStateBase)

function CityExplorerPetSubStateDoWork:ctor(pet, host)
    CityExplorerPetSubStateDoWork.super.ctor(self, pet)
    ---@type CityExplorerPetStateCollect
    self._host = host
    self._requestIndex = 0
    self._exitNeedCancel = true
    self._cityUid = nil
    self._workAniTick = nil
end

function CityExplorerPetSubStateDoWork:Enter()
    self._elementId = self.stateMachine:ReadBlackboard("ElementId")
    ---@type CityElementResource
    local element = self._pet._seMgr.city.elementManager:GetElementById(self._elementId)
    local elementConfig = element.resourceConfigCell
    local city = self._pet._seMgr.city
    self._cityUid = city.uid
    local sendCmd = CastleStartWorkParameter.new()
    sendCmd.args.WorkCfgId = elementConfig:CollectWork()
    sendCmd.args.WorkTarget = self._elementId
    sendCmd.args.WorkerIds:Add(self._pet.petId)
    sendCmd.args.Count = 1
    sendCmd.args.IsSeMode = true
    self._requestIndex = self._requestIndex + 1
    local index = self._requestIndex
    self._exitNeedCancel = true
    sendCmd:SendOnceCallback(nil, nil, nil, function(_, isSuccess, _)
        if self._requestIndex ~= index then
            return
        end
        if not isSuccess then
            self._exitNeedCancel = false
            self._host:ExitToNormal()
        end
    end)
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_INPROGRESS_RESOURCE_REMOVED, Delegate.GetOrCreate(self, self.OnCastleInProgressResourceRemoved))
    self._pet:ChangeAnimatorState("attack01")
end

function CityExplorerPetSubStateDoWork:Exit()
    self._pet:ChangeAnimatorState("idle")
    local elementId = self._elementId
    self._elementId = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_INPROGRESS_RESOURCE_REMOVED, Delegate.GetOrCreate(self, self.OnCastleInProgressResourceRemoved))
    if self._exitNeedCancel and elementId then
        self._exitNeedCancel = false
        local sendCmd = CastleStopCollectParameter.new()
        sendCmd.args.TargetId = elementId
        sendCmd:Send()
    end
end

function CityExplorerPetSubStateDoWork:OnCastleInProgressResourceRemoved(cityUid, elementId)
    if not self._cityUid or self._cityUid ~= cityUid then return end
    if not self._elementId or self._elementId ~= elementId then return end
    self._elementId = nil
    self._host:ExitToNormal()
end

function CityExplorerPetSubStateDoWork:Tick(dt)
    local petWorkLoopTime, loop = self._pet:GetCurrentAnimationNormalizedTime()
    if petWorkLoopTime >= 1.0 and not loop then
        if not self._workAniTick then
            self._workAniTick = 0.1
        end
        self._workAniTick = self._workAniTick - dt
        if self._workAniTick <= 0 then
            self._workAniTick = nil
            self._pet:RestartCurrentAnimation()
        end
    end
end

return CityExplorerPetSubStateDoWork