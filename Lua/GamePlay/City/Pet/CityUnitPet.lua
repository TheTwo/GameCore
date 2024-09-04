local CityUnitPathLine = require("CityUnitPathLine")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local StateMachine = require("StateMachine")
local CityUnitMoveGridEventProvider = require("CityUnitMoveGridEventProvider")
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local UnitMoveAgent = require("UnitMoveAgent")
local Utils = require("Utils")
local CityPathFinding = require("CityPathFinding")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local CityPetStatusHandle = require("CityPetStatusHandle")
local EventConst = require("EventConst")

local CityUnitPetStateIdle = require("CityUnitPetStateIdle")
local CityUnitPetStateMoving = require("CityUnitPetStateMoving")
local CityUnitPetStateWorking = require("CityUnitPetStateWorking")
local CityUnitPetStateWalking = require("CityUnitPetStateWalking")
local CityUnitPetStateSleeping = require("CityUnitPetStateSleeping")
local CityUnitPetStateEating = require("CityUnitPetStateEating")
local CityUnitPetStateBathing = require("CityUnitPetStateBathing")
local CityUnitPetStateExhausted = require("CityUnitPetStateExhausted")
local CityUnitPetStateCarrying = require("CityUnitPetStateCarrying")
local CityUnitPetStateBuildMaster = require("CityUnitPetStateBuildMaster")

local CityUnitPetSubStateAction = require("CityUnitPetSubStateAction")
local CityUnitPetSubStateActionLoop = require("CityUnitPetSubStateActionLoop")
local CityUnitPetSubStateMoving = require("CityUnitPetSubStateMoving")

local CityUnitActor = require("CityUnitActor")
---@class CityUnitPet:CityUnitActor
---@field new fun():CityUnitPet
local CityUnitPet = class("CityUnitPet", CityUnitActor)
local CarryingPrefabCreateDelay = 0.15
CityUnitPet.PathLineColor = CS.UnityEngine.Color(0, 0.5, 0.5, 1)

function CityUnitPet:ctor(id, actorType)
    CityUnitActor.ctor(self, id, actorType)
    ---@type CityUnitPathLine
    self.wayPointsLine = nil
    ---@type StateMachine
    self.stateMachine = StateMachine.new()
    self.stateMachine.allowReEnter = true
    ---@type StateMachine
    self.subStateMachine = StateMachine.new()
    self.subStateMachine.allowReEnter = true
    ---@type CS.UnityEngine.Vector3
    self.targetPos = CS.UnityEngine.Vector3.zero
    self.targetRotation = CS.UnityEngine.Quaternion.identity
    self.animSpeed = 1
    self.disposed = false
    self.pathFindingIndex = 0
    ---@type table<number, CS.DragonReborn.AssetTool.PooledGameObjectHandle>
    self.attachGo = {}
    ---@type table<number, CS.DragonReborn.AssetTool.PooledGameObjectHandle>
    self.carryAttachGo = {}
    ---@type {prefabName:string, parent:CS.UnityEngine.Transform, delay:number}[]
    self.delayCarrySpawnQueue = {}
    self.findPathMask = CityPathFinding.AreaMask.CityAllWalkable
    ---@type table<CS.DragonReborn.VisualEffect.VisualEffectHandle, boolean>
    self.carryVfxHandles = {}
end

---@param petData CityPetDatum
---@param creator CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@param moveAgent UnitMoveAgent
---@param config UnitActorConfigWrapper
---@param pathFinder CityPathFinding
---@param pathHeightFixer fun(pos:CS.UnityEngine.Vector3):CS.UnityEngine.Vector3
function CityUnitPet:Init(petData, creator, moveAgent, config, pathFinder, pathHeightFixer)
    CityUnitActor.Init(self, petData:GetAssetPath(), creator, moveAgent, config, pathFinder, pathHeightFixer)
    self.petData = petData
    self:InitStateMachine()
    self:InitStatusHandle()
