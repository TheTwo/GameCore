local CityCitizenDefine = require("CityCitizenDefine")
local CityCitizenStateSet = require("CityCitizenStateSet")
local CityCitizenStateSubSet = require("CityCitizenStateSubSet")
local StateMachine = require("StateMachine")
local Utils = require("Utils")
local CityUnitPathLine = require("CityUnitPathLine")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local CityUnitInfectionVfx = require("CityUnitInfectionVfx")
local CitizenBTNodeFactory = require("CitizenBTNodeFactory")
local CitizenBTContext = require("CitizenBTContext")
local CitizenBehaviourTree = require("CitizenBehaviourTree")
local CitizenBubbleStateMachine = require("CitizenBubbleStateMachine")
local ManualResourceConst = require("ManualResourceConst")

---@type CS.UnityEngine.Color
local UnityColor = CS.UnityEngine.Color
local ColorUtility = CS.UnityEngine.ColorUtility

local CityUnitActor = require("CityUnitActor")

---@class CityUnitCitizen:CityUnitActor
---@field new fun(unitId:number,unitActorType:UnitActorType):CityUnitCitizen
---@field super CityUnitActor
---@field _config UnitCitizenConfigWrapper
local CityUnitCitizen = class('CityUnitCitizen', CityUnitActor)
local success, color = ColorUtility.TryParseHtmlString("#66d3ff")
CityUnitCitizen.MarchLineColor = success and color or UnityColor.cyan

function CityUnitCitizen:ctor(id, type)
    CityUnitActor.ctor(self, id, type)
    self._disposed = false
    self._isRunning = false
    ---@type CitizenBTNode
    self._btAiRootNode = nil
    ---@type CitizenBTContext
    self._btContext = nil
    ---@type CitizenBTContext
    self._btgContext = nil
    self._stateMachine = StateMachine.new()
    self._stateMachine.allowReEnter = true
    self._subStateMachine = StateMachine.new()
    self._subStateMachine.allowReEnter = true
    ---@type CS.DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle
    self._pathFindingHandle = nil
    self._hasTargetPos = false
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self._goCreator = nil
    self._pause = false
    ---@type CityUnitPathLine
    self._wayPointsLine = nil
    ---@type CityUnitInfectionVfx
    self._infectionVfx = nil
    self._useLegacyStateMachine = false
    ---@type CitizenBubbleStateMachine
    self._citizenBubble = nil
    self._pathFindingIndex = 0
end

---@param citizenData CityCitizenData
---@param creator CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@param moveAgent UnitMoveAgent
---@param config UnitCitizenConfigWrapper
---@param pathFinder CityPathFinding
---@param pathHeightFixer fun(pos:CS.UnityEngine.Vector3):CS.UnityEngine.Vector3
---@param gContext CitizenBTContext
function CityUnitCitizen:Init(citizenData, creator, moveAgent, config, pathFinder, pathHeightFixer, gContext)
    self._data = citizenData
    self._goCreator = creator
    local asset = citizenData:ModelAsset()
    CityUnitActor.Init(self, asset, creator, moveAgent, config, pathFinder, pathHeightFixer)

    self._btAiRootNode = CitizenBTNodeFactory.CreateForCitizen(self._data)
    self._btContext = CitizenBTContext.new()
    self._btContext:SetCitizen(self)
    self._btgContext = gContext

    if self._useLegacyStateMachine then
        for k, v in pairs(CityCitizenStateSubSet) do
            self._subStateMachine:AddState(k, v.new(self))
        end
        for k, v in pairs(CityCitizenStateSet) do
            local s = v.new(self)
            s:SetSubStateMachine(self._subStateMachine)
            self._stateMachine:AddState(k, s)
        end
    end
    self._citizenBubble = CitizenBubbleStateMachine.new(self)
    self._citizenBubble:Start()
    self._data._mgr.city.cityEnvironmentalIndicatorManager:RegisterCitizenIndicatorTriggerEmoji(self)
end

function CityUnitCitizen:WaitSync()
    self._stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.WaitSyncDelayTime)
    self._stateMachine:ChangeState("CityCitizenStateWaitSync")
end

