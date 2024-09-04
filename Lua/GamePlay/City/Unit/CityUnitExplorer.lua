local Utils = require("Utils")
local CityUnitActor = require("CityUnitActor")
local StateMachine = require("StateMachine")
local CityExplorerStateSet = require("CityExplorerStateSet")
local CityUnitPathLine = require("CityUnitPathLine")
local Delegate = require("Delegate")
local CityExplorerStateDefine = require("CityExplorerStateDefine")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ManualResourceConst = require("ManualResourceConst")
---@type CS.UnityEngine.Quaternion
local Quaternion = CS.UnityEngine.Quaternion
---@type CS.UnityEngine.Color
local UnityColor = CS.UnityEngine.Color
local ColorUtility = CS.UnityEngine.ColorUtility

---@class CityUnitExplorer:CityUnitActor
---@field new fun(id:number, type:UnitActorType):CityUnitExplorer
---@field super CityUnitActor
---@field _config UnitCitizenConfigWrapper
local CityUnitExplorer = class('CityUnitExplorer', CityUnitActor)
CityUnitExplorer.DefaultInitDir = Quaternion.identity
local success, color = ColorUtility.TryParseHtmlString("#5ffb58")
CityUnitExplorer.MarchLineColor = success and color or UnityColor.green

function CityUnitExplorer:ctor(id, type)
    CityUnitActor.ctor(self, id, type)
    self._isRunning = false
    self._stateMachine = StateMachine.new()
    ---@type CS.DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle
    self._pathFindingHandle = nil
    self._hasTargetPos = false
    self._selectedShow = false
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self._goCreator = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._selectedEffectHandle = nil
    ---@type CityUnitPathLine
    self._wayPointsLine = nil
    self._isLeader = false
    ---@type CityUnitExplorer
    self._leaderUnit = nil
    self._teamIndex = nil
    self._showBornVfxTime = nil
    self._waitModelReady = false
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._bornVfxHandle = nil
end

---@param explorerId number
---@param asset string
---@param creator CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@param moveAgent UnitMoveAgent
---@param config UnitCitizenConfigWrapper
---@param pathFinder CityPathFinding
---@param pathHeightFixer fun(pos:CS.UnityEngine.Vector3):CS.UnityEngine.Vector3|nil
---@param seMgr CitySeManager
function CityUnitExplorer:Init(explorerId, asset, creator, moveAgent, config, pathFinder, pathHeightFixer, seMgr)
    self.explorerId = explorerId
    self._goCreator = creator
    self._seMgr = seMgr
    CityUnitActor.Init(self, asset, creator, moveAgent, config, pathFinder, pathHeightFixer)

    self._stateMachine.allowReEnter = true
    for k, v in pairs(CityExplorerStateSet) do
        self._stateMachine:AddState(k, v.new(self))
    end
    self._stateMachine:ChangeState("CityExplorerStateRandomWalkInRange")
end

---@param provider CityUnitMoveGridEventProvider
function CityUnitExplorer:AttachMoveGridListener(provider)
    if self._moveGridHandle then
        self._moveGridHandle:dispose()
    end
    local x,y = self._seMgr.city:GetCoordFromPosition(self._moveAgent._currentPosition)
    self._moveGridHandle = provider:AddUnit(x,y, provider.UnitType.Explorer)
end

function CityUnitExplorer:Tick(delta)
    if self._wayPointsLine then
        self._wayPointsLine:UpdateByMoveAgent(self._moveAgent)
    end
    CityUnitActor.Tick(self, delta)
    self._stateMachine:Tick(delta)
    if self._hasTargetPos and (not self._pathFindingHandle) then
        if not self._moveAgent._isMoving then
            self._hasTargetPos = false
        end
    end
    if self._moveGridHandle then
        local x,y = self._seMgr.city:GetCoordFromPosition(self._moveAgent._currentPosition)
        self._moveGridHandle:refreshPos(x, y)
    end
    if not self._showBornVfxTime then return end
    if not self._bornVfxHandle then
        return
    end
    self._showBornVfxTime = self._showBornVfxTime - delta
    if self._showBornVfxTime <= 0 then
        self._showBornVfxTime = nil
        self._bornVfxHandle:Delete()
        self._bornVfxHandle = nil
    end
