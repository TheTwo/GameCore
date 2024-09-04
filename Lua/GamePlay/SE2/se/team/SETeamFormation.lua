---@class SETeamFormation
---@field new fun():SETeamFormation
local SETeamFormation = class("SETeamFormation")
local SEFormationHelper = require("SEFormationHelper")
local MoveStickParameter = require("MoveStickParameter")
local SESceneRoot = require("SESceneRoot")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")
local Utils = require("Utils")
local SETeamUnitSEController = require("SETeamUnitSEController")
local SETeamUnitCustomController = require("SETeamUnitCustomController")
local SETeamUnitCircleController = require("SETeamUnitCircleController")
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local CityPathFinding = require("CityPathFinding")
local LayerMask = require("LayerMask")
local DebugDrawGizmos = false

local SYNC_PER_FRAME = 2
local MOVE_PER_FRAME = 8

local SETeamControlMode = {
    SELocomotion = 1,
    Custom = 2,
    Circle = 3,
}

---@param team SETeam
function SETeamFormation:ctor(team)
    self._team = team

    ---@type table<number, {x:number, y:number, petOffsetX:number|nil, petOffsetY:number|nil}> @value是服务器坐标系统，使用时需转为客户端坐标;pet字段只有英雄上有
    self._unitServerOffsetMap = {}
    ---@type table<number, CS.UnityEngine.Vector3>
    self._unitClientOffsetMap = {}
    ---@type table<number, CS.UnityEngine.Vector3>
    self._unitClientTargetPosMap = {}
    ---@type SEHero[]
    self._orderedHeroes = {}

    self._lastSendMoveTime = nil
    self._lastMoveTime = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._circleHandle = nil
    ---@type CS.UnityEngine.GameObject
    self._goCircle = nil
    self._controlMode = SETeamControlMode.Circle
    if self._controlMode == SETeamControlMode.SELocomotion then
        self._moveController = SETeamUnitSEController.new(self)
    elseif self._controlMode == SETeamControlMode.Custom then
        self._moveController = SETeamUnitCustomController.new(self)
    elseif self._controlMode == SETeamControlMode.Circle then
        self._moveController = SETeamUnitCircleController.new(self)
    end
    ---@type CS.UnityEngine.Vector3
    self._clientPos = CS.UnityEngine.Vector3.zero
    ---@type CS.UnityEngine.Vector3
    self._dir = CS.UnityEngine.Vector3.forward
    self._serverPosX, self._serverPosY = 0, 0
    if self._team._manager._env:GetEnvMode() == SEEnvironmentModeType.CityScene then
        self._rayCastAreaMask = CityPathFinding.AreaMask.CityAllWalkable
    else
        self._rayCastAreaMask = LayerMask.SEFloor
    end
    self.lastCaptainEntityId = nil
    self.newFormation = true
    self.forceCaptainId = nil
end

function SETeamFormation:Initialize()
    self:UpdateCenterPosAndDir()
    self:LoadTeamCenterVX()

    if DebugDrawGizmos and UNITY_EDITOR then
        g_Game:AddOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDrawGizmos))
    end
end

function SETeamFormation:UpdateCenterPosAndDir()
    local centerInfo = self._team:GetScenePlayerCenter()
    if centerInfo == nil then
        centerInfo = self._team:GetRandomUnitLocoAsCenter()
    end

    local position = centerInfo.Position
    self._serverPosX, self._serverPosY = position.X, position.Y
    self._clientPos = self._team._env:ServerPos2Client(CS.UnityEngine.Vector3(position.X, position.Y, position.Z))

    local direction = centerInfo.Direction
    local dirVec = CS.UnityEngine.Vector3(direction.X, 0, direction.Y)
    self._dir = dirVec.normalized
end

function SETeamFormation:LoadTeamCenterVX()
    if not self._team:IsOperatingTeam() then return end

    local createHelper = self._team:GetCreateHelper()
    self._circleHandle = createHelper:Create(ManualResourceConst.vfx_w_team_range, self._team._env:GetMapRoot(), Delegate.GetOrCreate(self, self.OnTeamCenterVXLoaded))
end