end

function CityUnitPet:Dispose()
    self:ReleaseFromBuildMaster()
    self:ChangeAnimatorState(CityPetAnimStateDefine.Idle)
    self:UnloadAllPrefabLoader()
    self:OnSubStateChanged()
    self:RemovePathLine()
    self:UnloadZZZEffect()
    self:DestroyCarryItemGo()
    self:DisposeStatusHandle()
    self:DetachMoveGridListener()
    self:ReleaseAllAttachedModel()
    self:ReleaseStateMachine()
    self._animatorId = nil
    self.disposed = true
    self._attachPointHolder = nil
    self._syncPos = nil
    if self.trigger ~= nil then
        self.trigger:SetOnTrigger(nil)
    end
    self.trigger = nil
    CityUnitActor.Dispose(self)
end

function CityUnitPet:Tick(delta)
    CityUnitActor.Tick(self, delta)
    self.stateMachine:Tick(delta)
    self.subStateMachine:Tick(delta)

    if self.wayPointsLine then
        self.wayPointsLine:UpdateByMoveAgent(self._moveAgent)
    end

    if self._moveGridHandle then
        local x, y = self.petData.manager.city:GetCoordFromPosition(self._moveAgent._currentPosition)
        self._moveGridHandle:refreshPos(x, y)
    end

    if self.dramaHandle then
        self.dramaHandle:Tick(delta)
    end

    if self.statusHandle then
        self.statusHandle:Tick(delta)
    end

    self:TickForSpawnCarryItemGo(delta)
end

function CityUnitPet:InitStateMachine()
    self.subStateMachine:AddState("CityUnitPetSubStateAction", CityUnitPetSubStateAction.new(self))
    self.subStateMachine:AddState("CityUnitPetSubStateActionLoop", CityUnitPetSubStateActionLoop.new(self))
    self.subStateMachine:AddState("CityUnitPetSubStateMoving", CityUnitPetSubStateMoving.new(self))
    self.subStateMachine:AddStateChangedListener(Delegate.GetOrCreate(self, self.OnSubStateChanged))

    self.stateMachine:AddState("CityUnitPetStateIdle", CityUnitPetStateIdle.new(self))
    self.stateMachine:AddState("CityUnitPetStateMoving", CityUnitPetStateMoving.new(self))
    self.stateMachine:AddState("CityUnitPetStateWorking", CityUnitPetStateWorking.new(self))
    self.stateMachine:AddState("CityUnitPetStateWalking", CityUnitPetStateWalking.new(self))
    self.stateMachine:AddState("CityUnitPetStateSleeping", CityUnitPetStateSleeping.new(self))
    self.stateMachine:AddState("CityUnitPetStateEating", CityUnitPetStateEating.new(self))
    self.stateMachine:AddState("CityUnitPetStateBathing", CityUnitPetStateBathing.new(self))
    self.stateMachine:AddState("CityUnitPetStateExhausted", CityUnitPetStateExhausted.new(self))
    self.stateMachine:AddState("CityUnitPetStateCarrying", CityUnitPetStateCarrying.new(self))
    self.stateMachine:AddState("CityUnitPetStateBuildMaster", CityUnitPetStateBuildMaster.new(self))
    self.stateMachine:AddStateChangedListener(Delegate.GetOrCreate(self, self.OnMainStateChanged))
    self.stateMachine:ChangeState("CityUnitPetStateIdle")

    self.statusMapToName = {}
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusNone] = "CityUnitPetStateIdle"
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusMoving] = "CityUnitPetStateMoving"
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusWorking] = "CityUnitPetStateWorking"
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusWalking] = "CityUnitPetStateWalking"
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusSleeping] = "CityUnitPetStateSleeping"
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusEating] = "CityUnitPetStateEating"
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusBath] = "CityUnitPetStateBathing"
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusExhausted] = "CityUnitPetStateExhausted"
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusCarrying] = "CityUnitPetStateCarrying"
    self.statusMapToName[wds.CastlePetStatus.CastlePetStatusBuilding] = "CityUnitPetStateBuildMaster"