end

function CityUnitExplorer:SetIsRunning(isRunning)
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

function CityUnitExplorer:WhenModelReady(model)
    CityUnitActor.WhenModelReady(self, model)
    if Utils.IsNull(self.model) then
        return
    end
    local fbxTrans = self.model:Transform():GetChild(0)
    fbxTrans.localScale = CS.UnityEngine.Vector3.one
    self.model:SetScale(self._config:ModelScale())
    self.model:SetGoLayer("City")
    local agent = self._moveAgent
    local displayPos = self._pathHeightFixer and self._pathHeightFixer(agent._currentPosition) or agent._currentPosition
    self.model:SetWorldPositionAndDir(displayPos, agent._currentDirectionNoPitch)
    self:DoRefreshSelectedShow()
    if self._showBornVfxTime and self._showBornVfxTime > 0 and not self._bornVfxHandle then
        local parent = self.model:Transform()
        if Utils.IsNotNull(parent) then
            self._bornVfxHandle = self._goCreator:Create(ManualResourceConst.vfx_w_caiji_born, parent, Delegate.GetOrCreate(self, self.OnBornVfxCreated))
        end
    end
    if Utils.IsNull(self._animator) then
        return
    end
    self._animator:CrossFade(self._state, 0)
end

---@param targetPos CS.UnityEngine.Vector3
---@param targetDir CS.UnityEngine.Quaternion
function CityUnitExplorer:WarpPos(targetPos, targetDir)
    local agent = self._moveAgent
    agent._currentPosition = targetPos
    agent._currentDirection = targetDir
    agent._currentDirectionNoPitch = agent.NoPitchDir(targetDir)
    if self.model and self.model._ready then
        local displayPos = self._pathHeightFixer and self._pathHeightFixer(agent._currentPosition) or agent._currentPosition
        self.model:SetWorldPositionAndDir(displayPos, targetDir)
    end
end

---@param targetPos CS.UnityEngine.Vector3
---@param run boolean
---@param showLine boolean
---@param startCallBack fun(p:CS.UnityEngine.Vector3[], agent:UnitMoveAgent)
function CityUnitExplorer:MoveToTargetPos(targetPos, run, showLine, startCallBack)
    self._hasTargetPos = true
    if self._pathFindingHandle then
        self._pathFindingHandle:Release()
    end
    self._pathFindingHandle = self._pathFinder:FindPath(self._moveAgent._currentPosition, targetPos ,
            self._pathFinder.AreaMask.CityAllWalkable ,function(p) 
        if self._pathFindingHandle then
            self._pathFindingHandle:Release()
        end
        self._pathFindingHandle = nil
        if run then
            self:ChangeAnimatorState(CityExplorerStateDefine.AnimatorState.run)
        else
            self:ChangeAnimatorState(CityExplorerStateDefine.AnimatorState.walk)
        end
        self._moveAgent:StopMove(self._moveAgent._currentPosition)
        self._moveAgent:BeginMove(p)
        if startCallBack then
            startCallBack(p, self._moveAgent)
        end
        if showLine then
            self:ShowPathLine(p, self._moveAgent._currentPosition)
        end
    end)
end

---@param wayPoints CS.UnityEngine.Vector3[]
---@param run boolean
---@param showLine boolean
---@param startCallBack fun(p:CS.UnityEngine.Vector3[], agent:UnitMoveAgent)
function CityUnitExplorer:MoveUseWaypoints(wayPoints, run, showLine, startCallBack)
    self._hasTargetPos = true
    if run then
        self:ChangeAnimatorState(CityExplorerStateDefine.AnimatorState.run)
    else
        self:ChangeAnimatorState(CityExplorerStateDefine.AnimatorState.walk)
    end
    self._moveAgent:StopMove(self._moveAgent._currentPosition)
    self._moveAgent:BeginMove(wayPoints)
    if startCallBack then
        startCallBack(wayPoints, self._moveAgent)
    end
    if showLine then
        self:ShowPathLine(wayPoints, self._moveAgent._currentPosition)
    end