function SETeamFormation:Dispose()
    if DebugDrawGizmos and UNITY_EDITOR then
        g_Game:RemoveOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDrawGizmos))
    end
    if self._circleHandle then
        self._circleHandle:Delete()
        self._circleHandle = nil
    end
    self._goCircle = nil
    table.clear(self._orderedHeroes)
    table.clear(self._unitServerOffsetMap)
    table.clear(self._unitClientOffsetMap)
    table.clear(self._unitClientTargetPosMap)
end

---任何成员的变化都会导致阵型被调整
function SETeamFormation:OnFormationChanged()
    self._unitServerOffsetMap = {}
    self._unitClientOffsetMap = {}
    
    local preset = self._team:GetTroopPreset()
    local heroCfg2Idxs = {}
    if preset then
        for i, v in ipairs(preset.Heroes) do
            heroCfg2Idxs[v.HeroCfgID] = i
        end
    end

    local heroMembers = self._team:GetHeroMembers()
    local heroCount, meleeHeroCount = 0, 0
    local orderHeroes = {}
    for entityId, seHero in pairs(heroMembers) do
        if not seHero:IsDead() then
            if seHero:IsMeleeHero() then
                meleeHeroCount = meleeHeroCount + 1
            end
            heroCount = heroCount + 1
            table.insert(orderHeroes, seHero)
        end
    end

    local heroBase = self._team:GetScenePlayerHeroBase()
    if self.newFormation and heroBase then
        self.lastCaptainEntityId = heroBase.CaptainHeroEntityId
        local targetCaptain = self:GetCaptainId()
        ---@param a SEHero
        ---@param b SEHero
        table.sort(orderHeroes, function(a, b)
            if a:GetEntity().ID == targetCaptain then
                return true
            end
            if b:GetEntity().ID == targetCaptain then
                return false
            end
            return (heroCfg2Idxs[a:GetHeroConfigId()] or 0) < (heroCfg2Idxs[b:GetHeroConfigId()] or 0)
        end)
    else
        ---@param a SEHero
        ---@param b SEHero
        table.sort(orderHeroes, function(a, b)
            if a:IsMeleeHero() ~= b:IsMeleeHero() then
                return a:IsMeleeHero()
            end
            return (heroCfg2Idxs[a:GetHeroConfigId()] or 0) < (heroCfg2Idxs[b:GetHeroConfigId()] or 0)
        end)
    end
    self._orderedHeroes = orderHeroes
    self:HideCircle()
    self:UpdateCircleRadius()

    local offsetMap = SEFormationHelper.GetMatchFormationData(heroCount, meleeHeroCount, orderHeroes, self.newFormation)
    if offsetMap == nil then return end

    for entityId, offset in pairs(offsetMap) do
        self._unitServerOffsetMap[entityId] = offset
    end

    local petMembers = self._team:GetPetMembers()
    local nonMasterOrderPets = {}
    for entityId, sePet in pairs(petMembers) do
        if not sePet:IsDead() then
            ---@type wds.SePet
            local petwds = sePet:GetEntity()
            local heroId = petwds.Owner.MasterID
            local seHero = heroMembers[heroId]
            if seHero and not seHero:IsDead() and self._unitServerOffsetMap[seHero._id] then
                local heroOffset = self._unitServerOffsetMap[seHero._id]
                self._unitServerOffsetMap[entityId] = {x = heroOffset.x + heroOffset.petOffsetX, y = heroOffset.y + heroOffset.petOffsetY}
            else
                table.insert(nonMasterOrderPets, sePet)
            end
        end
    end

    ---@param a SEPet
    ---@param b SEPet
    table.sort(nonMasterOrderPets, function(a, b)
        return a:GetEntity().BasicInfo.Index < b:GetEntity().BasicInfo.Index
    end)

    local nonPetOffsetMap = SEFormationHelper.GetNonMasterPetOffsets(nonMasterOrderPets)
    if nonPetOffsetMap then
        for entityId, offset in pairs(nonPetOffsetMap) do
            self._unitServerOffsetMap[entityId] = offset
        end
    end

    local scale = SESceneRoot.GetClientScale()
    for entityId, serverOffset in pairs(self._unitServerOffsetMap) do
        self._unitClientOffsetMap[entityId] = CS.UnityEngine.Vector3(serverOffset.x * scale, 0, serverOffset.y * scale)
    end