end

function CityUnitPet:ReleaseStateMachine()
    self.stateMachine:ClearAllStates()
    self.stateMachine:ClearStateChangeListener()
    self.subStateMachine:ClearAllStates()
    self.subStateMachine:ClearStateChangeListener()
    self.stateMachine = nil
    self.subStateMachine = nil
end

function CityUnitPet:InitStatusHandle()
    self.statusHandle = CityPetStatusHandle.new(self)
    self.statusHandle:LoadModel()
end

function CityUnitPet:DisposeStatusHandle()
    if self.statusHandle then
        self.statusHandle:Dispose()
        self.statusHandle = nil
    end
end

function CityUnitPet:UpdateStatusHandle()
    if self.statusHandle then
        self.statusHandle:Update()
    end
end

function CityUnitPet:UpdateName()
    if self.statusHandle then
        self.statusHandle:UpdateName()
    end
end

---@param provider CityUnitMoveGridEventProvider
function CityUnitPet:AttachMoveGridListener(provider)
    self:DetachMoveGridListener()
    local x, y = self.petData.manager.city:GetCoordFromPosition(self._moveAgent._currentPosition)
    self._moveGridHandle = provider:AddUnit(x, y, CityUnitMoveGridEventProvider.UnitType.Citizen)
end

function CityUnitPet:DetachMoveGridListener()
    if self._moveGridHandle then
        self._moveGridHandle:dispose()
    end
    self._moveGridHandle = nil
end

function CityUnitPet:ShowPathLine(wayPoints, currentPoint)
    if self.disposed then
        return
    end
    if not wayPoints then
        return
    end
    if not self.wayPointsLine then
        self.wayPointsLine = CityUnitPathLine.GetOrCreate(self._pathFinder.city.CityWorkerRoot, ArtResourceUtils.GetItem(ArtResourceConsts.effect_city_explorer_pathline))
    end
    self.wayPointsLine:SetLineColor(CityUnitPet.PathLineColor)
    self.wayPointsLine:InitWayPoints(wayPoints, currentPoint)
end

function CityUnitPet:RemovePathLine()
    if self.wayPointsLine then
        CityUnitPathLine.Delete(self.wayPointsLine)
    end
    self.wayPointsLine = nil
end

---@protected
---@param model UnitModel
function CityUnitPet:WhenModelReady(model)
    CityUnitActor.WhenModelReady(self, model)

    if not self.model:IsReady() then return end
    self.model:SetScale(self.petData:GetModelScale())
    self.model:SetGoLayer("City")
    local agent = self._moveAgent
    local displayPos = self.petData.manager.city:FixHeightWorldPosition(agent._currentPosition)
    self.model:SetWorldPositionAndDir(displayPos, agent._currentDirectionNoPitch)

    if self._animatorCount <= 1 then
        if Utils.IsNotNull(self._animator) then
            self._animator:CrossFade(self._state, 0)
        end
    else
        for i, animator in ipairs(self._animators) do
            if Utils.IsNotNull(animator) then
                animator:CrossFade(self._state, 0)
            end
        end
    end

    ---@type CS.PosSyncController
    self._syncPos = self.model._go:GetComponentInChildren(typeof(CS.PosSyncController))
    if Utils.IsNull(self._syncPos) then
        self._syncPos = self.model._go:AddComponent(typeof(CS.PosSyncController))
    end
    ---@type CS.FXAttachPointHolder
    self._attachPointHolder = self.model._go:GetComponentInChildren(typeof(CS.FXAttachPointHolder))
    if self.stateMachine and self.stateMachine.currentState then
        self.stateMachine.currentState:OnModelReady()
    end

    local behaviour = self.model._go:GetLuaBehaviourInChildren("CityTrigger")
    if Utils.IsNotNull(behaviour) then
        ---@type CityTrigger
        self.trigger = behaviour.Instance
        self.trigger:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickPet))
    end