function CityUnitCitizen:SyncFromData(updateFlag)
    if not self._useLegacyStateMachine then
        return
    end
    if updateFlag then
        if (updateFlag & 1) ~= 0 then
            self._stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork)
            self._stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork, true)
        end
        if (updateFlag & 2) ~= 0 then
            self._stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse)
            self._stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse, true)
        end
    end
    self._stateMachine:ChangeState("CityCitizenStateSyncFromServerData")
end

---@param provider CityUnitMoveGridEventProvider
function CityUnitCitizen:AttachMoveGridListener(provider)
    if self._moveGridHandle then
        self._moveGridHandle:dispose()
    end
    local x,y = self._data._mgr.city:GetCoordFromPosition(self._moveAgent._currentPosition)
    self._moveGridHandle = provider:AddUnit(x,y, provider.UnitType.Citizen)
end

function CityUnitCitizen:Tick(delta, nowTime)
    if self._wayPointsLine then
        self._wayPointsLine:UpdateByMoveAgent(self._moveAgent)
    end
    if self._pause then
        return
    end
    CityUnitActor.Tick(self, delta)
    if self._useLegacyStateMachine then
        self._stateMachine:Tick(delta)
    else
        CitizenBehaviourTree.Run(self._btAiRootNode, self._btContext, self._btgContext)
        CitizenBehaviourTree.Tick(self._btContext, self._btgContext, delta, nowTime)
    end
    if self._hasTargetPos and (not self._pathFindingHandle) then
        if not self._moveAgent._isMoving then
            self._hasTargetPos = false
        end
    end
    if self._moveGridHandle then
        local x,y = self._data._mgr.city:GetCoordFromPosition(self._moveAgent._currentPosition)
        self._moveGridHandle:refreshPos(x, y)
    end
    self._citizenBubble:Tick(delta)
end

function CityUnitCitizen:SetIsRunning(isRunning)
    if self._isRunning == isRunning then
        return
    end
    self._isRunning = isRunning
    if self._isRunning then
        self._moveAgent._speed = self._config:RunSpeed()
    else
        self._moveAgent._speed = self._config:WalkSpeed()
    end
end

function CityUnitCitizen:WhenModelReady(model)
    CityUnitActor.WhenModelReady(self, model)
    if Utils.IsNull(self.model) then
        return
    end
    self.model:SetScale(self._config:ModelScale())
    self.model:SetGoLayer("City")
    local agent = self._moveAgent
    local displayPos = self._pathHeightFixer and self._pathHeightFixer(agent._currentPosition) or agent._currentPosition
    self.model:SetWorldPositionAndDir(displayPos, agent._currentDirectionNoPitch)
    if Utils.IsNull(self._animator) then
        self:NotifyStateMachineModelReady()
        return
    end
    self._animator:CrossFade(self._state, 0)
    if self._needSyncInfectionVfx then
        self:SyncInfectionVfx()
    end
    self:NotifyStateMachineModelReady()
end

function CityUnitCitizen:NotifyStateMachineModelReady()
    if not self._stateMachine then return end
    local state = self._stateMachine:GetCurrentState()
    if not state or not state.OnUnitAssetLoaded then return end
    state:OnUnitAssetLoaded()
end

---@param speed number
---@param wayPoints CS.UnityEngine.Vector3[]
---@param leftTime number|nil
function CityUnitCitizen.IsMoveTimeEnough(speed, wayPoints, leftTime)
    if not leftTime then return true end
    if speed <= 0 then return false end
    ---@type CS.UnityEngine.Vector3
    local lastPoint = wayPoints[1]
    for i = 2, #wayPoints do
        local currentPoint = wayPoints[i]
        local distanceTime = (currentPoint - lastPoint).magnitude / speed
        leftTime = leftTime - distanceTime
        if leftTime <= 0 then
            return false
        end
        lastPoint = currentPoint
    end
    return true
end