end

---@param dir CS.UnityEngine.Vector3
function SETeamFormation:StartMove(dir, intencity, dt)
    self:HideCircle()
    self:MoveTo(dir, intencity, wrpc.MoveStickOpType.MoveStickOpType_StartMove, dt)
end

---@param dir CS.UnityEngine.Vector3
function SETeamFormation:Move(dir, intencity, dt)
    local moveDirNormalized = dir.normalized
    local dot = CS.UnityEngine.Vector3.Dot(self._dir, moveDirNormalized)
    if dot < 1 then
        self:MoveTo(dir, intencity, wrpc.MoveStickOpType.MoveStickOpType_Move, dt)
    else
        if not self._lastMoveTime or (g_Game.RealTime.realtimeSinceStartup - self._lastMoveTime > (1 / MOVE_PER_FRAME)) then
            self:MoveTo(dir, intencity, wrpc.MoveStickOpType.MoveStickOpType_Move, dt)
        end
    end
end

---@protected
---@param dir CS.UnityEngine.Vector3
function SETeamFormation:MoveTo(dir, intencity, opCode, dt)
    self._lastMoveTime = g_Game.RealTime.realtimeSinceStartup
    local moveDirNormalized = dir.normalized
    self._dir = moveDirNormalized
    local moveDirLength = intencity * self._team:GetCenterMoveSpeed() * SESceneRoot.GetClientScale()
    
    local isHit, navmeshHit = CS.UnityEngine.AI.NavMesh.Raycast(self._clientPos, self._clientPos + (moveDirNormalized * moveDirLength), self._rayCastAreaMask)
    if isHit then
        local hitPos = navmeshHit.position
        local hitDistance = navmeshHit.distance
        local hitDir = hitPos - self._clientPos
        local hitDirNormalized = hitDir.normalized
        local targetPos = hitPos - hitDirNormalized * math.min(0.1, hitDistance)
        if hitDistance > SESceneRoot.GetClientScale() then
            self:MoveFormation(targetPos, moveDirNormalized, opCode, dt)
        else
            local normal = navmeshHit.normal
            local x1, y1 = normal.x, normal.z
            local x2, y2 = moveDirNormalized.x, moveDirNormalized.z
            local det = x1 * y2 - x2 * y1
            if det > 0 then
                local newDir = CS.UnityEngine.Vector3(-normal.z, 0, normal.x)
                local newTargetPos = targetPos + newDir * moveDirLength
                local isHit, navmeshHit = CS.UnityEngine.AI.NavMesh.Raycast(targetPos, newTargetPos, self._rayCastAreaMask)
                if isHit then
                    newTargetPos = navmeshHit.position
                end
                targetPos = newTargetPos
                self:MoveFormation(targetPos, moveDirNormalized, opCode, dt)
            elseif det < 0 then
                local newDir = CS.UnityEngine.Vector3(normal.z, 0, -normal.x)
                local newTargetPos = targetPos + newDir * moveDirLength
                local isHit, navmeshHit = CS.UnityEngine.AI.NavMesh.Raycast(targetPos, newTargetPos, self._rayCastAreaMask)
                if isHit then
                    newTargetPos = navmeshHit.position
                end
                targetPos = newTargetPos
                self:MoveFormation(targetPos, moveDirNormalized, opCode, dt)
            else
                self:MoveFormation(targetPos, moveDirNormalized, opCode, dt)
            end
        end
    else
        self:MoveFormation(self._clientPos + moveDirNormalized * moveDirLength, moveDirNormalized, opCode, dt)
    end
end

---@param centerTargetPos CS.UnityEngine.Vector3
---@param moveDir CS.UnityEngine.Vector3
---@param opCode wrpc.MoveStickOpType
function SETeamFormation:MoveFormation(centerTargetPos, moveDir, opCode, dt)
    self._centerTargetPos = centerTargetPos
    self._moveController:Move(centerTargetPos, moveDir, opCode, dt)
    self:SyncToServer(opCode)
end

function SETeamFormation:StopMove(dt)
    self._moveController:StopMove()
    self:SyncToServer(wrpc.MoveStickOpType.MoveStickOpType_StopMove)
    self._lastMoveTime = nil
    self:TryShowCircle()