end

function CityUnitPet:SyncFromServer()
    if self.disposed then
        return
    end
    
    local stateName = self.statusMapToName[self.petData:GetStatus()]
    if string.IsNullOrEmpty(stateName) then
        stateName = "CityUnitPetStateIdle"
    end

    if self.petData:IsCurrentActionValid() then
        self.stateMachine:ChangeState(stateName)
    else
        self.stateMachine:ChangeState("CityUnitPetStateIdle")
    end
end

---@param targetPos CS.UnityEngine.Vector3
---@param run boolean
---@param startCallBack fun(p:CS.UnityEngine.Vector3[], agent:UnitMoveAgent)
---@param showPathLine boolean
function CityUnitPet:MoveToTargetPos(targetPos, targetRot, startCallBack, showPathLine)
    local oldHandle = self.pathFindingHandle
    self.pathFindingIndex = self.pathFindingIndex + 1
    local expectedIdx = self.pathFindingIndex
    self.pathFindingHandle = self._pathFinder:FindPath(self._moveAgent._currentPosition, targetPos, self.findPathMask, function(p)
        if self.pathFindingIndex ~= expectedIdx then
            return
        end
        self:ReleasePathFindingHandle()
        if not p or #p <= 1 then
            self:StopMove(targetPos, targetRot)
        else
            if self.dramaHandle ~= nil then
                local runSpeed, walkSpeed = self._config:RunSpeed(), self._config:WalkSpeed()
                local runTime, walkTime = self:GetPathCostTime(p, runSpeed, walkSpeed)
                local useWalk, suggestTime = self.dramaHandle:HasSuggestMoveRemainTime(runTime, walkTime, targetPos, runSpeed, walkSpeed)
                local remainTime = 0
                if useWalk then
                    remainTime = suggestTime
                else
                    remainTime = (targetPos - self._moveAgent._currentPosition).magnitude / runSpeed
                end
                local speedMulti = useWalk and math.max(walkTime / remainTime) or math.max(runTime / remainTime)
                self:MoveUseWaypoints(p, not useWalk, speedMulti, startCallBack, showPathLine)
            elseif self.petData:IsStrictMoving() then
                local runSpeed, walkSpeed = self._config:RunSpeed(), self._config:WalkSpeed()
                local runTime, walkTime = self:GetPathCostTime(p, runSpeed, walkSpeed)
                local remainTime = self.petData:GetCurrentActionMovingTime()
                if remainTime == 0 then
                    self:StopMove(targetPos, targetRot)
                else
                    local isRun = math.abs(runTime - remainTime) < math.abs(walkTime - remainTime) * (runSpeed / math.divprotect(walkSpeed))
                    local speedMulti = isRun and math.max(runTime / remainTime) or math.max(walkTime / remainTime)
                    self:MoveUseWaypoints(p, isRun, speedMulti, startCallBack, showPathLine)
                end
            else
                self:MoveUseWaypoints(p, false, 1, startCallBack, showPathLine)
            end
        end
    end)
    if oldHandle then
        oldHandle:Release()
    end
end

function CityUnitPet:IsFindingPath()
    return self.pathFindingHandle ~= nil
end

---@protected
function CityUnitPet:MoveUseWaypoints(wayPoints, isRun, speedMulti, startCallBack, showPathLine)
    if showPathLine then
        self:ShowPathLine(wayPoints, self._moveAgent._currentPosition)
    end

    self._moveAgent:StopMove(self._moveAgent._currentPosition)
    self.animSpeed = speedMulti
    self.isRun = isRun
    if isRun then
        self._moveAgent._speed = self._config:RunSpeed() * speedMulti
    else
        self._moveAgent._speed = self._config:WalkSpeed() * speedMulti
    end

    self._moveAgent:BeginMove(wayPoints)
    if startCallBack then
        startCallBack(wayPoints, self._moveAgent)
    end