end

function CityUnitExplorer:Dispose()
    if self._moveGridHandle then
        self._moveGridHandle:dispose()
    end
    self._moveGridHandle = nil
    if self._pathFindingHandle then
        self._pathFindingHandle:Release()
    end
    self._pathFindingHandle = nil
    self._stateMachine:ClearAllStates()
    self._stateMachine = nil
    if self._bornVfxHandle then
        self._bornVfxHandle:Delete()
        self._bornVfxHandle = nil
    end
    self._showBornVfxTime = nil
    CityUnitActor.Dispose(self)
end

function CityUnitExplorer:SetSelectedShow(show)
    self._selectedShow = show
    if not self._assetReady then
        return
    end
    self:DoRefreshSelectedShow()
end

function CityUnitExplorer:DoRefreshSelectedShow()
    if not self._selectedShow then
        if Utils.IsNotNull(self._selectedEffectHandle) then
            self._selectedEffectHandle:Delete()
            self._selectedEffectHandle = nil
        end
    else
        if Utils.IsNull(self._selectedEffectHandle) then
            self._selectedEffectHandle = self._goCreator:Create(ArtResourceUtils.GetItem(ArtResourceConsts.effect_city_explorer_selected), self.model:Transform(), Delegate.GetOrCreate(self, self.OnSelectedAssetReady))
        end
    end
end

---@param go CS.UnityEngine.GameObject
function CityUnitExplorer:OnSelectedAssetReady(go, userData)
    if Utils.IsNotNull(go) then
        go.transform.localPosition = CS.UnityEngine.Vector3(0, 0.01, 0)
    end
end

function CityUnitExplorer:ShowPathLine(wayPoints, currentPoint)
    if not wayPoints then
        return
    end
    if not self._wayPointsLine then
        self._wayPointsLine = CityUnitPathLine.GetOrCreate(self._pathFinder.city.CityExploreRoot, ArtResourceUtils.GetItem(ArtResourceConsts.effect_city_explorer_pathline))
    end
    self._wayPointsLine:SetLineColor(CityUnitExplorer.MarchLineColor)
    self._wayPointsLine:InitWayPoints(wayPoints, currentPoint)
end

function CityUnitExplorer:RemovePathLine()
    if self._wayPointsLine then
        CityUnitPathLine.Delete(self._wayPointsLine)
    end
    self._wayPointsLine = nil
end

function CityUnitExplorer:PlayTeleportBornVfx()
    self._showBornVfxTime = 1
    if self._bornVfxHandle then
        self._bornVfxHandle:Delete()
    end
    self._bornVfxHandle = nil
    if not self.model then return end
    if not self.model:IsReady() then return end
    local parent = self.model:Transform()
    if Utils.IsNull(parent) then return end
    self._bornVfxHandle = self._goCreator:Create(ManualResourceConst.vfx_w_caiji_born, parent, Delegate.GetOrCreate(self, self.OnBornVfxCreated))
end

function CityUnitExplorer:OnBornVfxCreated(go, userData)
    if Utils.IsNull(go) then return end
    go:SetVisible(false)
    go:SetLayerRecursively("City")
    local bornVfx = go:GetComponent(typeof(CS.DragonReborn.VisualEffect.VisualEffectBase))
    if Utils.IsNull(bornVfx) then
        if self._showBornVfxTime and self._showBornVfxTime > 0 then
            go:SetVisible(true)
        end
        return
    end
    bornVfx.autoPlay = false
    bornVfx.autoDelete = false
    if self._showBornVfxTime and self._showBornVfxTime > 0 then
        bornVfx.gameObject:SetVisible(true)
        bornVfx:ResetEffect()
        bornVfx:Play()
    end
end

return CityUnitExplorer