---@param targetPos CS.UnityEngine.Vector3
---@param run boolean
---@param startCallBack fun(p:CS.UnityEngine.Vector3[], agent:UnitMoveAgent)
---@param limitMoveTime number|nil
function CityUnitCitizen:MoveToTargetPos(targetPos, run, startCallBack, limitMoveTime)
    self._hasTargetPos = true
    local oldHandle = self._pathFindingHandle
    local moveSpeed = self._moveAgent._speed
    self._pathFindingIndex = self._pathFindingIndex + 1
    local index = self._pathFindingIndex
    self._pathFindingHandle = self._pathFinder:FindPath(self._moveAgent._currentPosition, targetPos ,
            self._pathFinder.AreaMask.CityAllWalkable,function(p)
                if self._pathFindingIndex ~= index then
                    return
                end
                self:ReleasePathFindingHandle()
                if not p or #p <= 1 then
                    self:StopMove(targetPos)
                else
                    if not CityUnitCitizen.IsMoveTimeEnough(moveSpeed, p, limitMoveTime) then
                        self:WarpInPos(targetPos)
                    else
                        self:MoveUseWaypoints(p, run, startCallBack)
                    end
                end
            end)
    if oldHandle then
        oldHandle:Release()
    end
end

function CityUnitCitizen:ReleasePathFindingHandle()
    if not self._pathFindingHandle then return end
    self._pathFindingHandle:Release()
    self._pathFindingIndex = self._pathFindingIndex + 1
    self._pathFindingHandle = nil
end

function CityUnitCitizen:StopMove(pos)
    pos = pos or self._moveAgent._currentPosition
    if pos then
        self._moveAgent:StopMove(pos)
    end
end

function CityUnitCitizen:WarpInPos(pos)
    self._moveAgent:StopMove(pos)
    if self._moveGridHandle then
        local x,y = self._data._mgr.city:GetCoordFromPosition(self._moveAgent._currentPosition)
        self._moveGridHandle:refreshPos(x, y)
    end
    self:SyncMoveAgentPosToModel()
end

function CityUnitCitizen:ReadMoveAgentPos()
    return self._moveAgent and self._moveAgent._currentPosition
end

function CityUnitCitizen:MoveUseWaypoints(wayPoints, run, startCallBack)
    if run then
        self:ChangeAnimatorState(CityCitizenDefine.AniClip.Running)
    else
        self:ChangeAnimatorState(CityCitizenDefine.AniClip.Walking)
    end
    self._moveAgent:StopMove(self._moveAgent._currentPosition)
    self._moveAgent:BeginMove(wayPoints)
    if startCallBack then
        startCallBack(wayPoints, self._moveAgent)
    end
    if run then
        self:ShowPathLine(wayPoints, self._moveAgent._currentPosition)
    end
end

---@param gridRange CityPathFindingGridRange
---@return boolean
function CityUnitCitizen:CheckSelfPosition(gridRange)
    local pos = self._moveAgent._currentPosition
    local city = self._pathFinder.city
    local gridX, gridY = city:GetCoordFromPosition(pos)
    return gridX >= gridRange.x and gridY >= gridRange.y and gridX < gridRange.xMax and gridY < gridRange.yMax
end

---@param gridRange CityPathFindingGridRange
---@return boolean
function CityUnitCitizen:CheckSelfPathInRange(gridRange)
    return self._moveAgent:CheckSelfPathInRange(gridRange, self._pathFinder)
end

function CityUnitCitizen:Dispose()
    self._disposed = true
    if  self._moveGridHandle then
        self._moveGridHandle:dispose()
    end
    self._moveGridHandle = nil
    self:SyncInfectionVfx()
    self:ReleasePathFindingHandle()
    self._stateMachine:ClearAllStates()
    self._stateMachine = nil
    self._subStateMachine:ClearAllStates()
    self._subStateMachine = nil
    if not self._useLegacyStateMachine then
        local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        CitizenBehaviourTree.SetCurrentActionNode(self._btContext, self._btgContext, nil)
        CitizenBehaviourTree.Tick(self._btContext, self._btgContext, 0, nowTime)
    end
    self._btAiRootNode = nil
    self._btContext = nil

    self:ReleaseBubbleTip()
    self._citizenBubble:End()
    self._data._mgr.city.cityEnvironmentalIndicatorManager:UnRegisterCitizenIndicatorTriggerEmoji(self)
    self:RemovePathLine()
    CityUnitActor.Dispose(self)
end