end

function CityUnitPet:StopMove(targetPos, dir)
    local pos = targetPos or self._moveAgent._currentPosition
    local dir = dir or self._moveAgent._currentDirectionNoPitch
    self._moveAgent:StopMove(pos, dir)
    self.animSpeed = 1
end

---@param wayPoints CS.UnityEngine.Vector3[]
---@param runSpeed number
---@param walkSpeed number
---@return number
function CityUnitPet:GetPathCostTime(wayPoints, runSpeed, walkSpeed)
    local runCost = self._moveAgent:PredictTime(wayPoints, runSpeed)
    local walkSpeed = self._moveAgent:PredictTime(wayPoints, walkSpeed)
    return runCost, walkSpeed
end

function CityUnitPet:ReleasePathFindingHandle()
    if self.pathFindingHandle then
        self.pathFindingHandle:Release()
        self.pathFindingHandle = nil
    end
end

function CityUnitPet:SyncAnimatorSpeed()
    if self._animatorCount <= 1 then
        if Utils.IsNull(self._animator) then return end
        self._animator.speed = self.animSpeed
    else
        for i, animator in ipairs(self._animators) do
            if Utils.IsNotNull(animator) then
                animator.speed = self.animSpeed
            end
        end
    end
end

function CityUnitPet:SetFindPathMask(mask)
    self.findPathMask = mask or CityPathFinding.AreaMask.CityAllWalkable
end

function CityUnitPet:PickRandomTargetPosForWalk()
    self.targetPos = self._pathFinder:RandomPositionInExploredZoneWithInSafeArea(self._pathFinder.AreaMask.CityGround)
    return self.targetPos
end

function CityUnitPet:PlayMove()
    if self.dramaHandle ~= nil then
        self.targetPos, self.targetRotation = self.dramaHandle:GetTargetPositionWithPetCenterFix()
    elseif self.petData:IsBuildMaster() then
        self.targetPos, self.targetRotation = self:GetBelongsToBuildMasterInfo():GetTargetPosition()
    elseif self.petData:IsWorking() then
        self.targetPos, self.targetRotation = self.petData:GetWorkTargetPos()
    elseif self.petData:IsStrictMoving() then
        self.targetPos, self.targetRotation = self.petData:GetFixedServerPos()
    end

    self.subStateMachine:ChangeState("CityUnitPetSubStateMoving")
end

---@param stateName string
function CityUnitPet:PlayLoopState(stateName)
    if self.subStateMachine.currentName == "CityUnitPetSubStateActionLoop" and self._state == stateName then
        return
    end

    self._targetState = stateName
    self.subStateMachine:ChangeState("CityUnitPetSubStateActionLoop")
end

function CityUnitPet:PlayNormalAnimState(stateName)
    if self.subStateMachine.currentName == "CityUnitPetSubStateAction" and self._state == stateName then
        return
    end

    self._targetState = stateName
    self.subStateMachine:ChangeState("CityUnitPetSubStateAction")
end

function CityUnitPet:GetWorkAnimName()
    local stateName = self.petData:GetWorkAnimName()
    if string.IsNullOrEmpty(stateName) then
        stateName = CityPetAnimStateDefine.WorkDefault
    end
    return stateName
end

function CityUnitPet:GetManager()
    return self.petData.manager
end

function CityUnitPet:PushCurrentPositionToServer()
    if self.disposed then
        return
    end
    local x, y = self.petData.manager.city:GetCoordFromPosition(self._moveAgent._currentPosition, true)
    if x == self.pushedX and y == self.pushedY then
        return
    end
    -- self.petData.manager:PushCurrentPositionToServer(self.petData.id, x, y)
    self.pushedX, self.pushedY = x, y
end

function CityUnitPet:GetCarryingStartAnimLength()
    return 0.5
end

function CityUnitPet:GetCarryingEndAnimLength()
    return 0.5