end

function SETeamFormation:MoveCenter(targetPos, dt)
    local step = self._team:GetCenterMoveSpeed() * SESceneRoot.GetClientScale() * dt
    local newPos = CS.UnityEngine.Vector3.MoveTowards(self._clientPos, targetPos, step)
    self._clientPos = newPos
end

function SETeamFormation:SyncToServer(opCode)
    if opCode == wrpc.MoveStickOpType.MoveStickOpType_StopMove or opCode == wrpc.MoveStickOpType.MoveStickOpType_StartMove then
        self:DoSendMoveStick(opCode)
    else
        self:TrySendMoveStick(opCode)
    end
end

---@param param MoveStickParameter
function SETeamFormation:TrySendMoveStick(opCode)
    if not self._lastSendMoveTime then
        self:DoSendMoveStick(opCode)
        self._lastSendMoveTime = g_Game.RealTime.realtimeSinceStartup
    else
        if g_Game.RealTime.realtimeSinceStartup - self._lastSendMoveTime > (1 / SYNC_PER_FRAME) then
            self:DoSendMoveStick(opCode)
            self._lastSendMoveTime = g_Game.RealTime.realtimeSinceStartup
        end
    end
end

function SETeamFormation:DoSendMoveStick(opCode)
    local param = MoveStickParameter.new()
    param.args.PresetIndex = self._team._presetIdx
    param.args.OpType = opCode

    local centerPos = self._team._env:ClientPos2Server(self._clientPos)
    param.args.Info.CenterPos.X = centerPos.x
    param.args.Info.CenterPos.Y = centerPos.y
    param.args.Info.CenterPos.Z = centerPos.z
    
    local centerDir = self._dir
    param.args.Info.CenterDir.X = centerDir.x
    param.args.Info.CenterDir.Y = centerDir.z
    
    param.args.Info.CenterDest.X = centerPos.x
    param.args.Info.CenterDest.Y = centerPos.y
    param.args.Info.CenterDest.Z = centerPos.z

    for entityId, targetPos in pairs(self._unitClientTargetPosMap) do
        local stickUnitInfo = wrpc.MoveStickUnitInfo.New(entityId)
        local unit = self._team:GetUnitMember(entityId)

        if unit and not unit:IsDead() then
            local unitClientPos = unit:GetActor():GetPosition()
            local unitServerPos = self._team._env:ClientPos2Server(unitClientPos)
            stickUnitInfo.Pos.X = unitServerPos.x
            stickUnitInfo.Pos.Y = unitServerPos.y
            stickUnitInfo.Pos.Z = unitServerPos.z
            
            local unitDir = unit:GetActor():GetForward()
            stickUnitInfo.Dir.X = unitDir.x
            stickUnitInfo.Dir.Y = unitDir.z

            local stopPos = targetPos
            if opCode == wrpc.MoveStickOpType.MoveStickOpType_StopMove then
                stopPos = unit:GetActor():GetPosition()
            end
            local unitClientTargetPos = self._team._env:ClientPos2Server(stopPos)
            stickUnitInfo.Dest.X = unitClientTargetPos.x
            stickUnitInfo.Dest.Y = unitClientTargetPos.y
            stickUnitInfo.Dest.Z = unitClientTargetPos.z

            param.args.Info.UnitInfos:Add(stickUnitInfo)
        end
    end

    param:Send()
end

function SETeamFormation:Tick(dt)
    if not self:IsCaptainCanMove() then return end
    
    if not self._lastMoveTime then return end
    self:MoveCenter(self._centerTargetPos, dt)
    self._moveController:DoTick(dt)
end