---@param newPosition CS.UnityEngine.Vector3
function CityUnitCitizen:OffsetMoveAndWayPoints(newPosition)
    local agent = self._moveAgent
    agent:OffsetMoveAndWayPoints(newPosition)
    if self.model and self.model._ready then
        local displayPos = self._pathHeightFixer and self._pathHeightFixer(agent._currentPosition) or agent._currentPosition
        self.model:SetWorldPositionAndDir(displayPos, agent._currentDirectionNoPitch)
    end
end

function CityUnitCitizen:OnWorkTargetChanged(targetId, targetType)
    ---@type CityCitizenState
    local state = self._stateMachine:GetCurrentState()
    if state then
        state:OnWorkTargetChanged(targetId, targetType)
    end
end

---@param gridRange CityPathFindingGridRange
function CityUnitCitizen:OnWalkableChangedCheck(gridRange)
    ---@type CityCitizenState
    local state = self._stateMachine.currentState
    if state then
        state:OnWalkableChangedCheck(gridRange)
    end
end

---@param pause boolean
function CityUnitCitizen:SetPause(pause)
    self._pause = pause
    self._moveAgent._isPause = pause
end

function CityUnitCitizen:SetIsHide(isHide)
    CityUnitCitizen.super.SetIsHide(self, isHide)
    self._citizenBubble:SetIsHide(isHide)
end

---@param trans CS.UnityEngine.Transform
function CityUnitCitizen:SetParent(trans)
    self.model:SetParent(trans)
end

function CityUnitCitizen:SetSelectedShow(showSelected)
    if self.model then
        if showSelected then
            self.model:SetGoLayer("Selected")
        else
            self.model:SetGoLayer("City")
        end
    end
end

function CityUnitCitizen:ShowPathLine(wayPoints, currentPoint)
    if self._disposed then
        return
    end
    if not wayPoints then
        return
    end
    if not self._wayPointsLine then
        self._wayPointsLine = CityUnitPathLine.GetOrCreate(self._pathFinder.city.CityWorkerRoot, ArtResourceUtils.GetItem(ArtResourceConsts.effect_city_explorer_pathline))
    end
    self._wayPointsLine:SetLineColor(CityUnitCitizen.MarchLineColor)
    self._wayPointsLine:InitWayPoints(wayPoints, currentPoint)
end

function CityUnitCitizen:RemovePathLine()
    if self._wayPointsLine then
        CityUnitPathLine.Delete(self._wayPointsLine)
    end
    self._wayPointsLine = nil
end

function CityUnitCitizen:SyncInfectionVfx()
    if self._disposed then
        self:HideInfectionVfx()
        return
    end
    local status = self._data:GetHealthStatusLocal()
    if status == CityCitizenDefine.HealthStatus.Health then
        self:HideInfectionVfx()
        return
    end
    self:ShowInfectionVfx(status)
end

function CityUnitCitizen:ShowInfectionVfx(status)
    if not self.model or not self.model:Transform() then
        self._needSyncInfectionVfx = status
        return
    end
    self._needSyncInfectionVfx = nil
    if not self._infectionVfx then
        self._infectionVfx = CityUnitInfectionVfx.GetOrCreate(self.model:Transform(), ManualResourceConst.fx_zhongdu)
    end
    self._infectionVfx:SetStatus(status)
end

function CityUnitCitizen:HideInfectionVfx()
    if self._infectionVfx then
        CityUnitInfectionVfx.Delete(self._infectionVfx)
    end
    self._infectionVfx = nil
end

function CityUnitCitizen:RequestBubbleTip()

end

function CityUnitCitizen:RequestGoToBubbleTip()

end

function CityUnitCitizen:ReleaseBubbleTip()

end

function CityUnitCitizen:RequestEscapeBubble()
    self._citizenBubble._inEscape = true
end

function CityUnitCitizen:ReleaseEscapeBubble()
    self._citizenBubble._inEscape = false
end

function CityUnitCitizen:HasChapterTaskBubble()
    return self._citizenBubble._hasTask
end

function CityUnitCitizen:RequestChapterTaskBubble()
    self._citizenBubble._hasTask = true
end

function CityUnitCitizen:ReleaseChapterTaskBubble()
    self._citizenBubble._hasTask = false
end

function CityUnitCitizen:OnDrawGizmos()
    if not self._stateMachine then
        return
    end
    local state = self._stateMachine.currentState
    if state then
        state:OnDrawGizmos()
    end
end

return CityUnitCitizen