end

function CityUnitPet:GetBelongsToBuildMasterInfo()
    return self.petData.manager:GetBuildMasterInfo(self.petData.furnitureId)
end

function CityUnitPet:GetSize()
    return self.petData.petCfg:BodySize()
end

---@param unitPet CityUnitPet
function CityUnitPet:AttachToPrevPetAnchor(unitPet)
    if not self:IsModelReady() then return end
    if not unitPet:IsModelReady() then return end

    if Utils.IsNull(self._attachPointHolder) or Utils.IsNull(unitPet._attachPointHolder) then
        g_Logger.ErrorChannel("CityUnitPet", "AttachPointHolder is null")
        return
    end

    local targetTrans = unitPet._attachPointHolder:GetAttachPoint("p_lift")
    if Utils.IsNull(targetTrans) then
        g_Logger.ErrorChannel("CityUnitPet", "Can't find p_lift attach point")
        return
    end
    local sourceTrans = self._attachPointHolder.transform
    if Utils.IsNull(sourceTrans) then
        return
    end
    self._syncPos:SetTransforms(targetTrans, sourceTrans)
    self._syncPos.SyncEveryTick = true
end

function CityUnitPet:DetachFromPrevPetAnchor()
    if not self:IsModelReady() then return end
    self._syncPos.SyncEveryTick = false
end

---@param targetPos CS.UnityEngine.Vector3
function CityUnitPet:IsCloseTo(targetPos)
    return CS.UnityEngine.Vector3.Distance(self._moveAgent._currentPosition, targetPos) < UnitMoveAgent.MoveEpsilon
end

---@param dramaHandle DramaHandleBase
function CityUnitPet:SetupCustomDrama(dramaHandle)
    self.dramaHandle = dramaHandle
    self.dramaHandle:Start()
end

function CityUnitPet:ReleaseCustomDrama()
    if self.dramaHandle then
        self.dramaHandle:End()
        self.dramaHandle = nil
    end
end

function CityUnitPet:AttachModelTo(modelName, scale, anchorIndex)
    if string.IsNullOrEmpty(modelName) then return end

    if self.attachGo[anchorIndex] then
        self.attachGo[anchorIndex]:Delete()
        self.attachGo[anchorIndex] = nil
    end

    if Utils.IsNull(self._attachPointHolder) then
        g_Logger.ErrorChannel("CityUnitPet", "AttachPointHolder is null")
        return
    end

    local parent = self._attachPointHolder:GetAttachPoint("res_prod_"..anchorIndex)
    if Utils.IsNull(parent) then return end

    self.attachGo[anchorIndex] = self:GetManager().city.createHelper:Create(modelName, parent, function(go, userdata, handle)
        local transform = go.transform
        transform.localPosition = CS.UnityEngine.Vector3.zero
        transform.localRotation = CS.UnityEngine.Quaternion.identity
        transform.localScale = CS.UnityEngine.Vector3.one * scale
        go:SetLayerRecursively("City")
    end)
end

function CityUnitPet:ReleaseAllAttachedModel()
    for _, v in pairs(self.attachGo) do
        v:Delete()
    end
    self.attachGo = {}
end

function CityUnitPet:EnterCarryingState()
    self.isCarring = true
end

function CityUnitPet:ExitCarryingState()
    self.isCarring = false
end