function SETeamFormation:OnDrawGizmos()
    CS.UnityEngine.Gizmos.color = CS.UnityEngine.Color.yellow
    if self._clientPos then
        CS.UnityEngine.Gizmos.DrawSphere(self._clientPos, 0.08)
    end

    CS.UnityEngine.Gizmos.color = CS.UnityEngine.Color.red
    local lookRotation = CS.UnityEngine.Quaternion.LookRotation(self._dir, CS.UnityEngine.Vector3.up)
    for entityId, localOffset in pairs(self._unitClientOffsetMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            local worldOffset = lookRotation * localOffset
            local targetPos = self._clientPos + worldOffset
            CS.UnityEngine.Gizmos.DrawSphere(targetPos, 0.05)
        end
    end

    if not self._lastMoveTime then return end

    local clientPos = self._clientPos
    local centerTargetPos = self._centerTargetPos
    CS.UnityEngine.Gizmos.DrawLine(clientPos, centerTargetPos)
    CS.UnityEngine.Gizmos.DrawSphere(centerTargetPos, 0.08)

    CS.UnityEngine.Gizmos.color = CS.UnityEngine.Color.green
    for entityId, targetPos in pairs(self._unitClientTargetPosMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            local unitCurWorldPos = unit:GetActor():GetPosition()
            CS.UnityEngine.Gizmos.DrawLine(unitCurWorldPos, targetPos)
            CS.UnityEngine.Gizmos.DrawSphere(targetPos, 0.05)
        end
    end
end

---@param go CS.UnityEngine.GameObject
function SETeamFormation:OnTeamCenterVXLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    go.transform.position = self._clientPos
    go.transform.localScale = self:GetVXCircleScale() * CS.UnityEngine.Vector3.one
    go:SetActive(false)
    self._goCircle = go
end

function SETeamFormation:GetVXCircleScale()
    return self._team:GetTeamVXRadius() * 2
end

function SETeamFormation:TryShowCircle()
    if Utils.IsNull(self._goCircle) then return end

    self._goCircle.transform.position = self._clientPos
    self._goCircle:SetActive(true)
end

function SETeamFormation:HideCircle()
    if Utils.IsNull(self._goCircle) then return end
    self._goCircle:SetActive(false)
end

function SETeamFormation:UpdateCircleRadius()
    if Utils.IsNull(self._goCircle) then return end
    self._goCircle.transform.localScale = self:GetVXCircleScale() * CS.UnityEngine.Vector3.one
end

---@return SEHero
function SETeamFormation:GetOrderedLastHero()
    if self._orderedHeroes and #self._orderedHeroes > 0 then
        return self._orderedHeroes[#self._orderedHeroes]
    end
    return nil
end

function SETeamFormation:GetOrderedLastNotDeadHero()
    if self._orderedHeroes and #self._orderedHeroes > 0 then
        for i = #self._orderedHeroes, 1, -1 do
            local hero = self._orderedHeroes[i]
            if not hero:IsDead() then
                return hero
            end
        end
    end
    return nil
end

---@return CS.UnityEngine.Vector3
function SETeamFormation:GetCenterClientPos()
    return self._clientPos
end

function SETeamFormation:GetUnitRadius()
    return 1.5 * SESceneRoot.GetClientScale()
end

---@param unit SEUnit
function SETeamFormation:IsUnitCanMove(unit)
    return not unit:IsDominated() and not unit:IsControl()
end

function SETeamFormation:IsAnyUnitCanMove()
    for entityId, _ in pairs(self._unitClientOffsetMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            if self:IsUnitCanMove(unit) then
                return true
            end
        end
    end
    return false
end

function SETeamFormation:IsCaptainCanMove()
    local heroBase = self._team:GetScenePlayerHeroBase()
    if heroBase then
        local hero = self._team:GetUnitMember(heroBase.CaptainHeroEntityId)
        if hero and not hero:IsDead() then
            return self:IsUnitCanMove(hero)
        end
    end
    return false
end

---@param newCaptainId number
function SETeamFormation:UpdateCaptain(newCaptainId)
    if self.newFormation and self.lastCaptainEntityId ~= newCaptainId then
        self:OnFormationChanged()
    end
end

function SETeamFormation:DebugForceSetCaptain(entityId)
    self.forceCaptainId = entityId
    if self.newFormation then
        local unit = self._team:GetUnitMember(self.forceCaptainId)
        if unit and not unit:IsDead() then
            self:OnFormationChanged()
            self._clientPos = unit:GetActor():GetPosition()
        end
    end
end

function SETeamFormation:GetCaptainId()
    if self.forceCaptainId then
        local unit = self._team:GetUnitMember(self.forceCaptainId)
        if unit and not unit:IsDead() then
            return self.forceCaptainId
        end
    end
    return self.lastCaptainEntityId
end

return SETeamFormation