function CityUnitPet:SetupCarryItemGo()
    if not self.petData:IsCarrying() then return end

    if Utils.IsNull(self._attachPointHolder) then return end

    local transport = self._attachPointHolder:GetAttachPoint("p_transport")
    if Utils.IsNull(transport) then
        g_Logger.ErrorChannel("CityUnitPet", "Can't find p_transport attach point")
        return
    end

    local luaBehaviour = transport.gameObject:GetLuaBehaviour("CityCitizenPrefabLoader")
    if Utils.IsNull(luaBehaviour) then
        g_Logger.ErrorChannel("CityUnitPet", "Can't find CityCitizenPrefabLoader luabehaviour on p_transport")
        return
    end

    ---@type CityCitizenPrefabLoader
    local prefabLoader = luaBehaviour.Instance
    if not prefabLoader:IsLoaded() then
        prefabLoader:SetLoadedCallbackOnce(Delegate.GetOrCreate(self, self.SetupCarryItemGo))
    else
        local prefabNames = self.petData:GetCarryInfoPrefabNames()
        if prefabNames == nil or next(prefabNames) == nil then return end

        local attachHandle = prefabLoader._loadHandle.Asset:GetComponent(typeof(CS.FXAttachPointHolder))
        if Utils.IsNull(attachHandle) then return end

        self.carryAttachHandle = attachHandle
        self.carryAttachGo = {}
        for i, v in ipairs(prefabNames) do
            self:AppendSpawnOneAttachGo(v, attachHandle:GetAttachPoint("t_transport0"..i), (i - 1) * CarryingPrefabCreateDelay)
        end
    end    
end

---@param prefabName string
---@param parent CS.UnityEngine.Transform
---@param delay number
function CityUnitPet:AppendSpawnOneAttachGo(prefabName, parent, delay)
    if delay <= 0 then
        self:DoSpawnOneAttachGo(prefabName, parent)
    else
        table.insert(self.delayCarrySpawnQueue, {prefabName = prefabName, parent = parent, delay = delay})
        table.sort(self.delayCarrySpawnQueue, function(a, b) return a.delay < b.delay end)
    end
end

function CityUnitPet:DoSpawnOneAttachGo(prefabName, parent)
    if string.IsNullOrEmpty(prefabName) then return end
    if Utils.IsNull(parent) then return end

    local handle = self:GetManager().city.createHelper:Create(prefabName, parent, function(go, userdata, handle)
        local transform = go.transform
        transform.localPosition = CS.UnityEngine.Vector3.zero
        transform.localRotation = CS.UnityEngine.Quaternion.identity
        transform.localScale = CS.UnityEngine.Vector3.one
        go:SetLayerRecursively("City")
    end)
    table.insert(self.carryAttachGo, handle)

    local vxhandle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    vxhandle:Create(ManualResourceConst.vfx_w_banyun, "CityUnitPet", parent, function(isSuccess, userdata, vhandle)
        if isSuccess then
            vhandle.Effect.gameObject:SetLayerRecursively("City")
            g_Game.SoundManager:Play("sfx_world_pet_transport", vhandle.Effect.gameObject)
        end
    end)
    self.carryVfxHandles[vxhandle] = true
end

function CityUnitPet:TickForSpawnCarryItemGo(dt)
    if #self.delayCarrySpawnQueue == 0 then return end

    for i, v in ipairs(self.delayCarrySpawnQueue) do
        v.delay = v.delay - dt
    end

    local first = self.delayCarrySpawnQueue[1]
    while first ~= nil and first.delay <= 0 do
        self:DoSpawnOneAttachGo(first.prefabName, first.parent)
        table.remove(self.delayCarrySpawnQueue, 1)
        first = self.delayCarrySpawnQueue[1]
    end
end

function CityUnitPet:DestroyCarryItemGo()
    for _, v in pairs(self.carryAttachGo) do
        v:Delete()
    end
    for handle, _ in pairs(self.carryVfxHandles) do
        handle:Delete()
    end
    self.carryAttachGo = {}
    self.delayCarrySpawnQueue = {}
    self.carryVfxHandles = {}
    self.carryAttachHandle = nil
end

function CityUnitPet:OnMainStateChanged(oldState, newState)
    local newStateName = newState:GetName()
    if newStateName == "CityUnitPetStateWorking" or newStateName == "CityUnitPetStateBuildMaster" or newStateName == "CityUnitPetStateCarrying" then
        if self.statusHandle then
            self.statusHandle:ShowBingo(2)
        end
    end
end

function CityUnitPet:OnSubStateChanged(oldState, newState)
    if not self:IsModelReady() then return end

    if Utils.IsNull(self._attachPointHolder) then return end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_PET_CLEAR_DISPATCH_VFX_SFX, self._attachPointHolder:GetInstanceID())
end

function CityUnitPet:GetStatusDesc()
    local currentState = self.stateMachine.currentName
    if currentState == "CityUnitPetStateBuildMaster" then
        return true, I18N.Get("pet_tip_status07")
    elseif currentState == "CityUnitPetStateCarrying" then
        return true, I18N.Get("pet_tip_status01")
    elseif currentState == "CityUnitPetStateEating" then
        return true, I18N.Get("pet_tip_status08")
    elseif currentState == "CityUnitPetStateWorking" then
        return true, I18N.Get("pet_tip_status07")
    else
        return false
    end
end

function CityUnitPet:OnClickPet()
    if not self.petData:CanBeClicked() then
        return false
    end

    local pet = ModuleRefer.PetModule:GetPetByID(self.petData.id)
    ---@type CityPetDetailsTipUIParameter
    local param = {
        id = self.petData.id,
        cfgId = self.petData.petCfg:Id(),
        Level = pet.Level,
        removeFunc = nil,
        workTimeFunc = nil,
        benefitFunc = nil,
        rectTransform = nil,
    }
    g_Game.UIManager:Open(UIMediatorNames.CityPetDetailsTipUIMediator, param)
    self:GetManager().city.petManager:BITraceTipsOpen(0)
    return true
end

function CityUnitPet:LoadZZZEffect()
    self:UnloadZZZEffect()
    if not self:IsModelReady() then return end

    self.zzzHandle = self:GetManager().city.createHelper:Create("fx_city_zzz", self:GetManager().city.CityRoot.transform, function(go, userdata, handle)
        local transform = go.transform
        transform.localScale = CS.UnityEngine.Vector3.one
        transform:SetParent(self.model._go.transform)
        transform.localPosition = CS.UnityEngine.Vector3.up * 3
        transform.localRotation = CS.UnityEngine.Quaternion.identity
        go:SetLayerRecursively("City")
    end)
end

function CityUnitPet:UnloadZZZEffect()
    if self.zzzHandle then
        self.zzzHandle:Delete()
    end
    self.zzzHandle = nil
end

function CityUnitPet:UnloadAllPrefabLoader()
    if not self.model:IsReady() then return end
    if Utils.IsNull(self.model._go) then return end
    local allScripts = {}
    self.model._go:GetLuaBehavioursInChildren("CityCitizenPrefabLoader", allScripts, false)
    for _, luaScript in ipairs(allScripts) do
        if Utils.IsNotNull(luaScript) then
            luaScript.gameObject:SetActive(false)
        end
    end
end

function CityUnitPet:ReleaseFromBuildMaster()
    self:DetachFromPrevPetAnchor()
    local buildMasterInfo = self:GetBelongsToBuildMasterInfo()
    if buildMasterInfo then
        buildMasterInfo:UnregisterBuildMaster(self)
    end
end

---@param workPosWS CS.UnityEngine.Vector3
---@param workPosDir CS.UnityEngine.Quaternion
---@return CS.UnityEngine.Vector3
function CityUnitPet:GetWorkPosWithCenterOffsetFix(workPosWS, workPosDir)
    if not workPosDir then return nil end
    local cityScale = self:GetManager().city.scale
    local petConfig = self.petData.petCfg
    local offsetX = petConfig:BodyCenterOffsetX()
    local offsetY = petConfig:BodyCenterOffsetY()
    local worldPosOffset = CS.UnityEngine.Vector3(offsetX * cityScale, 0, offsetY * cityScale) 
    local offsetWithRotation = workPosDir * worldPosOffset
    return workPosWS + offsetWithRotation
end

return CityUnitPet